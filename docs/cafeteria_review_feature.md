# Cafeteria Review Feature Implementation Guide

This document describes every requirement needed to recreate the cafeteria review feature in the `cit_app` Flutter project. Follow it step by step to reproduce the behaviour exactly, including Firestore schema, security rules, data layer, Riverpod providers, and UI flow.

## 1. Firestore Schema

### 1.1 Collections and Documents

- `cafeteria_reviews`
  - Stores individual reviews for cafeteria menus.
  - Required fields:
    - `cafeteriaId` (`string`): must be one of `tsudanuma`, `narashino_1f`, `narashino_2f`.
    - `taste` (`int` 1..5)
    - `volume` (`int` 1..5)
    - `recommend` (`int` 1..5)
    - `userId` (`string`): Firebase UID of reviewer.
    - `userName` (`string`): display name stored with review even if user later renames profile.
    - `createdAt` (`timestamp`)
  - Optional fields:
    - `menuName` (`string|null`): free text, used to group by menu.
    - `comment` (`string|null`)
    - `volumeGender` (`string|null`): `'male'`, `'female'`, or `null`.

- `cafeteria_menu_items`
  - Stores canonical menu definitions per cafeteria; used to show menus even without reviews and to surface price/photo.
  - Fields:
    - `cafeteriaId` (`string`): same allowed values as above.
    - `menuName` (`string`)
    - `price` (`int|null`): price in yen.
    - `photoUrl` (`string|null`)
    - `createdAt` (`timestamp`)

### 1.2 Security Rules Requirements

In `firestore.rules` ensure:

```text
match /cafeteria_reviews/{reviewId} {
  allow read: if isCITUser();
  allow create: if isCITUser()
    && request.auth != null
    && request.resource.data.userId == request.auth.uid
    && hasRequiredCafeteriaReviewFields();
  allow update: if false;
  allow delete: if isCITUser()
    && request.auth != null
    && (resource.data.userId == request.auth.uid || isAdmin());
}

match /cafeteria_menu_items/{itemId} {
  allow read: if isCITUser();
  allow create: if false; // menu addition is disabled for end users
  allow update, delete: if isAdmin();
}
```

Ensure helper `hasRequiredCafeteriaReviewFields()` validates every required field and range check (1..5) exactly as above.

## 2. Data Models (`lib/models/cafeteria`)

### 2.1 `cafeteria_review_model.dart`

Create `CafeteriaReview` class with:

- Fields from schema plus
  - `id` (`String`)
- Factory `fromJson(Map<String,dynamic>)` and `toJson()` using `Timestamp` for `createdAt`.
- Helper `Cafeterias` class exposing constants, `all`, and `displayName(String id)` returning the Japanese labels:
  - `tsudanuma` -> `"津田沼"`
  - `narashino_1f` -> `"新習志野 1F"`
  - `narashino_2f` -> `"新習志野 2F"`

### 2.2 `cafeteria_menu_item_model.dart`

`CafeteriaMenuItem` class with fields listed above, `fromJson`, `toJson`, and `_parseDateTime` helper that accepts `Timestamp`, `DateTime`, or ISO string.

## 3. Services (`lib/services/cafeteria`)

### 3.1 `cafeteria_review_service.dart`

- Static collection reference `FirebaseFirestore.instance.collection('cafeteria_reviews')`.
- `streamReviews(String cafeteriaId)` -> stream filtered by `cafeteriaId`, ordered by `createdAt` descending, mapping each doc to `CafeteriaReview`.
- `addReview(CafeteriaReview review)` -> `await _col.add(review.toJson());`.

### 3.2 `cafeteria_menu_item_service.dart`

- Similar structure with `_col = FirebaseFirestore.instance.collection('cafeteria_menu_items')`.
- `streamItems(String cafeteriaId)` -> stream filtered by `cafeteriaId`, order by `createdAt` descending, map to `CafeteriaMenuItem`.
- Provide optional helpers (`streamAllItems`, `getMenuItem`, `menuExists`) if needed.

## 4. Riverpod Providers (`lib/core/providers`)

### 4.1 `cafeteria_review_provider.dart`

- `cafeteriaReviewsProvider = StreamProvider.family<List<CafeteriaReview>, String>` delegating to `CafeteriaReviewService.streamReviews`.
- `CafeteriaReviewActions` class with:
  - `create(...)` requiring an authenticated user, constructing `CafeteriaReview` with `DateTime.now()` and defaulting `userName` to provided value or `displayName/email/"匿名"` fallback.
  - `update(...)` sending updates via `FirebaseFirestore.instance.collection('cafeteria_reviews').doc(reviewId).update(...)` (even though rules currently forbid updates, keep method for future use).
- `cafeteriaReviewActionsProvider = Provider((ref) => CafeteriaReviewActions());`

### 4.2 `cafeteria_menu_provider.dart`

- `cafeteriaMenuItemsProvider = StreamProvider.family<Map<String, CafeteriaMenuItem>, String>` returning a lower-cased lookup map.
- `cafeteriaMenuItemsListProvider = StreamProvider.family<List<CafeteriaMenuItem>, String>` for list access.
- Include `CafeteriaMenuItemActions` only if admin UI needs CRUD; otherwise creation is blocked.

## 5. UI Flow

### 5.1 Home Screen Entry Point

- In `HomeScreen` add a `FilledButton.icon` labeled `"学食レビュー"` with `Icons.reviews` that calls `_openCafeteriaReviews`.
- `_openCafeteriaReviews` pushes `CafeteriaReviewsScreen` via `MaterialPageRoute`.

