import 'dart:async';
import 'package:cit_app/screens/profile/account_deletion_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/theme_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<Brightness, ThemeData> themes;
  setUpAll(() async => themes = await loadTestThemes());
  Future<void> mount(
    WidgetTester tester,
    Future<void> Function(String) submit, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
                child: child!,
              ),
          home: const AccountDeletionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Password123');
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.ensureVisible(find.text('アカウントを削除する'));
    await tester.pump();
  }

  testWidgets(
    'password and confirmation required; one automatic request; no approval queue',
    (tester) async {
      final done = Completer<void>();
      var calls = 0;
      await mount(tester, (password) {
        expect(password, 'Password123');
        calls++;
        return done.future;
      });
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await confirm(tester);
      await tester.tap(find.text('アカウントを削除する'));
      await tester.pump();
      expect(calls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.text('アカウントの削除を開始しました。'), findsNothing);
      done.complete();
      await tester.pumpAndSettle();
      expect(find.text('アカウントの削除を開始しました。'), findsOneWidget);
      expect(find.textContaining('運営の承認は不要'), findsOneWidget);
      expect(find.textContaining('受付番号'), findsNothing);
    },
  );
  testWidgets('wrong password preserves form for retry', (tester) async {
    var calls = 0;
    await mount(tester, (_) async {
      if (++calls == 1) throw FirebaseAuthException(code: 'wrong-password');
    });
    await confirm(tester);
    await tester.tap(find.text('アカウントを削除する'));
    await tester.pumpAndSettle();
    expect(find.text('パスワードが正しくありません。'), findsOneWidget);
    await tester.ensureVisible(find.text('アカウントを削除する'));
    await tester.tap(find.text('アカウントを削除する'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('アカウントの削除を開始しました。'), findsOneWidget);
  });
  testWidgets('timeout does not falsely report successful acceptance', (
    tester,
  ) async {
    await mount(tester, (_) async => throw TimeoutException('timeout'));
    await confirm(tester);
    await tester.tap(find.text('アカウントを削除する'));
    await tester.pumpAndSettle();
    expect(find.textContaining('通信がタイムアウトしました'), findsOneWidget);
    expect(find.text('アカウントの削除を開始しました。'), findsNothing);
  });
  for (final brightness in Brightness.values) {
    testWidgets('deletion readable at 320px and 200% in $brightness', (
      tester,
    ) async {
      await mount(tester, (_) async {}, brightness: brightness, scale: 2);
      await confirm(tester);
      expect(tester.takeException(), isNull);
      expect(
        tester.getBottomRight(find.text('アカウントを削除する')).dy,
        lessThanOrEqualTo(796),
      );
    });
  }
}
