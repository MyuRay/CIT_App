import 'package:cloud_firestore/cloud_firestore.dart';

/// 学食のお気に入り（メニュー / 食堂）を表すモデル
class CafeteriaFavorite {
  final String id;
  final String userId;
  /// 'cafeteria' または 'menu'
  final String type;
  /// type == 'cafeteria' のときは Cafeterias.xxx
  final String? cafeteriaId;
  /// type == 'menu' のときに使用。`cafeteria_menu_items` のドキュメントID
  final String? menuItemId;
  /// type == 'menu' でメニューIDがまだ存在しないケース向けの補助情報
  final String? menuName;
  final DateTime createdAt;

  const CafeteriaFavorite({
    required this.id,
    required this.userId,
    required this.type,
    this.cafeteriaId,
    this.menuItemId,
    this.menuName,
    required this.createdAt,
  });

  factory CafeteriaFavorite.fromJson(Map<String, dynamic> json) {
    return CafeteriaFavorite(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? 'cafeteria',
      cafeteriaId: json['cafeteriaId'] as String?,
      menuItemId: json['menuItemId'] as String?,
      menuName: json['menuName'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'cafeteriaId': cafeteriaId,
      'menuItemId': menuItemId,
      'menuName': menuName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return DateTime.now();
  }
}

