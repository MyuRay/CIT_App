import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../models/train/train_snapshot.dart';

/// Firestore を使わず、HTTP で最寄駅電車JSONを取得するクライアント。
///
/// [AppConstants.trainInfoApiBaseUrl] が空のときは取得せず `null` を返す。
///
/// 想定レスポンス: `application/json` のオブジェクト（設計書 v1 と同一形状）。
/// - `GET {baseUrl}?campus=tsudanuma` のように `campus` クエリを付与する。
///
/// **APIキーが必要な場合**は、必ず自前のサーバー（Cloud Functions / Cloud Run 等）を
/// プロキシとして置き、クライアントにはその HTTPS URL だけを設定すること。
class TrainApiClient {
  TrainApiClient({
    required this.client,
    String? baseUrl,
  }) : baseUrl = (baseUrl ?? AppConstants.trainInfoApiBaseUrl).trim();

  final http.Client client;
  final String baseUrl;

  static const Duration timeout = Duration(seconds: 12);

  /// ベースURL未設定時は常に null（DB・ネットワークを使わない）
  bool get isConfigured => baseUrl.isNotEmpty;

  Uri _uriForCampus(String campusKey) {
    final base = Uri.parse(baseUrl);
    final q = Map<String, String>.from(base.queryParameters);
    q['campus'] = campusKey;
    return base.replace(queryParameters: q);
  }

  Future<TrainSnapshot?> fetchSnapshot(String campusKey) async {
    if (!isConfigured) return null;
    final uri = _uriForCampus(campusKey);
    final res = await client.get(uri, headers: _headers).timeout(timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TrainApiException(
        'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    }
    final decoded = json.decode(utf8.decode(res.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const TrainApiException('JSON がオブジェクトではありません');
    }
    return TrainSnapshot.fromMap(campusKey, decoded);
  }

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'CIT_App/train_api',
  };

  void close() => client.close();
}

class TrainApiException implements Exception {
  const TrainApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'TrainApiException: $message';
}
