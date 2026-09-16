import 'dart:async';
import 'dart:convert';

/// Only identifiers and routing metadata are carried in local notification data.
class NotificationTarget {
  const NotificationTarget(this.data);
  final Map<String, String> data;
  static const _keys = [
    'notificationId',
    'type',
    'source',
    'userId',
    'postId',
    'commentId',
    'replyId',
    'fromUserId',
    'fromCwitterId',
    'globalNotificationId',
  ];

  factory NotificationTarget.fromData(Map<String, dynamic> input) {
    return NotificationTarget({
      for (final key in _keys)
        if (input[key] is String && (input[key] as String).isNotEmpty)
          key: input[key] as String,
    });
  }

  String? get postId => _documentId(data['postId']);
  String? get commentId => _documentId(data['commentId']);
  String? get notificationId => _documentId(data['notificationId']);
  String? get fromUserId => _documentId(data['fromUserId']);
  String get source => data['source'] ?? '';
  bool belongsTo(String userId) =>
      data['userId'] == null || data['userId'] == userId;
  String encode() => jsonEncode({'kind': 'cit_push', 'data': data});

  static NotificationTarget? tryParse(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is! Map || json['kind'] != 'cit_push' || json['data'] is! Map) {
        return null;
      }
      return NotificationTarget.fromData(
        Map<String, dynamic>.from(json['data'] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  static String? _documentId(String? value) =>
      value == null ||
              value.isEmpty ||
              value.contains('/') ||
              value == '.' ||
              value == '..'
          ? null
          : value;
}

/// Holds a cold-start tap until an authenticated screen is ready.
class NotificationTapQueue {
  final _changes = StreamController<void>.broadcast(sync: true);
  NotificationTarget? _pending;
  Stream<void> get changes => _changes.stream;
  void add(NotificationTarget target) {
    _pending = target;
    _changes.add(null);
  }

  NotificationTarget? consume(String userId) {
    final target = _pending;
    _pending = null;
    return target != null && target.belongsTo(userId) ? target : null;
  }

  void clear() => _pending = null;
  Future<void> dispose() => _changes.close();
}
