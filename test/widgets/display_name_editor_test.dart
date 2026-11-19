import 'dart:async';

import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/widgets/profile/display_name_editor.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _SavingAuthService extends AuthService {
  _SavingAuthService(super.auth, this.save);

  final Future<void> Function(String) save;

  @override
  Future<void> updateDisplayName(String newName) => save(newName);
}

void main() {
  late MockFirebaseAuth auth;
  late List<String> saves;
  late Future<void> Function(String) save;

  setUp(() {
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'self', displayName: '変更前の名前'),
    );
    saves = [];
    save = (name) async => saves.add(name);
  });

  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          authServiceProvider.overrideWithValue(
            _SavingAuthService(auth, (name) => save(name)),
          ),
        ],
        child: MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
          home: Scaffold(
            body: Consumer(
              builder:
                  (context, ref, _) => TextButton(
                    onPressed:
                        () => showDisplayNameEditor(
                          context,
                          ref,
                          currentDisplayName: '変更前の名前',
                        ),
                    child: const Text('編集を開く'),
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('編集を開く'));
    await tester.pumpAndSettle();
  }

  testWidgets('empty input and cancellation never save a profile', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '  ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('表示名を入力してください'), findsOneWidget);
    expect(saves, isEmpty);

    await tester.enterText(find.byType(TextFormField), '保存しない名前');
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(saves, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('表示名を更新しました'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failure retains the draft and only a successful retry closes', (
    tester,
  ) async {
    save = (_) async => throw StateError('profile write failed');
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '  新しい名前  ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('表示名を更新できませんでした。もう一度お試しください。'), findsOneWidget);
    expect(find.text('表示名を更新しました'), findsNothing);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '  新しい名前  ',
    );

    save = (name) async => saves.add(name);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(saves, ['新しい名前']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('表示名を更新しました'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('waits for storage and prevents repeated saves or dismissal', (
    tester,
  ) async {
    final pending = Completer<void>();
    save = (name) {
      saves.add(name);
      return pending.future;
    };
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '新しい名前');
    await tester.tap(find.text('保存'));
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(saves, ['新しい名前']);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('表示名を更新しました'), findsNothing);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('表示名を更新しました'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not apply a previous account draft after sign out', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '前のアカウントの名前');
    await auth.signOut();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(saves, isEmpty);
    expect(find.text('ログイン状態が変わりました。画面を閉じてやり直してください。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared editor fits a narrow screen at 200 percent text', (
    tester,
  ) async {
    await open(tester, scale: 2);
    expect(find.text('マイページとCwitterで共通の表示名です。'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(saves, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
