import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_app/core/providers/admin_provider.dart';
import 'package:cit_app/core/providers/cwitter_pin_provider.dart';
import 'package:cit_app/core/providers/cwitter_provider.dart';
import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/core/providers/user_block_provider.dart';
import 'package:cit_app/core/providers/user_provider.dart';
import 'package:cit_app/models/community/cwitter_activity_counts.dart';
import 'package:cit_app/models/community/cwitter_follow_counts.dart';
import 'package:cit_app/models/community/cwitter_post.dart';
import 'package:cit_app/models/community/cwitter_profile_activity.dart';
import 'package:cit_app/models/community/cwitter_profile_user.dart';
import 'package:cit_app/models/user/user_model.dart';
import 'package:cit_app/screens/community/widgets/cwitter_more_menu.dart';
import 'package:cit_app/screens/community/widgets/cwitter_post_card.dart';
import 'package:cit_app/screens/community/community_time_format.dart';
import 'package:cit_app/screens/community/widgets/cwitter_profile_screen.dart';
import 'package:cit_app/services/auth/session_work_guard.dart';
import 'package:cit_app/services/community/cwitter_pin_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../support/theme_test_fonts.dart';

void main() {
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async {
    themes = await loadTestThemes();
  });
  final old = CwitterPost(
    id: 'old',
    authorId: 'owner',
    cwitterId: 'owner',
    displayName: '学生',
    body: '古い固定Cweet',
    createdAt: DateTime(2020),
  );
  final recent = CwitterPost(
    id: 'recent',
    authorId: 'owner',
    cwitterId: 'owner',
    displayName: '学生',
    body: '新しいCweet',
    createdAt: DateTime(2026),
  );
  final user = AppUser(
    uid: 'owner',
    email: 'owner@chibatech.ac.jp',
    displayName: '学生',
    cwitterId: 'owner',
    createdAt: DateTime(2020),
  );
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late CwitterPinService service;
  final preview = GlobalKey();

  setUp(() async {
    SessionWorkGuard.resume();
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'owner'));
    service = CwitterPinService(firestore: db, auth: auth);
    await db.doc('users/owner').set({
      'displayName': '学生',
      'cwitterId': 'owner',
      CwitterPinService.field: old.id,
    });
    await db.doc('cwitter_posts/old').set(old.toJson());
    await db.doc('cwitter_posts/recent').set(recent.toJson());
  });

  Future<void> mount(
    WidgetTester tester, {
    bool self = true,
    bool includeOld = true,
    double scale = 1,
    Brightness brightness = Brightness.light,
    List<String> tags = const [],
  }) async {
    tester.view.physicalSize = const Size(320, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(self ? 'owner' : 'viewer'),
          currentAppUserStreamProvider.overrideWith(
            (ref) => Stream.value(user),
          ),
          isAdminProvider.overrideWithValue(false),
          cwitterPinServiceProvider.overrideWithValue(service),
          hiddenUserIdsProvider.overrideWith((ref) => Stream.value(<String>{})),
          blockedUsersProvider.overrideWith((ref) => Stream.value([])),
          cwitterTagsOverrideSyncProvider.overrideWith((ref) {}),
          cwitterUserTagsProvider.overrideWith((ref, uid) => AsyncData(tags)),
          cwitterUserBioProvider.overrideWith((ref, uid) => Stream.value(null)),
          cwitterUserSocialLinksProvider.overrideWith(
            (ref, uid) => Stream.value({}),
          ),
          authorDisplayNameProvider.overrideWith(
            (ref, query) => Stream.value(query.fallback),
          ),
          authorProfileImageUrlProvider.overrideWith(
            (ref, uid) => Stream.value(null),
          ),
          cwitterFollowCountsProvider.overrideWith(
            (ref, uid) => Stream.value(const CwitterFollowCounts()),
          ),
          cwitterUserCweetCountsProvider.overrideWith(
            (ref, uid) =>
                Stream.value(const CwitterActivityCounts(postCount: 2)),
          ),
          cwitterIsFollowingProvider.overrideWith(
            (ref, target) => Stream.value(false),
          ),
          cwitterIsRecweetedProvider.overrideWith(
            (ref, target) => Stream.value(false),
          ),
          cwitterPostReplyCountProvider.overrideWith(
            (ref, id) => Stream.value(0),
          ),
          filteredCwitterUserActivityProvider.overrideWith(
            (ref, uid) => AsyncData([
              CwitterProfileActivity.post(recent),
              if (includeOld) CwitterProfileActivity.post(old),
            ]),
          ),
          filteredLikedCwitterPostsProvider.overrideWithValue(
            const AsyncData([]),
          ),
        ],
        child: MaterialApp(
          theme: themes[brightness],
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
          home: RepaintBoundary(
            key: preview,
            child: CwitterProfileScreen(
              user:
                  self
                      ? null
                      : const CwitterProfileUser(
                        authorId: 'owner',
                        cwitterId: 'owner',
                        displayName: '学生',
                      ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<CwitterPostCard> cards(WidgetTester tester) =>
      tester.widgetList<CwitterPostCard>(find.byType(CwitterPostCard)).toList();
  Future<void> menu(WidgetTester tester, String id) async {
    final card = find.byWidgetPredicate(
      (widget) => widget is CwitterPostCard && widget.post.id == id,
    );
    await tester.ensureVisible(card);
    await tester.tap(
      find.descendant(of: card, matching: find.byType(CwitterMoreMenu)),
    );
    await tester.pumpAndSettle();
  }

  for (final self in [true, false]) {
    testWidgets('pin is first without duplication for self=$self', (
      tester,
    ) async {
      await mount(tester, self: self);
      expect(cards(tester).map((card) => card.post.id), ['old', 'recent']);
      expect(cards(tester).first.showPinnedLabel, isTrue);
      expect(find.text('固定されたCweet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('post time stays left of the reactions on the same row', (
    tester,
  ) async {
    await mount(tester, scale: 2);
    final card = find.byWidgetPredicate(
      (widget) => widget is CwitterPostCard && widget.post.id == old.id,
    );
    final time = find.descendant(
      of: card,
      matching: find.text(formatCommunityRelativeTime(old.createdAt)),
    );
    final like = find.descendant(
      of: card,
      matching: find.byIcon(Icons.favorite_border),
    );
    expect(tester.getCenter(time).dy, closeTo(tester.getCenter(like).dy, 1));
    expect(tester.getRect(time).right, lessThan(tester.getRect(like).left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an old pin outside the activity page is still displayed', (
    tester,
  ) async {
    await mount(tester, includeOld: false);
    expect(cards(tester).map((card) => card.post.id), ['old', 'recent']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancel replacement preserves the pin, confirmation replaces it',
    (tester) async {
      await mount(tester);
      await menu(tester, 'recent');
      await tester.tap(find.text('プロフィールに固定'));
      await tester.pumpAndSettle();
      expect(find.text('固定するCweetを変更'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(cards(tester).first.post.id, 'old');
      await menu(tester, 'recent');
      await tester.tap(find.text('プロフィールに固定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('変更する'));
      await tester.pumpAndSettle();
      expect(cards(tester).map((card) => card.post.id), ['recent', 'old']);
      expect(
        (await db.doc('users/owner').get()).data()![CwitterPinService.field],
        'recent',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unpin restores chronological activity order', (tester) async {
    await mount(tester);
    await menu(tester, 'old');
    await tester.tap(find.text('固定を解除'));
    await tester.pumpAndSettle();
    expect(cards(tester).map((card) => card.post.id), ['recent', 'old']);
    expect(find.text('固定されたCweet'), findsNothing);
    expect(
      (await db.doc('users/owner').get()).data()!.containsKey(
        CwitterPinService.field,
      ),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('another viewer has no pin or unpin menu', (tester) async {
    await mount(tester, self: false);
    await menu(tester, 'old');
    expect(find.text('固定を解除'), findsNothing);
    expect(find.text('プロフィールに固定'), findsNothing);
    expect(find.text('通報'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'pin controls fit narrow profiles with large text in $brightness',
      (tester) async {
        await mount(
          tester,
          scale: 2,
          brightness: brightness,
          tags: const ['創造工学部', 'デザイン科学科'],
        );
        expect(find.text('固定されたCweet'), findsOneWidget);
        await menu(tester, 'recent');
        expect(find.text('プロフィールに固定'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (themePreviewDirectory.isNotEmpty) {
          // Dismiss the popup before capturing the actual profile.
          await tester.tapAt(const Offset(4, 4));
          await tester.pumpAndSettle();
          final scrollState = tester.state<NestedScrollViewState>(
            find.byType(NestedScrollView),
          );
          scrollState.innerController.jumpTo(0);
          scrollState.outerController.jumpTo(0);
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final boundary =
                preview.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              '$themePreviewDirectory/profile-${brightness.name}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
  }

  testWidgets(
    'a failed save retains the pin and shows an error instead of success',
    (tester) async {
      await mount(tester);
      await auth.signOut();
      await menu(tester, 'old');
      await tester.tap(find.text('固定を解除'));
      await tester.pumpAndSettle();
      expect(find.text('ログイン状態を確認してください'), findsOneWidget);
      expect(find.text('固定を解除しました'), findsNothing);
      expect(cards(tester).first.post.id, 'old');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pin action is disabled while a save is already in progress', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isAdminProvider.overrideWithValue(false)],
        child: MaterialApp(
          home: Scaffold(
            body: CwitterMoreMenu(
              isOwner: true,
              pinEnabled: false,
              onPin: () async {
                calls++;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(CwitterMoreMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('プロフィールに固定'));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });
}
