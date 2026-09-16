import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/core/providers/admin_provider.dart';
import 'package:cit_app/core/providers/filtered_bulletin_provider.dart';
import 'package:cit_app/core/theme/app_colors.dart';
import 'package:cit_app/models/admin/admin_model.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/models/bulletin/bulletin_model.dart';
import 'package:cit_app/screens/admin/bulletin_management_screen.dart';
import 'package:cit_app/screens/bulletin/bulletin_screen.dart';
import 'package:cit_app/services/bulletin/bulletin_admin_service.dart';
import 'package:cit_app/widgets/ads/in_app_ad_creative.dart';
import 'package:cit_app/widgets/ads/in_app_ad_editor_dialog.dart';
import 'package:cit_app/widgets/ads/sponsor_presentation.dart';
import 'package:cit_app/widgets/bulletin/bulletin_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../support/sponsor_fixtures.dart';
import '../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());
  final boundary = GlobalKey();
  final admin = AdminPermissions.fromJson({'userId': 'admin', 'isAdmin': true});

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    Brightness mode = Brightness.light,
    double width = 390,
    double scale = 1,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bulletinFeedHasMoreProvider.overrideWithValue(false),
          bulletinFeedErrorProvider.overrideWithValue(null),
          ...overrides,
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themes[mode],
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(bottom: 48),
                  ),
                  child: child!,
                ),
            home: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(
    WidgetTester tester,
    Widget dialog, {
    Brightness mode = Brightness.light,
    double width = 320,
    double scale = 2,
  }) async {
    await mount(
      tester,
      Scaffold(
        body: Builder(
          builder:
              (context) => Center(
                child: FilledButton(
                  onPressed:
                      () => showDialog<void>(
                        context: context,
                        builder: (_) => dialog,
                      ),
                  child: const Text('開く'),
                ),
              ),
        ),
      ),
      mode: mode,
      width: width,
      scale: scale,
    );
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (themePreviewDirectory.isEmpty) return;
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(themePreviewDirectory).create(recursive: true);
      await File(
        '$themePreviewDirectory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final mode in Brightness.values) {
    testWidgets('$mode gold colors and advertisement at 320px / 200%', (
      tester,
    ) async {
      await mount(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                InAppAdCreative(ad: sponsorTestAd()),
                InAppAdCreative(ad: sponsorTestAd(sponsored: false)),
              ],
            ),
          ),
        ),
        mode: mode,
        width: 320,
        scale: 2,
      );
      final colors = SponsorPalette.of(
        tester.element(find.byType(InAppAdCreative).first),
      );
      expect(
        AppColors.contrastRatio(colors.ink, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        AppColors.contrastRatio(colors.ink, colors.highlight),
        greaterThanOrEqualTo(4.5),
      );
      expect(find.text('広告'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('$mode public bulletin grid and sponsor frame', (tester) async {
      await mount(
        tester,
        const BulletinScreen(),
        mode: mode,
        overrides: [
          filteredBulletinPostsByCategoryProvider.overrideWith(
            (ref, category) => AsyncValue.data([
              sponsorTestPost(),
              sponsorTestPost(
                id: 'normal',
                sponsored: false,
                title: 'サークルからのお知らせ',
              ),
            ]),
          ),
          bulletinFeedIsLoadingMoreProvider.overrideWithValue(false),
        ],
      );
      expect(find.byType(SponsorBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'bulletin-' + mode.name);
    });

    testWidgets('$mode public bulletin at 320px / 200%', (tester) async {
      await mount(
        tester,
        const BulletinScreen(),
        mode: mode,
        width: 320,
        scale: 2,
        overrides: [
          filteredBulletinPostsByCategoryProvider.overrideWith(
            (ref, category) => AsyncValue.data([
              sponsorTestPost(name: 'とても長いスポンサー企業・店舗名称の表示確認'),
            ]),
          ),
          bulletinFeedIsLoadingMoreProvider.overrideWithValue(false),
        ],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('$mode bulletin settings at 320px / 200%', (tester) async {
      await openDialog(
        tester,
        BulletinSettingsDialog(
          post: sponsorTestPost(),
          onSave:
              ({
                required isSponsored,
                required sponsorName,
                required isActive,
                required isPinned,
                required allowComments,
                required expiresAt,
              }) async {},
        ),
        mode: mode,
      );
      expect(find.text('スポンサー名'), findsOneWidget);
      await tester.ensureVisible(find.text('期限なし'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('$mode advertisement editor at 320px / 200%', (tester) async {
      await openDialog(
        tester,
        InAppAdEditorDialog(
          ad: sponsorTestAd(),
          onSave: (_) async {},
          pickBulletin: () async => null,
        ),
        mode: mode,
      );
      await tester.ensureVisible(find.byType(InAppAdCreative));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('$mode admin search and selection at 320px / 200%', (
      tester,
    ) async {
      await mount(
        tester,
        const BulletinManagementScreen(),
        mode: mode,
        width: 320,
        scale: 2,
        overrides: [
          currentUserAdminProvider.overrideWith((ref) => Stream.value(admin)),
          adminBulletinPostsProvider.overrideWith(
            (ref) => Stream.value([
              sponsorTestPost(),
              sponsorTestPost(id: 'normal', sponsored: false, title: '一般投稿'),
            ]),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField), '津田沼カフェ');
      await tester.pumpAndSettle();
      expect(find.text('1件 / 全2件'), findsOneWidget);
      await tester.tap(find.byTooltip('検索をクリア'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(find.text('2件 / 全2件'), findsOneWidget);
      await tester.ensureVisible(find.text('複数選択'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('複数選択'));
      await tester.pumpAndSettle();
      expect(find.text('0件を選択中'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$mode manager previews all images at 320px / 200%', (
      tester,
    ) async {
      final post = BulletinPost.fromJson(
        sponsorTestPost().toJson()
          ..['imageUrl'] = 'https://example.com/first.png'
          ..['imageUrls'] = [
            'https://example.com/first.png',
            'https://example.com/second.png',
          ],
      );
      await mount(
        tester,
        const BulletinManagementScreen(),
        mode: mode,
        width: 320,
        scale: 2,
        overrides: [
          currentUserAdminProvider.overrideWith((ref) => Stream.value(admin)),
          adminBulletinPostsProvider.overrideWith(
            (ref) => Stream.value([post]),
          ),
        ],
      );
      await tester.scrollUntilVisible(
        find.text('プレビュー'),
        300,
        scrollable:
            find
                .descendant(
                  of: find.byType(CustomScrollView),
                  matching: find.byType(Scrollable),
                )
                .first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('プレビュー'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('プレビュー'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('表示プレビュー'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.widgetWithText(TextButton, '閉じる')).bottom,
        lessThanOrEqualTo(844 - 48),
      );
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
    });

    testWidgets('$mode sponsor and manager preview', (tester) async {
      await mount(
        tester,
        Scaffold(
          appBar: AppBar(title: const Text('スポンサー広告')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: InAppAdCreative(ad: sponsorTestAd()),
          ),
        ),
        mode: mode,
      );
      await capture(tester, 'ad-' + mode.name);
      await mount(
        tester,
        const BulletinManagementScreen(),
        mode: mode,
        overrides: [
          currentUserAdminProvider.overrideWith((ref) => Stream.value(admin)),
          adminBulletinPostsProvider.overrideWith(
            (ref) => Stream.value([
              sponsorTestPost(),
              sponsorTestPost(
                id: 'zz-pending',
                sponsored: false,
                approval: 'pending',
              ),
            ]),
          ),
        ],
      );
      await capture(tester, 'management-' + mode.name);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'failed settings save retains input and can retry without double submission',
    (tester) async {
      var saves = 0;
      var result = Completer<void>();
      await openDialog(
        tester,
        BulletinSettingsDialog(
          post: sponsorTestPost(),
          onSave: ({
            required isSponsored,
            required sponsorName,
            required isActive,
            required isPinned,
            required allowComments,
            required expiresAt,
          }) {
            saves++;
            expect(sponsorName, '新スポンサー');
            return result.future;
          },
        ),
        width: 390,
        scale: 1,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '津田沼カフェ'),
        '新スポンサー',
      );
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.tap(find.text('保存中…'));
      expect(saves, 1);
      result.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.text('新スポンサー'), findsWidgets);
      result = Completer<void>();
      await tester.tap(find.text('保存'));
      await tester.pump();
      result.complete();
      await tester.pumpAndSettle();
      expect(saves, 2);
      expect(find.byType(BulletinSettingsDialog), findsNothing);
    },
  );

  testWidgets('advertisement validates date range and saves sponsor fields', (
    tester,
  ) async {
    InAppAd? saved;
    await openDialog(
      tester,
      InAppAdEditorDialog(
        ad: sponsorTestAd().copyWith(
          startAt: sponsorTestNow,
          endAt: sponsorTestNow.subtract(const Duration(days: 1)),
        ),
        onSave: (ad) async => saved = ad,
        pickBulletin: () async => null,
      ),
      width: 390,
      scale: 1,
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(find.text('終了日時は開始日時より後にしてください'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('終了日時をクリア'));
    await tester.tap(find.byTooltip('終了日時をクリア'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(saved!.isSponsored, isTrue);
    expect(saved!.sponsorName, '津田沼カフェ');
    expect(saved!.endAt, isNull);
  });

  testWidgets('confirming an existing expiry does not extend it by a day', (
    tester,
  ) async {
    final expiry = DateTime(2026, 10, 1);
    DateTime? saved;
    await openDialog(
      tester,
      BulletinSettingsDialog(
        post: sponsorTestPost(expiry: expiry),
        onSave:
            ({
              required isSponsored,
              required sponsorName,
              required isActive,
              required isPinned,
              required allowComments,
              required expiresAt,
            }) async => saved = expiresAt,
      ),
      width: 390,
      scale: 1,
    );
    await tester.ensureVisible(find.text('期限を変更'));
    await tester.tap(find.text('期限を変更'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DatePickerDialog>(find.byType(DatePickerDialog))
          .initialDate,
      DateTime(2026, 9, 30),
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(saved, expiry);
  });

  testWidgets('non-admin cannot view management data', (tester) async {
    var subscribed = false;
    await mount(
      tester,
      const BulletinManagementScreen(),
      overrides: [
        currentUserAdminProvider.overrideWith((ref) => Stream.value(null)),
        adminBulletinPostsProvider.overrideWith((ref) {
          subscribed = true;
          return Stream.value([]);
        }),
      ],
    );
    expect(find.text('管理者権限が必要です'), findsOneWidget);
    expect(subscribed, isFalse);
  });
}
