import 'package:cit_app/core/utils/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
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
      SecureLogger.debug('📊 ユーザー数推移の取得を開始...');

      final url = Uri.parse('$_baseUrl/$_functionName');
      SecureLogger.debug('URL: $url');

      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return null;
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'})
          .timeout(_timeout);

      SecureLogger.debug('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final stats = UserGrowthStats.fromJson(jsonData);
        SecureLogger.debug('✅ ユーザー数推移の取得が完了しました');
        SecureLogger.debug('総ユーザー数: ${stats.totalUsers}');
        SecureLogger.debug('日次データ数: ${stats.daily.length}');
        SecureLogger.debug('月次データ数: ${stats.monthly.length}');
        return stats;
      } else {
        SecureLogger.debug('❌ ユーザー数推移の取得に失敗: ${response.statusCode}');
        SecureLogger.debug('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      SecureLogger.debug('❌ ユーザー数推移の取得エラー: $e');
      SecureLogger.debug('StackTrace: $stackTrace');
      return null;
    }
  }
}
