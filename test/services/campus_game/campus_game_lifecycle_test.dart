import 'dart:async';
import 'dart:convert';
import 'package:cit_app/services/campus_game/campus_game_service.dart';
import 'package:cit_app/services/campus_game/campus_game_view_bridge.dart';
import 'package:cit_app/services/campus_game/campus_race_best_store.dart';
import 'package:cit_app/screens/classroom_map/campus_game_online_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('standalone preview without Firebase returns a login error', () async {
    final service = CampusGameService();
    final response = await service.handle({'action': 'courses'});
    expect(response['ok'], false);
    expect(response['error'], 'オンライン機能にはログインが必要です');
    service.dispose();
  });
  test(
    'HTTP uses only the fixed authenticated callable and profile whitelist',
    () async {
      final service = CampusGameService(
        tokenProvider: () async => 'test-secret',
        client: MockClient((request) async {
          expect(request.url, CampusGameService.endpoint);
          expect(request.headers['Authorization'], 'Bearer test-secret');
          final body = jsonDecode(request.body) as Map;
          expect(body['data'], {'action': 'profile', 'consent': false});
          return http.Response(
            jsonEncode({
              'result': {'nickname': 'BusFan'},
            }),
            200,
          );
        }),
      );
      await service.call('profile', {
        'nickname': 'BusFan',
        'consent': false,
        'email': 'private@example.test',
        'action': 'writeScore',
      });
      service.dispose();
    },
  );
  test('401 and timeout produce explicit recoverable errors', () async {
    final unauthorized = CampusGameService(
      tokenProvider: () async => 'test',
      client: MockClient((_) async => http.Response('Unauthorized', 401)),
    );
    expect(
      (await unauthorized.handle({'action': 'courses'}))['error'],
      'ログイン状態を確認して再接続してください',
    );
    unauthorized.dispose();
    final timeout = CampusGameService(
      tokenProvider: () async => 'test',
      client: MockClient((_) async => throw TimeoutException('request')),
    );
    expect(
      (await timeout.handle({'action': 'courses'}))['error'],
      '通信がタイムアウトしました。再接続してください',
    );
    timeout.dispose();
  });
  test('late join is left without replacing the new viewer lobby', () async {
    final pending = Completer<Map<String, dynamic>>();
    final left = <String>[];
    final service = CampusGameService(
      transport: (action, payload) async {
        if (action == 'joinRoom') return pending.future;
        if (action == 'leaveRoom') left.add(payload['roomId'] as String);
        return {};
      },
    );
    final request = service.handle({
      'action': 'joinRoom',
      'payload': {'code': 'ABCDEF123456'},
    });
    service.detach();
    service.watchRoom({'roomId': 'new', 'players': []});
    pending.complete({'roomId': 'old', 'players': []});
    expect((await request)['ok'], false);
    await Future<void>.delayed(Duration.zero);
    expect(left, ['old']);
    expect(service.room?['roomId'], 'new');
    service.dispose();
  });
  test('late poll does not restore a detached room or its error', () async {
    final pending = Completer<Map<String, dynamic>>();
    final service = CampusGameService(
      transport:
          (action, payload) async => action == 'room' ? pending.future : {},
    );
    service.watchRoom({'roomId': 'old'});
    final polling = service.reconnect();
    service.detach();
    service.watchRoom({'roomId': 'new'});
    pending.complete({'roomId': 'old'});
    await polling;
    expect(service.room?['roomId'], 'new');
    expect(service.error, isNull);
    service.dispose();
  });
  test(
    'failed leave still stops local polling and detach cancels a challenge',
    () async {
      final calls = <String>[];
      final service = CampusGameService(
        transport: (action, payload) async {
          calls.add(action);
          if (action == 'leaveRoom') throw const CampusGameException('offline');
          if (action == 'challenge') return {'challengeId': 'solo'};
          return {};
        },
      );
      service.watchRoom({'roomId': 'room'});
      await expectLater(service.leave(), throwsA(isA<CampusGameException>()));
      expect(service.room, isNull);
      await service.call('challenge', {'direction': 'outward'});
      service.detach();
      await Future<void>.delayed(Duration.zero);
      expect(calls, contains('cancelChallenge'));
      expect(service.challengeId, isNull);
      service.dispose();
    },
  );
  test('bridge ignores sends after disposal', () async {
    final bridge = CampusGameViewBridge(
      onRequest: (_) async {},
      onDetached: () {},
    );
    var updates = 0;
    bridge.addListener(() => updates++);
    bridge.send({'ok': true});
    bridge.dispose();
    bridge.send({'ok': false});
    expect(updates, 1);
  });
  test(
    'native best writes are serialized and invalid keys never persist',
    () async {
      SharedPreferences.setMockInitialValues({
        'cit_bus_best_v1_return_12345678': 1200,
        'unrelated': 1,
        'cit_bus_best_v1_outward_aaaaaaaa': 'bad',
      });
      final store = CampusRaceBestStore();
      final results = await Future.wait([
        store.save('cit_bus_best_v1_outward_12345678', 3000),
        store.save('cit_bus_best_v1_outward_12345678', 1000),
        store.save('cit_bus_best_v1_outward_12345678', 2000),
        store.save('unrelated', 5),
        store.save('cit_bus_best_v1_return_12345678', 0),
      ]);
      expect(results, [true, true, true, false, false]);
      expect(await store.load(), {
        'cit_bus_best_v1_outward_12345678': 1000,
        'cit_bus_best_v1_return_12345678': 1200,
      });
    },
  );
  test('storage failure cannot crash viewer load or finish', () async {
    final store = CampusRaceBestStore(
      preferences: () async => throw StateError('storage unavailable'),
    );
    expect(await store.load(), isEmpty);
    expect(await store.save('cit_bus_best_v1_outward_12345678', 1000), false);
  });
  testWidgets('320px landscape panel at 200 percent text remains scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = CampusGameService(transport: (a, p) async => {});
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
        home: Scaffold(body: CampusGameOnlinePanel(service: service)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('この方向のランキングを表示'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
  testWidgets('full 12-digit room code is pasted and sent without truncation', (
    tester,
  ) async {
    final calls = <Map<String, dynamic>>[];
    final service = CampusGameService(
      transport: (a, p) async {
        calls.add({'action': a, ...p});
        if (a == 'getProfile') return {'nickname': 'BusFan', 'consent': false};
        if (a == 'profile') return {};
        return {
          'roomId': 'room',
          'code': 'ABCDEF123456',
          'status': 'lobby',
          'players': [
            {
              'nickname': 'BusFan',
              'ready': false,
              'status': 'waiting',
              'progress': 0,
            },
          ],
        };
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CampusGameOnlinePanel(service: service)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ABCDEF123456');
    await tester.ensureVisible(find.text('コードで参加'));
    await tester.tap(find.text('コードで参加'));
    await tester.pumpAndSettle();
    expect(calls[1], {'action': 'profile', 'consent': false});
    expect(calls[2], {'action': 'joinRoom', 'code': 'ABCDEF123456'});
    expect(service.room?['roomId'], 'room');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
  test(
    'fractional native best is rejected while rounded milliseconds persist',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = CampusRaceBestStore();
      expect(
        await store.save('cit_bus_best_v1_outward_12345678', 1000.5),
        false,
      );
      expect(await store.load(), isEmpty);
      expect(await store.save('cit_bus_best_v1_outward_12345678', 1001), true);
      expect(await store.load(), {'cit_bus_best_v1_outward_12345678': 1001});
    },
  );

  testWidgets('stored opt-in is loaded before room profile writes', (
    tester,
  ) async {
    final loading = Completer<Map<String, dynamic>>();
    final calls = <Map<String, dynamic>>[];
    final service = CampusGameService(
      transport: (action, payload) async {
        calls.add({'action': action, ...payload});
        if (action == 'getProfile') return loading.future;
        if (action == 'createRoom') {
          return {
            'roomId': 'room',
            'code': 'ABCDEF123456',
            'status': 'lobby',
            'players': [],
          };
        }
        return {};
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CampusGameOnlinePanel(service: service)),
      ),
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'ルームを作成'))
          .onPressed,
      isNull,
    );
    loading.complete({'nickname': 'ChosenNickname', 'consent': true});
    await tester.pumpAndSettle();
    expect(find.text('マイページのニックネーム: ChosenNickname'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, true);
    await tester.ensureVisible(find.text('ルームを作成'));
    await tester.tap(find.text('ルームを作成'));
    await tester.pumpAndSettle();
    expect(calls[1], {'action': 'profile', 'consent': true});
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
  testWidgets('failed profile read never submits a default opt-out', (
    tester,
  ) async {
    final calls = <String>[];
    final service = CampusGameService(
      transport: (action, payload) async {
        calls.add(action);
        throw const CampusGameException('オンライン機能はサーバー反映待ち');
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CampusGameOnlinePanel(service: service)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ルームを作成'));
    await tester.tap(find.text('ルームを作成'));
    await tester.pumpAndSettle();
    expect(calls, ['getProfile']);
    expect(find.text('公開設定を再読込してから操作してください'), findsOneWidget);
    expect(find.text('公開設定を再読込'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
  testWidgets('public rank uses published time separately from private best', (
    tester,
  ) async {
    final service = CampusGameService(
      transport: (action, payload) async {
        if (action == 'getProfile') {
          return {'nickname': 'ChosenNickname', 'consent': true};
        }
        if (action == 'courses') {
          return {
            'courses': [
              {'direction': 'outward', 'courseKey': 'course-v1'},
            ],
          };
        }
        return {
          'courseKey': 'course-v1',
          'own': {
            'elapsedMs': 9000,
            'publicElapsedMs': 10000,
            'rank': 70,
            'optedIn': true,
          },
          'entries': [],
        };
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CampusGameOnlinePanel(service: service)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('この方向のランキングを表示'));
    await tester.tap(find.text('この方向のランキングを表示'));
    await tester.pumpAndSettle();
    expect(find.text('自分のベスト（個人記録）: 9.00 秒'), findsOneWidget);
    expect(find.text('公開記録: 10.00 秒 ・ 70位'), findsOneWidget);
    expect(find.textContaining('9.00 秒 ・ 70位'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });

  testWidgets('missing MyPage name never falls back to account identity', (
    tester,
  ) async {
    final calls = <String>[];
    final service = CampusGameService(
      transport: (action, payload) async {
        calls.add(action);
        return {
          'nickname': null,
          'consent': false,
          'email': 'private@example.test',
          'displayName': 'Real Account Name',
        };
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CampusGameOnlinePanel(service: service)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('マイページで表示名（ニックネーム）を設定してから参加してください。'), findsOneWidget);
    expect(find.textContaining('private@example.test'), findsNothing);
    expect(find.textContaining('Real Account Name'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    await tester.ensureVisible(find.text('ルームを作成'));
    await tester.tap(find.text('ルームを作成'));
    await tester.pumpAndSettle();
    expect(calls, ['getProfile']);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
  testWidgets(
    'MyPage name changes are reread without independent name writes',
    (tester) async {
      var canonical = 'FirstName';
      final calls = <String>[];
      final service = CampusGameService(
        transport: (action, payload) async {
          calls.add(action);
          return {'nickname': canonical, 'consent': true};
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CampusGameOnlinePanel(service: service)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('マイページのニックネーム: FirstName'), findsOneWidget);
      canonical = 'UpdatedName';
      await tester.ensureVisible(find.text('マイページのニックネームを再読込'));
      await tester.tap(find.text('マイページのニックネームを再読込'));
      await tester.pumpAndSettle();
      expect(find.text('マイページのニックネーム: UpdatedName'), findsOneWidget);
      expect(find.textContaining('FirstName'), findsNothing);
      expect(calls, ['getProfile', 'getProfile']);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, true);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    },
  );
}
