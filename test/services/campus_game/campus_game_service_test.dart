import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cit_app/services/campus_game/campus_game_service.dart';
import 'package:cit_app/screens/classroom_map/campus_game_online_panel.dart';

void main() {
  test(
    'bridge recovery preserves server correction and active challenge',
    () async {
      final calls = <String>[];
      final correction = {
        'challengeId': 'active',
        'position': {'x': 12, 'z': 34},
        'penaltyMs': 3000,
      };
      final service = CampusGameService(
        transport: (action, payload) async {
          calls.add(action);
          if (action == 'challenge') return {'challengeId': 'active'};
          expect(action, 'recover');
          expect(payload, {'challengeId': 'active'});
          return correction;
        },
      );
      await service.call('challenge', {'direction': 'neon_city'});
      final response = await service.handle({
        'type': 'campus-game',
        'requestId': 'recover-one',
        'action': 'recover',
        'payload': {'challengeId': 'active'},
      });
      expect(response['ok'], true);
      expect(response['requestId'], 'recover-one');
      expect(response['action'], 'recover');
      final data = response['data'] as Map;
      for (final key in correction.keys) {
        expect(data[key], correction[key]);
      }
      expect(data['rtt'], isA<int>());
      expect(service.challengeId, 'active');
      expect(calls, ['challenge', 'recover']);
      service.dispose();
    },
  );
  test(
    'missing authentication is explicit and does not contact server',
    () async {
      final service = CampusGameService(tokenProvider: () async => null);
      final response = await service.handle({
        'requestId': 'one',
        'action': 'challenge',
        'payload': {'direction': 'outward'},
      });
      expect(response['ok'], false);
      expect(response['requestId'], 'one');
      expect(response['error'], 'オンライン機能にはログインが必要です');
      service.dispose();
    },
  );
  test('bridge preserves trace and rejects unsupported actions', () async {
    Map<String, dynamic>? received;
    final service = CampusGameService(
      transport: (action, payload) async {
        received = payload;
        return {'verified': true};
      },
    );
    final samples = [
      {'t': 1000, 'x': 1, 'z': 2},
    ];
    final response = await service.handle({
      'requestId': 7,
      'action': 'trace',
      'payload': {'challengeId': 'opaque', 'samples': samples, 'finish': true},
    });
    expect(response['ok'], true);
    expect(received, {
      'challengeId': 'opaque',
      'samples': samples,
      'finish': true,
    });
    expect((await service.handle({'action': 'writeScore'}))['ok'], false);
    service.dispose();
  });
  test('public profile requires explicit consent', () async {
    var calls = 0;
    final service = CampusGameService(
      transport: (a, p) async {
        calls++;
        return {};
      },
    );
    await expectLater(
      service.call('profile', {'displayName': 'Account Name'}),
      throwsA(isA<CampusGameException>()),
    );
    expect(calls, 0);
    service.dispose();
  });
  testWidgets(
    'canonical MyPage nickname is read-only and failures are explicit',
    (tester) async {
      final calls = <String>[];
      final service = CampusGameService(
        transport: (a, p) async {
          calls.add(a);
          if (a == 'getProfile') {
            return {'nickname': 'BusFan', 'consent': false};
          }
          if (a == 'profile') {
            expect(p, {'consent': true});
            return {'nickname': 'BusFan', 'consent': true};
          }
          throw const CampusGameException('オンライン機能はサーバー反映待ち');
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CampusGameOnlinePanel(service: service)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('マイページのニックネーム: BusFan'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(find.text('ルームを作成'));
      await tester.tap(find.text('ルームを作成'));
      await tester.pumpAndSettle();
      expect(calls, ['getProfile', 'profile', 'createRoom']);
      expect(find.text('オンライン機能はサーバー反映待ち'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    },
  );
}
