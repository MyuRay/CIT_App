import 'dart:async';

import 'package:cit_app/core/providers/cwitter_provider.dart';
import 'package:cit_app/core/providers/cwitter_search_provider.dart';
import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/core/providers/user_block_provider.dart';
import 'package:cit_app/core/providers/user_provider.dart';
import 'package:cit_app/models/community/cwitter_follow_user.dart';
import 'package:cit_app/screens/community/widgets/cwitter_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  const user = CwitterFollowUser(
    authorId: 'student',
    cwitterId: 'student_123',
    displayName: '千葉 花子',
  );
  const other = CwitterFollowUser(
    authorId: 'other',
    cwitterId: 'other_456',
    displayName: '津田沼 太郎',
  );
  CwitterSearchResults results(List<CwitterFollowUser> users) => (
    posts: [],
    users: users,
    tagUsers: [],
  );

  Future<void> mount(
    WidgetTester tester,
    CwitterSearch search, {
    Set<String> hidden = const {},
  }) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cwitterSearchProvider.overrideWithValue(search),
          currentUserIdProvider.overrideWithValue('self'),
          hiddenUserIdsProvider.overrideWith((ref) => Stream.value(hidden)),
          cwitterRegisteredHashtagsProvider.overrideWith((ref) async => []),
          cwitterUserTagsProvider.overrideWith(
            (ref, uid) => const AsyncData([]),
          ),
          authorProfileImageUrlProvider.overrideWith(
            (ref, uid) => Stream.value(null),
          ),
          authorDisplayNameProvider.overrideWith(
            (ref, query) => Stream.value(query.fallback),
          ),
        ],
        child: const MaterialApp(home: CwitterSearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ユーザー'));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 410));
  }

  testWidgets('one user tab searches by either display name or ID', (
    tester,
  ) async {
    final queries = <String>[];
    await mount(tester, (query) async {
      queries.add(query);
      return results([user]);
    });
    expect(find.text('ID'), findsNothing);
    expect(find.text('表示名または @ID を入力（部分一致）'), findsOneWidget);
    await enter(tester, '花子');
    await tester.pumpAndSettle();
    expect(find.text(user.displayName), findsOneWidget);
    expect(find.text('@${user.cwitterId}'), findsOneWidget);
    await enter(tester, '@student');
    await tester.pumpAndSettle();
    expect(find.text(user.displayName), findsOneWidget);
    expect(queries, ['花子', '@student']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocked users remain excluded from combined search results', (
    tester,
  ) async {
    await mount(
      tester,
      (_) async => results([user, other]),
      hidden: {'student'},
    );
    await enter(tester, '検索');
    await tester.pumpAndSettle();
    expect(find.text(user.displayName), findsNothing);
    expect(find.text(other.displayName), findsOneWidget);
  });

  testWidgets('a slow old query cannot overwrite the latest name search', (
    tester,
  ) async {
    final old = Completer<CwitterSearchResults>();
    final latest = Completer<CwitterSearchResults>();
    await mount(tester, (query) => query == 'old' ? old.future : latest.future);
    await enter(tester, 'old');
    await enter(tester, '花子');
    latest.complete(results([user]));
    await tester.pumpAndSettle();
    old.complete(results([other]));
    await tester.pumpAndSettle();
    expect(find.text(user.displayName), findsOneWidget);
    expect(find.text(other.displayName), findsNothing);
  });

  testWidgets(
    'editing input invalidates old results during the debounce delay',
    (tester) async {
      final old = Completer<CwitterSearchResults>();
      await mount(
        tester,
        (query) => query == 'old' ? old.future : Future.value(results([user])),
      );
      await enter(tester, 'old');
      await tester.enterText(find.byType(TextField), '花子');
      old.complete(results([other]));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(other.displayName), findsNothing);
      await tester.pump(const Duration(milliseconds: 310));
      await tester.pumpAndSettle();
      expect(find.text(user.displayName), findsOneWidget);
    },
  );

  testWidgets(
    'clearing a query prevents a pending failure from replacing the hint',
    (tester) async {
      final pending = Completer<CwitterSearchResults>();
      await mount(tester, (_) => pending.future);
      await enter(tester, '花子');
      await tester.tap(find.byIcon(Icons.clear));
      pending.completeError(StateError('old request failed'));
      await tester.pumpAndSettle();
      expect(find.text('表示名または @ID を入力（部分一致）'), findsOneWidget);
      expect(find.textContaining('検索に失敗'), findsNothing);
    },
  );

  testWidgets('keyboard submit cancels the duplicate delayed request', (
    tester,
  ) async {
    var calls = 0;
    await mount(tester, (_) async {
      calls++;
      return results([user]);
    });
    await tester.enterText(find.byType(TextField), '花子');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text(user.displayName), findsOneWidget);
  });
}
