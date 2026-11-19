import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef GameTransport =
    Future<Map<String, dynamic>> Function(
      String action,
      Map<String, dynamic> payload,
    );

class CampusGameException implements Exception {
  const CampusGameException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Authenticated callable boundary: credentials never enter the viewer.
class CampusGameService extends ChangeNotifier {
  CampusGameService({
    GameTransport? transport,
    Future<String?> Function()? tokenProvider,
    http.Client? client,
    Duration requestTimeout = const Duration(seconds: 12),
  }) : _transport = transport,
       _tokenProvider = tokenProvider,
       _client = client ?? http.Client(),
       _requestTimeout = requestTimeout;
  final GameTransport? _transport;
  final Future<String?> Function()? _tokenProvider;
  final http.Client _client;
  final Duration _requestTimeout;
  static final Uri endpoint = Uri.parse(
    'https://us-central1-cit-app-2de1c.cloudfunctions.net/campusGame',
  );
  static const actions = {
    'courses',
    'best',
    'cancelChallenge',
    'profile',
    'getProfile',
    'standings',
    'challenge',
    'trace',
    'recover',
    'createRoom',
    'joinRoom',
    'room',
    'readyRoom',
    'startRoom',
    'leaveRoom',
  };
  static const roomActions = {
    'createRoom',
    'joinRoom',
    'room',
    'readyRoom',
    'startRoom',
  };
  Timer? _timer;
  final Set<Future<void>> _cleanups = {};
  bool _polling = false, _disposed = false;
  int _generation = 0;
  Map<String, dynamic>? room;
  String? challengeId;
  String? error;
  void Function(Map<String, dynamic>)? onEvent;

