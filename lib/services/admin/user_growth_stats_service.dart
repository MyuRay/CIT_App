import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/admin/user_growth_stats_model.dart';

/// ユーザー数推移を取得するサービス
class UserGrowthStatsService {
  // Firebase FunctionsのURL
  // プロジェクトID: cit-app-2de1c
  // リージョン: us-central1 (デフォルト)
  static const String _baseUrl =
      'https://us-central1-cit-app-2de1c.cloudfunctions.net';
  static const String _functionName = 'getUserGrowthStats';
  static const Duration _timeout = Duration(seconds: 30);

  /// ユーザー数推移を取得
  static Future<UserGrowthStats?> getUserGrowthStats() async {
    try {
      debugPrint('📊 ユーザー数推移の取得を開始...');

      final url = Uri.parse('$_baseUrl/$_functionName');
      debugPrint('URL: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final stats = UserGrowthStats.fromJson(jsonData);
        debugPrint('✅ ユーザー数推移の取得が完了しました');
        debugPrint('総ユーザー数: ${stats.totalUsers}');
        debugPrint('日次データ数: ${stats.daily.length}');
        debugPrint('月次データ数: ${stats.monthly.length}');
        return stats;
      } else {
        debugPrint('❌ ユーザー数推移の取得に失敗: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ユーザー数推移の取得エラー: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }
}


