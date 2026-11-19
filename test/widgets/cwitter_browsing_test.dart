import 'package:cit_app/core/providers/admin_provider.dart';
import 'package:cit_app/core/providers/cwitter_provider.dart';
import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/core/providers/user_provider.dart';
import 'package:cit_app/models/community/cwitter_post.dart';
import 'package:cit_app/models/user/user_model.dart';
import 'package:cit_app/screens/community/widgets/cwitter_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StaticFeed extends CwitterFeedNotifier {
  _StaticFeed(super.ref);
  @override
  Future<void> refresh() async {
    state = const CwitterFeedState(hasMore: false);
  }
}

void main() {
  final post = CwitterPost(
    id: 'post',
    authorId: 'author',
    cwitterId: 'author',
    displayName: '投稿者',
    body: 'IDがなくても読める投稿です',
    createdAt: DateTime(2026, 10, 30),
  );
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> mount(WidgetTester tester, {String uid = 'viewer'}) async {
    final user = AppUser(
      uid: uid,
      email: '$uid@chibatech.ac.jp',
      displayName: '閲覧者',
      emailVerified: true,
      createdAt: DateTime(2026, 10, 30),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: CwitterTab()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          currentUserIdProvider.overrideWithValue(uid),
          currentAppUserStreamProvider.overrideWith(
            (ref) => Stream.value(user),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isAdminProvider.overrideWithValue(false),
          cwitterFeedProvider.overrideWith((ref) => _StaticFeed(ref)),
          cwitterPostsProvider.overrideWithValue(AsyncData([post])),
          filteredCwitterPostsProvider.overrideWithValue(AsyncData([post])),
          cwitterLatestPostCreatedAtProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
          cwitterTagsOverrideSyncProvider.overrideWith((ref) {}),
          cwitterFollowingUserIdsProvider.overrideWith(
            (ref, id) => Stream.value(<String>{}),
          ),
          cwitterIsRecweetedProvider.overrideWith(
            (ref, target) => Stream.value(false),
          ),
          cwitterPostReplyCountProvider.overrideWith(
            (ref, id) => Stream.value(0),
          ),
          cwitterUserTagsProvider.overrideWith(
            (ref, id) => const AsyncData(<String>[]),
          ),
          authorDisplayNameProvider.overrideWith(
            (ref, query) => Stream.value(query.fallback),
          ),
          authorProfileImageUrlProvider.overrideWith(
            (ref, id) => Stream.value(null),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'later opens the feed without an ID and persists for the same account',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('CweetIDをあとで設定する'));
      await tester.pumpAndSettle();
      expect(find.text('IDがなくても読める投稿です'), findsOneWidget);
      expect(find.text('CweetIDを設定して参加する'), findsOneWidget);
      expect(prefs.getBool('cwitter_id_setup_deferred:viewer'), isTrue);
      await mount(tester);
      expect(find.text('IDがなくても読める投稿です'), findsOneWidget);
      await mount(tester, uid: 'another');
      expect(find.text('CweetIDをあとで設定する'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'like and recweet ask for an ID and cancellation keeps the feed readable',
    (tester) async {
      await prefs.setBool('cwitter_id_setup_deferred:viewer', true);
      await mount(tester);
      for (final icon in [Icons.favorite_border, Icons.repeat]) {
        await tester.ensureVisible(find.byIcon(icon).first);
        await tester.tap(find.byIcon(icon).first);
        await tester.pumpAndSettle();
        expect(find.text('CweetIDを設定'), findsOneWidget);
        await tester.tap(find.text('あとで'));
        await tester.pumpAndSettle();
        expect(find.text('IDがなくても読める投稿です'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a required action can open setup and return to reading without claiming an ID',
    (tester) async {
      await prefs.setBool('cwitter_id_setup_deferred:viewer', true);
      await mount(tester);
      await tester.tap(find.text('CweetIDを設定して参加する'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('設定する'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      await tester.tap(find.text('CweetIDをあとで設定する'));
      await tester.pumpAndSettle();
      expect(find.text('IDがなくても読める投稿です'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
