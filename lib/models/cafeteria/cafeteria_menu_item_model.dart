import 'package:cloud_firestore/cloud_firestore.dart';

class CafeteriaMenuItem {
  final String id;
  final String cafeteriaId; // 'tsudanuma' | 'narashino_1f' | 'narashino_2f'
  final String menuName;
  final int? price; // 円。未設定の場合は null
  final String? photoUrl;
  final DateTime createdAt;

  const CafeteriaMenuItem({
    required this.id,
    required this.cafeteriaId,
    required this.menuName,
    this.price,
    this.photoUrl,
    required this.createdAt,
  });

  factory CafeteriaMenuItem.fromJson(Map<String, dynamic> json) {
    return CafeteriaMenuItem(
      id: json['id'] as String? ?? '',
      cafeteriaId: json['cafeteriaId'] as String? ?? 'tsudanuma',
      menuName: json['menuName'] as String? ?? '',
      price: (json['price'] as num?)?.toInt(),
      photoUrl: json['photoUrl'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cafeteriaId': cafeteriaId,
      'menuName': menuName,
      'price': price,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
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

  CafeteriaMenuItem copyWith({
    String? id,
    String? cafeteriaId,
    String? menuName,
    int? price,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return CafeteriaMenuItem(
      id: id ?? this.id,
      cafeteriaId: cafeteriaId ?? this.cafeteriaId,
      menuName: menuName ?? this.menuName,
      price: price ?? this.price,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

