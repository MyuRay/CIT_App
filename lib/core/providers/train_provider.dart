import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/train/train_snapshot.dart';
import '../../services/train/train_api_client.dart';
import '../../services/train/train_departure_decision.dart';
import '../../services/train/train_mock_snapshot.dart';
import '../../services/train/train_static_snapshot.dart';
import 'settings_provider.dart';

final trainApiClientProvider = Provider<TrainApiClient>((ref) {
  final c = TrainApiClient(client: http.Client());
  ref.onDispose(c.close);
  return c;
});

/// ODPT 接続前はデバッグでモック、本番は URL 設定時のみ HTTP
final trainInfoUseMockProvider = Provider<bool>((ref) {
  return AppConstants.resolveTrainInfoUseMock(isDebugMode: kDebugMode);
});

/// モック・HTTP・津田沼の同梱静的時刻表のいずれかがあれば取得可能
final trainInfoAvailableProvider = Provider<bool>((ref) {
  if (ref.watch(trainInfoUseMockProvider)) return true;
  if (ref.watch(trainApiClientProvider).isConfigured) return true;
  return TrainStaticSnapshot.supportsTsudanuma;
});

/// 1秒ごとにカウントダウン表示を更新
final trainUiTickProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    yield DateTime.now();
  }
});

/// HTTP で定期取得（既定 60 秒）。Firestore は使わない。
final trainSnapshotStreamProvider =
    StreamProvider.autoDispose.family<TrainSnapshot?, String>((ref, campusKey) async* {
  final useMock = ref.watch(trainInfoUseMockProvider);
  if (useMock) {
    while (true) {
      yield TrainMockSnapshot.build(campusKey, DateTime.now());
      await Future.delayed(const Duration(seconds: 60));
    }
  }

  if (campusKey == 'tsudanuma') {
    await TrainStaticSnapshot.ensureLoaded();
  }

  final client = ref.watch(trainApiClientProvider);
  while (true) {
    final now = DateTime.now();
    TrainSnapshot? snap;

    if (client.isConfigured) {
      try {
        final remote = await client.fetchSnapshot(campusKey);
        if (remote != null) {
          snap = trainSnapshotWithValidDirections(remote);
          if (snap.directions.isEmpty) snap = null;
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('train API failed ($campusKey): $e\n$st');
        }
      }
    }

    snap ??= TrainStaticSnapshot.build(campusKey, now);
    yield snap;
    await Future.delayed(const Duration(seconds: 60));
  }
});

TrainDirectionSnapshot? pickTrainDirection({
  required TrainSnapshot snapshot,
  required String preferredDirectionKey,
}) {
  final valid = snapshot.directions
      .where(trainDirectionHasValidDeparture)
      .toList();
  if (valid.isEmpty) return null;
  if (preferredDirectionKey.isNotEmpty) {
    for (final d in valid) {
      if (d.directionKey == preferredDirectionKey) return d;
    }
  }
  return valid.first;
}

/// ホーム表示用: 優先キャンパス + スナップショット + 設定 + 現在時刻
final trainHomeDecisionProvider =
    Provider.autoDispose<AsyncValue<TrainHomeVm>>((ref) {
  ref.watch(trainUiTickProvider);
  final campus = ref.watch(preferredBusCampusProvider);
  final snapAsync = ref.watch(trainSnapshotStreamProvider(campus));
  final settings = ref.watch(settingsProvider);
  final prefKey = campus == 'narashino'
      ? settings.trainPreferredDirectionNarashino
      : settings.trainPreferredDirectionTsudanuma;

  return snapAsync.when(
    data: (snap) {
      if (snap == null) {
        return AsyncValue.data(
          TrainHomeVm(
            campusKey: campus,
            snapshot: null,
            direction: null,
            decision: TrainDepartureDecision.noData(),
            delay: null,
          ),
        );
      }
      final dir = pickTrainDirection(
        snapshot: snap,
        preferredDirectionKey: prefKey,
      );
      if (dir == null) {
        return AsyncValue.data(
          TrainHomeVm(
            campusKey: campus,
            snapshot: snap,
            direction: null,
            decision: TrainDepartureDecision.noData(),
            delay: snap.delay,
          ),
        );
      }
      final decision = computeTrainDepartureDecision(
        now: DateTime.now(),
        walkMinutesToStation: TrainHomeVm.walkMinutesToStation,
        nextDepartureAt: dir.nextDepartureAt,
        secondDepartureAt: dir.secondDepartureAt,
      );
      return AsyncValue.data(
        TrainHomeVm(
          campusKey: campus,
          snapshot: snap,
          direction: dir,
          decision: decision,
          delay: snap.delay,
        ),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

class TrainHomeVm {
  const TrainHomeVm({
    required this.campusKey,
    required this.snapshot,
    required this.direction,
    required this.decision,
    this.delay,
  });

  static const int walkMinutesToStation = 10;

  final String campusKey;
  final TrainSnapshot? snapshot;
  final TrainDirectionSnapshot? direction;
  final TrainDepartureDecision decision;
  final TrainDelayInfo? delay;

  String get campusDisplayName =>
      campusKey == 'narashino' ? '新習志野キャンパス' : '津田沼キャンパス';
}
