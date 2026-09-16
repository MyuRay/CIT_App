import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_app/screens/profile/account_deletion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());
  final boundary = GlobalKey();

  Future<void> mount(
    WidgetTester tester,
    Future<String> Function() submit, {
    Brightness brightness = Brightness.light,
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountDeletionSubmitProvider.overrideWithValue(submit)],
        child: MaterialApp(
          theme: themes[brightness],
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(bottom: 48),
                ),
                child: RepaintBoundary(key: boundary, child: child!),
              ),
          home: const AccountDeletionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.ensureVisible(find.text('削除を申請する'));
    await tester.pump();
  }

  testWidgets(
    'request requires consent, waits for persistence, and submits once',
    (tester) async {
      final done = Completer<String>();
      var calls = 0;
      await mount(tester, () {
        calls++;
        return done.future;
      });
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await confirm(tester);
      await tester.tap(find.text('削除を申請する'));
      await tester.pump();
      expect(find.text('受付済み・削除処理待ち'), findsNothing);
      await tester.tap(find.text('送信中…'));
      await tester.pump();
      expect(calls, 1);
      done.complete('request-123');
      await tester.pumpAndSettle();
      expect(find.text('受付番号：request-123'), findsOneWidget);
      expect(find.text('受付済み・削除処理待ち'), findsOneWidget);
      expect(find.text('削除を申請する'), findsNothing);
    },
  );

  testWidgets('failure keeps request editable with retry and email fallback', (
    tester,
  ) async {
    var calls = 0;
    await mount(tester, () async {
      if (++calls == 1) throw StateError('permission-denied');
      return 'retry-123';
    });
    await confirm(tester);
    await tester.tap(find.text('削除を申請する'));
    await tester.pumpAndSettle();
    expect(find.textContaining('申請を送信できませんでした'), findsOneWidget);
    expect(find.text('受付済み・削除処理待ち'), findsNothing);
    await tester.ensureVisible(find.text('削除を申請する'));
    await tester.tap(find.text('削除を申請する'));
    await tester.pumpAndSettle();
    expect(find.text('受付番号：retry-123'), findsOneWidget);
    await tester.ensureVisible(find.text('メールを作成'));
    expect(find.text(accountDeletionEmail), findsOneWidget);
  });

  testWidgets('timeout does not claim deletion or successful acceptance', (
    tester,
  ) async {
    final pending = Completer<String>();
    await mount(tester, () => pending.future);
    await confirm(tester);
    await tester.tap(find.text('削除を申請する'));
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.textContaining('送信結果を確認できませんでした'), findsOneWidget);
    expect(find.text('受付済み・削除処理待ち'), findsNothing);
    pending.complete('late-result');
    await tester.pumpAndSettle();
  });

  for (final brightness in Brightness.values) {
    testWidgets('deletion screen is scrollable in $brightness and large text', (
      tester,
    ) async {
      await mount(tester, () async => 'unused', brightness: brightness);
      if (themePreviewDirectory.isNotEmpty) {
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '$themePreviewDirectory/account-deletion-${brightness.name}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await mount(
        tester,
        () async => 'unused',
        brightness: brightness,
        width: 320,
        scale: 2,
      );
      await tester.scrollUntilVisible(find.text('コピー'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getBottomRight(find.text('コピー')).dy,
        lessThanOrEqualTo(796),
      );
    });
  }
}
