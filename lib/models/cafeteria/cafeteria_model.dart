class CafeteriaMenu {
  final String date;
  final String campus;
  final List<MenuItem> items;
  final DateTime fetchedAt;

  CafeteriaMenu({
    required this.date,
    required this.campus,
    required this.items,
    required this.fetchedAt,
  });

  factory CafeteriaMenu.fromMap(Map<String, dynamic> map) {
    return CafeteriaMenu(
      date: map['date'] ?? '',
      campus: map['campus'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((e) => MenuItem.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(map['fetchedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'campus': campus,
      'items': items.map((e) => e.toMap()).toList(),
      'fetchedAt': fetchedAt.millisecondsSinceEpoch,
    };
  }
}

class MenuItem {
  final String name;
  final String price;
  final String category; // 例: "定食", "丼物", "麺類"
  final String? description;
  final bool isAvailable;

  MenuItem({
    required this.name,
    required this.price,
    required this.category,
    this.description,
    this.isAvailable = true,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      category: map['category'] ?? '',
      description: map['description'],
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'description': description,
      'isAvailable': isAvailable,
    };
  }
}

class CafeteriaCongestion {
  final String campus;
  final String location;
  final CongestionLevel level;
  final DateTime timestamp;
  final String? cameraUrl;

  CafeteriaCongestion({
    required this.campus,
    required this.location,
    required this.level,
    required this.timestamp,
    this.cameraUrl,
  });

  factory CafeteriaCongestion.fromMap(Map<String, dynamic> map) {
    return CafeteriaCongestion(
      campus: map['campus'] ?? '',
      location: map['location'] ?? '',
      level: CongestionLevel.values[map['level'] ?? 0],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      cameraUrl: map['cameraUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campus': campus,
      'location': location,
      'level': level.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'cameraUrl': cameraUrl,
    };
  }
}

enum CongestionLevel {
  empty,    // 空いている
  low,      // やや空いている
  medium,   // 普通
  high,     // 混雑
  full,     // 満席
}

extension CongestionLevelExtension on CongestionLevel {
  String get displayName {
    switch (this) {
      case CongestionLevel.empty:
        return '空いています';
      case CongestionLevel.low:
        return 'やや空いています';
      case CongestionLevel.medium:
        return '普通';
      case CongestionLevel.high:
        return '混雑しています';
      case CongestionLevel.full:
        return '満席';
    }
  }

  String get emoji {
    switch (this) {
      case CongestionLevel.empty:
        return '😌';
      case CongestionLevel.low:
        return '🙂';
      case CongestionLevel.medium:
        return '😐';
      case CongestionLevel.high:
        return '😰';
      case CongestionLevel.full:
        return '😵';
    }
  }
}