  Future<Map<String, dynamic>> _request(
    String action,
    Map<String, dynamic> payload,
  ) async {
    try {
      if (_transport != null) {
        return await _transport(action, payload).timeout(_requestTimeout);
      }
      final token = await (_tokenProvider != null
              ? _tokenProvider()
              : Firebase.apps.isEmpty
              ? Future<String?>.value(null)
              : FirebaseAuth.instance.currentUser?.getIdToken() ??
                  Future<String?>.value(null))
          .timeout(_requestTimeout);
      if (token == null) throw const CampusGameException('オンライン機能にはログインが必要です');
      final response = await _client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'data': {...payload, 'action': action},
            }),
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 404 || response.statusCode == 503) {
        throw const CampusGameException('オンライン機能はサーバー反映待ち');
      }
      if (response.statusCode == 401) {
        throw const CampusGameException('ログイン状態を確認して再接続してください');
      }
      if (response.statusCode == 403) {
        throw const CampusGameException('オンライン機能へのアクセスが許可されていません');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const CampusGameException('サーバーの応答を確認できません');
      if (decoded['error'] != null) {
        final failure = decoded['error'];
        throw CampusGameException(
          failure is Map
              ? failure['message']?.toString() ?? 'オンライン処理に失敗しました'
              : 'オンライン処理に失敗しました',
        );
      }
      if (response.statusCode != 200) {
        throw const CampusGameException('オンライン処理に失敗しました');
      }
      final data = decoded['result'] ?? decoded['data'];
      if (data is! Map) throw const CampusGameException('サーバーの応答を確認できません');
      return Map<String, dynamic>.from(data);
    } on CampusGameException {
      rethrow;
    } on TimeoutException {
      throw const CampusGameException('通信がタイムアウトしました。再接続してください');
    } on FirebaseException {
      throw const CampusGameException('ログイン状態を確認して再接続してください');
    } catch (_) {
      throw const CampusGameException('通信できません。接続を確認してください');
    }
  }

  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> payload = const {},
  ]) async {
    if (!actions.contains(action)) throw const CampusGameException('未対応の操作です');
    if (_disposed) throw const CampusGameException('画面を開き直してください');
    if (action == 'profile') {
      if (payload['consent'] is! bool) {
        throw const CampusGameException('ランキングの公開設定を選択してください');
      }
      payload = {'consent': payload['consent']};
    }
    final generation = _generation;
    final roundTrip = Stopwatch()..start();
    final response = await _request(action, payload);
    roundTrip.stop();
    final data = {...response, 'rtt': roundTrip.elapsedMilliseconds};
    if (action == 'challenge') {
      if (generation == _generation && !_disposed) {
        challengeId = data['challengeId']?.toString();
      } else {
        final id = data['challengeId'];
        if (id != null) {
          _scheduleCleanup('cancelChallenge', {'challengeId': id});
        }
        throw const CampusGameException('画面が切り替わりました。再度開始してください');
      }
    }
    if (action == 'trace' &&
        payload['finish'] == true &&
        payload['challengeId'] == challengeId) {
      challengeId = null;
    }
    if (action == 'cancelChallenge' && payload['challengeId'] == challengeId) {
      challengeId = null;
    }
    return data;
  }

  /// Includes lifecycle checks for panel and viewer requests alike.
  Future<Map<String, dynamic>> updateRoom(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final generation = _generation;
    final data = await call(action, payload);
    if (generation != _generation || _disposed) {
      if (action == 'createRoom' || action == 'joinRoom') {
        final id = data['roomId'];
        if (id != null) _scheduleCleanup('leaveRoom', {'roomId': id});
      }
      throw const CampusGameException('画面が切り替わりました。再度参加してください');
    }
    watchRoom(data);
    return data;
  }

  Future<Map<String, dynamic>> handle(Map<String, dynamic> request) async {
    final action = request['action']?.toString() ?? '';
    try {
      final value = request['payload'];
      final payload =
          value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
      final data =
          roomActions.contains(action)
              ? await updateRoom(action, payload)
              : await call(action, payload);
      if (action == 'leaveRoom' && payload['roomId'] == room?['roomId']) {
        stopWatching();
      }
      return {
        'type': 'campus-game-response',
        'requestId': request['requestId'],
        'action': action,
        'ok': true,
        'data': data,
      };
    } catch (e) {
      return {
        'type': 'campus-game-response',
        'requestId': request['requestId'],
        'action': action,
        'ok': false,
        'error': e is CampusGameException ? e.message : 'オンライン処理に失敗しました',
      };
    }
  }

  void watchRoom(Map<String, dynamic> value) {
    if (_disposed) return;
    room = value;
    error = null;
    onEvent?.call({
      'type': 'campus-game-session',
      'data': value,
      'rtt': value['rtt'],
    });
    notifyListeners();
    _timer ??= Timer.periodic(const Duration(seconds: 2), (_) => reconnect());
  }

  Future<void> reconnect() async {
    final id = room?['roomId'];
    if (_polling || id == null || _disposed) return;
    final generation = _generation;
    _polling = true;
    try {
      await updateRoom('room', {'roomId': id});
    } catch (e) {
      if (!_disposed && generation == _generation) {
        error = e.toString();
        notifyListeners();
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> leave() async {
    final id = room?['roomId'];
    // Stop polling immediately even when the server cannot be reached.
    stopWatching();
    if (id != null) await call('leaveRoom', {'roomId': id});
  }

  void _scheduleCleanup(String action, Map<String, dynamic> payload) {
    final future = _cleanup(action, payload);
    _cleanups.add(future);
    unawaited(future.whenComplete(() => _cleanups.remove(future)));
  }

  Future<void> _cleanup(String action, Map<String, dynamic> payload) async {
    try {
      await _request(action, payload);
    } catch (_) {
      /* server expires abandoned sessions */
    }
  }

  /// Navigation detaches immediately; cleanup must not stop a replacement room.
  void detach() {
    final id = room?['roomId'];
    final challenge = challengeId;
    challengeId = null;
    stopWatching();
    if (id != null) _scheduleCleanup('leaveRoom', {'roomId': id});
    if (challenge != null) {
      _scheduleCleanup('cancelChallenge', {'challengeId': challenge});
    }
  }

  void stopWatching() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    room = null;
    if (!_disposed) {
      onEvent?.call({'type': 'campus-game-session', 'data': null});
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Best-effort cleanup survives closing the view. HTTP is closed after the
    // finite timeout instead of cancelling an in-flight leave immediately.
    detach();
    _disposed = true;
    _timer?.cancel();
    if (_cleanups.isEmpty) {
      _client.close();
    } else {
      unawaited(Future.wait(_cleanups).whenComplete(_client.close));
    }
    super.dispose();
  }
}
