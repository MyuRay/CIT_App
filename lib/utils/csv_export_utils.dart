import 'package:flutter/services.dart';
import '../models/admin/user_growth_stats_model.dart';

/// CSVエクスポート用のユーティリティ
class CsvExportUtils {
  /// CSV形式の文字列を安全にする（カンマや改行をエスケープ）
  static String csvSafe(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// ユーザー数推移データを日次CSV形式に変換
  static String exportDailyStatsToCsv(UserGrowthStats stats) {
    final rows = <String>[];
    
    // ヘッダー
    rows.add('日付,新規登録数,累積ユーザー数');
    
    // データ行
    for (final daily in stats.daily) {
      rows.add([
        csvSafe(daily.date),
        daily.count.toString(),
        daily.cumulative.toString(),
      ].join(','));
    }
    
    return rows.join('\n');
  }

  /// ユーザー数推移データを月次CSV形式に変換
  static String exportMonthlyStatsToCsv(UserGrowthStats stats) {
    final rows = <String>[];
    
    // ヘッダー
    rows.add('年月,新規登録数,累積ユーザー数');
    
    // データ行
    for (final monthly in stats.monthly) {
      rows.add([
        csvSafe(monthly.month),
        monthly.count.toString(),
        monthly.cumulative.toString(),
      ].join(','));
    }
    
    return rows.join('\n');
  }

  /// ユーザー数推移データを統合CSV形式に変換（日次と月次を含む）
  static String exportAllStatsToCsv(UserGrowthStats stats) {
    final rows = <String>[];
    
    // メタ情報
    rows.add('# ユーザー数推移統計データ');
    rows.add('# 生成日時,${stats.generatedAt.toIso8601String()}');
    rows.add('# 総ユーザー数,${stats.totalUsers}');
    rows.add('');
    
    // 月次データ
    rows.add('# 月次データ');
    rows.add('年月,新規登録数,累積ユーザー数');
    for (final monthly in stats.monthly) {
      rows.add([
        csvSafe(monthly.month),
        monthly.count.toString(),
        monthly.cumulative.toString(),
      ].join(','));
    }
    
    rows.add('');
    
    // 日次データ
    rows.add('# 日次データ');
    rows.add('日付,新規登録数,累積ユーザー数');
    for (final daily in stats.daily) {
      rows.add([
        csvSafe(daily.date),
        daily.count.toString(),
        daily.cumulative.toString(),
      ].join(','));
    }
    
    return rows.join('\n');
  }

  /// CSVデータをクリップボードにコピー
  static Future<void> copyToClipboard(String csvData) async {
    await Clipboard.setData(ClipboardData(text: csvData));
  }
}