### 5.2 `CafeteriaReviewsScreen`

- Scaffold with AppBar title `"学食レビュー"` and `TabBar` for three campuses: `津田沼`, `新習志野 1F`, `新習志野 2F`.
- `TabBarView` hosts `_MenuCardsList` per cafeteria ID.

### 5.3 `_MenuCardsList`

- Subscriber to both `cafeteriaReviewsProvider(cafeteriaId)` and `cafeteriaMenuItemsListProvider(cafeteriaId)`.
- Combine menu definitions and review aggregates so that:
  - Every menu from Firestore is shown, even with zero reviews.
  - Reviews lacking a matching menu item still appear, using review `menuName`.
  - Aggregation structure `_MenuAgg` keeps `menuName`, optional `CafeteriaMenuItem menuItem`, `count`, and `sumRecommend` with derived `avgRecommend`.
- Filtering:
  - TextField with hint `"メニュー名で検索（{campusName}のみ）"` using `_searchController`.
  - Filter aggregated list by lowercase menu name.
- Sorting priority:
  1. Descending `count` (menus with reviews first).
  2. Newer `menuItem.createdAt` if available.
  3. Alphabetical fallback on `menuName`.
- Render ListView of `_MenuRowCard` (no “メニューを追加” button).

### 5.4 `_MenuRowCard`

- Displays thumbnail image (`photoUrl`) or first letter placeholder.
- Title = `agg.menuName`.
- Rating row uses `_Stars` widget and label `({agg.count}件)` or `レビューなし` when `count == 0`.
- Price text uses helper `_formatPrice()` returning `"¥{price}"` or `"価格未設定"` if `price` is null.
- Card `onTap` pushes `CafeteriaMenuReviewsScreen` with current `cafeteriaId` and `menuName`.

### 5.5 `_Stars`

- Renders 5 icons with filled/half/outline depending on fractional rating.

### 5.6 `CafeteriaMenuReviewsScreen`

- Receives `cafeteriaId` + `menuName`.
- Header shows menu image/price/aggregated ratings broken down by overall taste, volume, recommend; retains existing gender-based volume average logic (male/female breakdown if data available).
- Lists individual reviews (filtered where `menuName` matches case-insensitively).
- FloatingActionButton opens `CafeteriaReviewFormScreen` with `fixed: true`, auto-filling cafeteria/menu fields; if user already has a review, pass `editingReview`.

### 5.7 `CafeteriaReviewFormScreen`

- Allows create or edit.
- Fields:
  - Dropdown for cafeteria (disabled when `fixed` or editing)
  - TextField for menu name (disabled when `fixed` or editing)
  - Ratings for taste/volume/recommend (1..5) using star pickers.
  - Gender radio buttons (`男性`, `女性`) storing `'male'`/`'female'` in `volumeGender`. Persist last choice using `sharedPreferencesProvider` key `cafeteria_volume_gender`.
  - Optional comment and user display name (defaults to logged-in user).
  - Submit button calling `CafeteriaReviewActions.create` or `.update`.
- Show SnackBars on success/failure and `Navigator.pop(true)` when done.

## 6. Additional Behaviour Notes

- `CafeteriaReviewsScreen` search should reset by clearing text and `_query` when clear icon tapped.
- Aggregation must ensure zero-review menus appear ahead of the empty-state label. If both menu list and reviews are empty, display `"表示できるメニューがありません"`.
- For zero reviews, use `_Stars` with rating 0 (all outlines) and review count label `レビューなし`.
- All Japanese UI strings must match existing literal values to preserve localisation.
- Use `InkWell` on cards to show tap feedback and `MaterialPageRoute` for navigation to sub-screens.

## 7. Testing & Verification Checklist

1. **Firestore rules**: Deploy updated rules; confirm creation fails when unauthenticated or when userId mismatch.
2. **Menu list**: Ensure menus without reviews still render with `価格未設定` if no price. Verify search filtering works.
3. **Aggregation**: Add multiple reviews for the same menu and confirm average stars and `(n件)` count update in real time.
4. **Detail screen**: Verify header stats reflect averages, including gender-based volume if data present.
5. **Review form**: Attempt create, edit, and cancel flows; ensure SnackBars fire and list updates after closing form.
6. **Error handling**: Validate Firestore stream errors render friendly `Text('レビューの読み込みに失敗しました: $e')` or `Text('メニュー情報の読み込みに失敗しました: $e')`.
7. **Platform**: Test on Android emulator and Flutter web (Chrome) to ensure responsive layout.

## 8. File Inventory

- `lib/models/cafeteria/cafeteria_review_model.dart`
- `lib/models/cafeteria/cafeteria_menu_item_model.dart`
- `lib/services/cafeteria/cafeteria_review_service.dart`
- `lib/services/cafeteria/cafeteria_menu_item_service.dart`
- `lib/core/providers/cafeteria_review_provider.dart`
- `lib/core/providers/cafeteria_menu_provider.dart`
- `lib/screens/cafeteria/cafeteria_reviews_screen.dart`
- `lib/screens/cafeteria/cafeteria_menu_reviews_screen.dart`
- `lib/screens/cafeteria/cafeteria_review_form_screen.dart`
- `lib/screens/home/home_screen.dart` (entry button)
- `firestore.rules`

Follow this specification precisely to reproduce the cafeteria review feature.
