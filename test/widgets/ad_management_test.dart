import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cit_app/core/providers/admin_provider.dart';
import 'package:cit_app/core/providers/in_app_ad_provider.dart';
import 'package:cit_app/models/admin/admin_model.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/screens/admin/in_app_ad_management_screen.dart';
import 'package:cit_app/widgets/ads/in_app_ad_creative.dart';
import 'package:cit_app/widgets/ads/in_app_ad_editor_dialog.dart';
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
  final ads = [
    sponsorTestAd().copyWith(id: 'active', title: '学生応援キャンペーン'),
    sponsorTestAd().copyWith(
      id: 'future',
      title: '新学期フェア',
      startAt: DateTime(2100),
    ),
    sponsorTestAd(sponsored: false).copyWith(
      id: 'paused',
      title: '学食のおすすめ',
      isActive: false,
      placement: AdPlacement.cafeteria,
    ),
    sponsorTestAd().copyWith(
      id: 'ended',
      title: '終了したキャンペーン',
      endAt: DateTime(2000),
    ),
  ];

  Future<void> mount(
    WidgetTester tester, {
    Brightness mode = Brightness.light,
    Size size = const Size(390, 844),
    double scale = 1,
    Widget? editor,
    bool isAdmin = true,
    VoidCallback? subscribed,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserAdminProvider.overrideWith(
            (ref) => Stream.value(
              isAdmin
                  ? AdminPermissions.fromJson({
                    'userId': 'admin',
                    'isAdmin': true,
                  })
                  : null,
            ),
          ),
          inAppAdsStreamProvider.overrideWith((ref) {
            subscribed?.call();
            return Stream.value(ads);
          }),
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
            home:
                editor == null
                    ? const InAppAdManagementScreen()
                    : Scaffold(
                      body: Builder(
                        builder:
                            (ctx) => TextButton(
                              onPressed:
                                  () => showDialog<void>(
                                    context: ctx,
                                    barrierDismissible: false,
                                    builder: (_) => editor,
                                  ),
                              child: const Text('開く'),
                            ),
                      ),
                    ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (editor != null) {
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (themePreviewDirectory.isEmpty) return;
    await tester.runAsync(() async {
      final picture =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await Directory(themePreviewDirectory).create(recursive: true);
      await File(
        '$themePreviewDirectory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  }

  testWidgets(
    'filters compose, clear resets search and placement, no writes required',
    (tester) async {
      await mount(tester);
      await tester.enterText(find.byKey(const Key('ad_search')), '津田沼');
      await tester.pumpAndSettle();
      expect(find.text('3件 / 全4件'), findsOneWidget);
      await tap(tester, find.byKey(const Key('ad_status_running')));
      expect(find.text('1件 / 全4件'), findsOneWidget);
      await tap(tester, find.text('絞り込みを解除'));
      expect(find.text('4件 / 全4件'), findsOneWidget);
      await tap(tester, find.byKey(const Key('ad_filters')));
      await tap(tester, find.byKey(const Key('ad_placement_all')));
      await tap(tester, find.text('学食').last);
      expect(find.text('1件 / 全4件'), findsOneWidget);
      await tap(tester, find.byKey(const Key('ad_sponsors')));
      expect(find.text('0件 / 全4件'), findsOneWidget);
      await tap(tester, find.text('絞り込みを解除'));
      expect(find.text('4件 / 全4件'), findsOneWidget);
    },
  );

  testWidgets('non-admin never subscribes to advertisements', (tester) async {
    var subscribed = false;
    await mount(tester, isAdmin: false, subscribed: () => subscribed = true);
    expect(find.text('管理者権限が必要です'), findsOneWidget);
    expect(subscribed, false);
  });

  testWidgets(
    'preview is passive and duplicate opens a paused editable draft',
    (tester) async {
      await mount(tester);
      final card = find.byKey(const Key('ad_card_active'));
      await tap(
        tester,
        find.descendant(of: card, matching: find.text('プレビュー')),
      );
      expect(
        tester.widget<InAppAdCreative>(find.byType(InAppAdCreative)).onTap,
        isNull,
      );
      await tap(tester, find.text('閉じる'));
      await tap(tester, find.byKey(const Key('ad_menu_active')));
      await tap(tester, find.text('複製して作成'));
      final editor = tester.widget<InAppAdEditorDialog>(
        find.byType(InAppAdEditorDialog),
      );
      expect(editor.isDuplicate, true);
      expect(editor.ad!.isActive, false);
      expect(editor.ad!.id, '');
      expect(editor.ad!.sponsorName, ads.first.sponsorName);
    },
  );

  testWidgets(
    'editing a link prompts before discard; failed save retains input and retries',
    (tester) async {
      var attempts = 0;
      var result = Completer<void>();
      InAppAd? saved;
      await mount(
        tester,
        editor: InAppAdEditorDialog(
          ad: sponsorTestAd(),
          pickBulletin: () async => null,
          onSave: (ad) {
            saved = ad;
            attempts++;
            return result.future;
          },
        ),
      );
      final link = find.byKey(const Key('ad_editor_payload'));
      await tester.ensureVisible(link);
      await tester.enterText(link, 'https://example.com/new');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('変更を破棄しますか？'), findsOneWidget);
      await tap(tester, find.text('編集を続ける'));
      await tester.tap(find.byKey(const Key('ad_editor_save')));
      await tester.pump();
      expect(attempts, 1);
      await tester.tap(find.byKey(const Key('ad_editor_save')));
      await tester.pump();
      expect(attempts, 1);
      result.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.textContaining('保存できませんでした'), findsOneWidget);
      result = Completer<void>();
      await tester.tap(find.byKey(const Key('ad_editor_save')));
      await tester.pump();
      result.complete();
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(saved!.actionPayload, 'https://example.com/new');
      expect(saved!.ctaText, sponsorTestAd().ctaText);
      expect(find.byType(InAppAdEditorDialog), findsNothing);
    },
  );

  for (final mode in Brightness.values) {
    testWidgets(
      '$mode list and editor fit 320px 200 percent and system navigation',
      (tester) async {
        await mount(tester, mode: mode, size: const Size(320, 700), scale: 2);
        await tester.scrollUntilVisible(
          find.byKey(const Key('ad_card_active')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        await tap(
          tester,
          find.descendant(
            of: find.byKey(const Key('ad_card_active')),
            matching: find.text('編集'),
          ),
        );
        final save = find.byKey(const Key('ad_editor_save'));
        expect(tester.getRect(save).bottom, lessThanOrEqualTo(652));
        await tester.ensureVisible(find.text('配信を有効にする'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(tester, 'ad-editor-large-text-${mode.name}');
      },
    );
    testWidgets('$mode list and editor visual previews', (tester) async {
      await mount(tester, mode: mode);
      await capture(tester, 'ads-${mode.name}');
      await tester.scrollUntilVisible(
        find.byKey(const Key('ad_card_active')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await capture(tester, 'ad-card-${mode.name}');
      await tap(
        tester,
        find.descendant(
          of: find.byKey(const Key('ad_card_active')),
          matching: find.text('編集'),
        ),
      );
      await capture(tester, 'ad-editor-${mode.name}');
      expect(tester.takeException(), isNull);
    });
    testWidgets('$mode desktop has side-by-side live preview', (tester) async {
      await mount(
        tester,
        mode: mode,
        size: const Size(1200, 900),
        editor: InAppAdEditorDialog(
          ad: sponsorTestAd(),
          onSave: (_) async {},
          pickBulletin: () async => null,
        ),
      );
      expect(find.byType(InAppAdCreative), findsOneWidget);
      await capture(tester, 'ad-editor-desktop-${mode.name}');
      expect(tester.takeException(), isNull);
    });
  }
}
