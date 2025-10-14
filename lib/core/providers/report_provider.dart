import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/reports/report_model.dart';
import '../../services/reports/report_service.dart';

// 通報送信状態を管理するStateNotifier
class ReportSubmitNotifier extends StateNotifier<AsyncValue<void>> {
  ReportSubmitNotifier() : super(const AsyncValue.data(null));

  /// 通報を送信
  Future<void> submitReport({
    required ReportType type,
    required String targetId,
    required ReportReason reason,
    String? detail,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ReportService.submitReport(
        type: type,
        targetId: targetId,
        reason: reason,
        detail: detail,
      );
    });
  }

  /// 状態をリセット
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// 通報送信プロバイダー
final reportSubmitProvider = StateNotifierProvider<ReportSubmitNotifier, AsyncValue<void>>((ref) {
  return ReportSubmitNotifier();
});

// ステータス別通報一覧プロバイダー（Stream）
final reportsByStatusProvider = StreamProvider.family<List<Report>, ReportStatus?>((ref, status) {
  return ReportService.watchReportsByStatus(status);
});

// 全通報一覧プロバイダー（Stream）
final allReportsProvider = StreamProvider<List<Report>>((ref) {
  return ReportService.watchReportsByStatus(null);
});

// 未対応通報一覧プロバイダー（Stream）
final pendingReportsProvider = StreamProvider<List<Report>>((ref) {
  return ReportService.watchReportsByStatus(ReportStatus.pending);
});

// 確認中通報一覧プロバイダー（Stream）
final reviewingReportsProvider = StreamProvider<List<Report>>((ref) {
  return ReportService.watchReportsByStatus(ReportStatus.reviewing);
});

// 対応済み通報一覧プロバイダー（Stream）
final resolvedReportsProvider = StreamProvider<List<Report>>((ref) {
  return ReportService.watchReportsByStatus(ReportStatus.resolved);
});

// 通報統計プロバイダー
final reportStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await ReportService.getReportStatistics();
});

// 通報済みチェックプロバイダー
final hasAlreadyReportedProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final targetId = params['targetId'] as String;
  final type = params['type'] as ReportType;

  return await ReportService.hasAlreadyReported(
    targetId: targetId,
    type: type,
  );
});

// 通報ステータス更新状態を管理するStateNotifier
class ReportStatusUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  ReportStatusUpdateNotifier() : super(const AsyncValue.data(null));

  /// 通報ステータスを更新
  Future<void> updateStatus({
    required String reportId,
    required ReportStatus status,
    String? resolutionNote,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ReportService.updateStatus(
        reportId: reportId,
        status: status,
        resolutionNote: resolutionNote,
      );
    });
  }

  /// 状態をリセット
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// 通報ステータス更新プロバイダー
final reportStatusUpdateProvider = StateNotifierProvider<ReportStatusUpdateNotifier, AsyncValue<void>>((ref) {
  return ReportStatusUpdateNotifier();
});
