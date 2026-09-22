import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bus/bus_model.dart';
import '../../services/bus/bus_service.dart';

/// 学バス情報プロバイダー
final busServiceProvider = Provider<BusService>((ref) => BusService());

/// 学バス情報取得プロバイダー
final busInformationProvider = FutureProvider<BusInformation?>((ref) async {
  final busService = ref.read(busServiceProvider);
  return await busService.getBusInformation();
});

/// 学バス情報リアルタイム監視プロバイダー
final busInformationStreamProvider = StreamProvider<BusInformation?>((ref) {
  print('🚌 StreamProvider: 学バス情報監視開始 - ${DateTime.now()}');
  final busService = ref.read(busServiceProvider);
  final stream = busService.watchBusInformation();
  print('🚌 StreamProvider: watchBusInformation()取得完了');
  return stream;
});

/// 現在運行中かどうかを判定するプロバイダー
final isCurrentlyOperatingProvider = Provider<bool>((ref) {
  final busInfo = ref.watch(busInformationStreamProvider);
  return busInfo.when(
    data: (data) => data?.isCurrentlyOperating ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// 現在の運行期間プロバイダー
final currentOperationPeriodProvider = Provider<BusOperationPeriod?>((ref) {
  final busInfo = ref.watch(busInformationStreamProvider);
  return busInfo.when(
    data: (data) => data?.currentOperationPeriod,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// アクティブなバス路線プロバイダー
final activeRoutesProvider = Provider<List<BusRoute>>((ref) {
  final busInfo = ref.watch(busInformationStreamProvider);
  return busInfo.when(
    data: (data) => data?.operatingRoutes ?? [],
    loading: () => [],
    error: (_, __) => [],
  );
});

/// 次のバス時刻取得プロバイダー
final nextBusTimesProvider = Provider<Map<String, BusTimeEntry?>>((ref) {
  final routes = ref.watch(activeRoutesProvider);
  final nextTimes = <String, BusTimeEntry?>{};

  for (final route in routes) {
    nextTimes[route.id] = route.getNextBusTime();
  }

  return nextTimes;
});

/// 管理者用: 学バス情報更新プロバイダー
final busInformationNotifierProvider =
    StateNotifierProvider<BusInformationNotifier, AsyncValue<BusInformation?>>((
      ref,
    ) {
      final busService = ref.read(busServiceProvider);
      return BusInformationNotifier(busService);
    });

/// 学バス情報管理用Notifier
class BusInformationNotifier
    extends StateNotifier<AsyncValue<BusInformation?>> {
  BusInformationNotifier(this._busService) : super(const AsyncValue.loading()) {
    _loadBusInformation();
  }

  final BusService _busService;

  /// 学バス情報を読み込み
  Future<void> _loadBusInformation() async {
    try {
      final busInfo = await _busService.getBusInformation();
      state = AsyncValue.data(busInfo);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 学バス情報を更新
  Future<bool> updateBusInformation(BusInformation busInfo) async {
    try {
      final success = await _busService.saveBusInformation(busInfo);
      if (success) {
        state = AsyncValue.data(busInfo);
        print('✅ 学バス情報を更新しました');
      }
      return success;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// 運行期間を追加
  Future<String?> addOperationPeriod(BusOperationPeriod period) async {
    try {
      final periodId = await _busService.addOperationPeriod(period);
      if (periodId != null) {
        await _loadBusInformation(); // データを再読み込み
      }
      return periodId;
    } catch (e) {
      print('❌ 運行期間追加エラー: $e');
      return null;
    }
  }

  /// 運行期間を更新
  Future<bool> updateOperationPeriod(BusOperationPeriod period) async {
    try {
      final success = await _busService.updateOperationPeriod(period);
      if (success) {
        await _loadBusInformation(); // データを再読み込み
      }
      return success;
    } catch (e) {
      print('❌ 運行期間更新エラー: $e');
      return false;
    }
  }

  /// 運行期間を削除
  Future<bool> deleteOperationPeriod(String periodId) async {
    try {
      final success = await _busService.deleteOperationPeriod(periodId);
      if (success) {
        await _loadBusInformation(); // データを再読み込み
      }
      return success;
    } catch (e) {
      print('❌ 運行期間削除エラー: $e');
      return false;
    }
  }

  /// バス路線を追加
  Future<String?> addBusRoute(BusRoute route) async {
    try {
      final routeId = await _busService.addBusRoute(route);
      if (routeId != null) {
        await _loadBusInformation(); // データを再読み込み
      }
      return routeId;
    } catch (e) {
      print('❌ バス路線追加エラー: $e');
      return null;
    }
  }

  /// バス路線を更新
  Future<bool> updateBusRoute(BusRoute route) async {
    try {
      final success = await _busService.updateBusRoute(route);
      if (success) {
        await _loadBusInformation(); // データを再読み込み
      }
      return success;
    } catch (e) {
      print('❌ バス路線更新エラー: $e');
      return false;
    }
  }

  /// バス路線を削除
  Future<bool> deleteBusRoute(String routeId) async {
    try {
      final success = await _busService.deleteBusRoute(routeId);
      if (success) {
        await _loadBusInformation(); // データを再読み込み
      }
      return success;
    } catch (e) {
      print('❌ バス路線削除エラー: $e');
      return false;
    }
  }

  /// データをリフレッシュ
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadBusInformation();
  }

  /// 初期データを作成
  Future<bool> createInitialData() async {
    try {
      final success = await _busService.createInitialBusData();
      if (success) {
        await _loadBusInformation();
      }
      return success;
    } catch (e) {
      print('❌ 初期データ作成エラー: $e');
      return false;
    }
  }
}
