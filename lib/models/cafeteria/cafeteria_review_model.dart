import 'package:cloud_firestore/cloud_firestore.dart';

class CafeteriaReview {
  final String id;
  final String cafeteriaId; // 'tsudanuma' | 'narashino_1f' | 'narashino_2f'
  final String? menuName; // 任意のメニュー名/メモ
  final int taste; // 1-5
  final int volume; // 1-5
  final int recommend; // 1-5（おすすめ度）
  final String? volumeGender; // 'male' | 'female' | null
  final String? comment;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final int likeCount;
  final Map<String, dynamic>? likedBy;

  const CafeteriaReview({
    required this.id,
    required this.cafeteriaId,
    this.menuName,
    required this.taste,
    required this.volume,
    required this.recommend,
    this.volumeGender,
    this.comment,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.likeCount = 0,
    this.likedBy,
  });

  factory CafeteriaReview.fromJson(Map<String, dynamic> json) {
    return CafeteriaReview(
      id: json['id'] as String? ?? '',
      cafeteriaId: json['cafeteriaId'] as String? ?? 'tsudanuma',
      menuName: json['menuName'] as String?,
      taste: (json['taste'] as num?)?.toInt() ?? 0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
      recommend: (json['recommend'] as num?)?.toInt() ?? 0,
      volumeGender: json['volumeGender'] as String?,
      comment: json['comment'] as String?,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '匿名',
      createdAt: _parseDateTime(json['createdAt']),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: json['likedBy'] is Map
          ? Map<String, dynamic>.from(json['likedBy'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cafeteriaId': cafeteriaId,
      'menuName': menuName,
      'taste': taste,
      'volume': volume,
      'recommend': recommend,
      'volumeGender': volumeGender,
      'comment': comment,
      'userId': userId,
      'userName': userName,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'likedBy': likedBy,
    };
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      try { return DateTime.parse(v); } catch (_) {}
    }
    return DateTime.now();
  }
}

class Cafeterias {
  static const tsudanuma = 'tsudanuma';
  static const narashino1F = 'narashino_1f';
  static const narashino2F = 'narashino_2f';

  static const all = [tsudanuma, narashino1F, narashino2F];

  static String displayName(String id) {
    switch (id) {
      case tsudanuma:
        return '津田沼';
      case narashino1F:
        return '新習志野 1F';
      case narashino2F:
        return '新習志野 2F';
      default:
        return id;
    }
  }
}
