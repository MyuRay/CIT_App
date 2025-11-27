import 'package:flutter/material.dart';

class ConvenienceLink {
  final String id;
  final String title;
  final String url;
  final String iconName;
  final String color;
  final int order;
  final bool isEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ConvenienceLink({
    required this.id,
    required this.title,
    required this.url,
    required this.iconName,
    required this.color,
    this.order = 0,
    this.isEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  // copyWith メソッド
  ConvenienceLink copyWith({
    String? id,
    String? title,
    String? url,
    String? iconName,
    String? color,
    int? order,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConvenienceLink(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      order: order ?? this.order,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // JSON serialization
  factory ConvenienceLink.fromJson(Map<String, dynamic> json) {
    return ConvenienceLink(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      iconName: json['iconName'] as String,
      color: json['color'] as String,
      order: json['order'] as int? ?? 0,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'iconName': iconName,
      'color': color,
      'order': order,
      'isEnabled': isEnabled,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConvenienceLink &&
        other.id == id &&
        other.title == title &&
        other.url == url &&
        other.iconName == iconName &&
        other.color == color &&
        other.order == order &&
        other.isEnabled == isEnabled &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      url,
      iconName,
      color,
      order,
      isEnabled,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'ConvenienceLink(id: $id, title: $title, url: $url, iconName: $iconName, color: $color, order: $order, isEnabled: $isEnabled, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

// アイコン定数
class LinkIcons {
  static const Map<String, IconData> icons = {
    'web': Icons.language,
    'school': Icons.school,
    'book': Icons.book,
    'email': Icons.email,
    'phone': Icons.phone,
    'map': Icons.map,
    'calendar': Icons.calendar_today,
    'notes': Icons.notes,
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'train': Icons.train,
    'bus': Icons.directions_bus,
    'library': Icons.library_books,
    'assignment': Icons.assignment,
    'group': Icons.group,
    'chat': Icons.chat,
    'video_call': Icons.video_call,
    'document': Icons.description,
    'link': Icons.link,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'bookmark': Icons.bookmark,
    'info': Icons.info,
    'help': Icons.help,
    'settings': Icons.settings,
    'work': Icons.work,
  };

  static IconData getIcon(String iconName) {
    return icons[iconName] ?? Icons.link;
  }

  static List<MapEntry<String, IconData>> get iconList => icons.entries.toList();
}

// カラー定数
class LinkColors {
  static const Map<String, Color> colors = {
    'blue': Colors.blue,
    'green': Colors.green,
    'red': Colors.red,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
    'amber': Colors.amber,
    'lime': Colors.lime,
    'cyan': Colors.cyan,
    'brown': Colors.brown,
    'grey': Colors.grey,
    'deepOrange': Colors.deepOrange,
    'deepPurple': Colors.deepPurple,
  };

  static Color getColor(String colorName) {
    return colors[colorName] ?? Colors.blue;
  }

  static List<MapEntry<String, Color>> get colorList => colors.entries.toList();
}

// プリセットリンク
class PresetLinks {
  static List<ConvenienceLink> get defaultLinks => [
    ConvenienceLink(
      id: 'preset_official',
      title: '千葉工大公式HP',
      url: 'https://chibatech.jp/',
      iconName: 'web',
      color: 'orange',
      order: 1,
    ),
    ConvenienceLink(
      id: 'preset_library',
      title: '図書館',
      url: 'https://opac2.lib.it-chiba.ac.jp/',
      iconName: 'library_books',
      color: 'green',
      order: 2,
    ),
    ConvenienceLink(
      id: 'preset_manaba',
      title: 'manaba',
      url: 'https://cit.manaba.jp/ct/home',
      iconName: 'assignment',
      color: 'purple',
      order: 3,
    ),
    ConvenienceLink(
      id: 'preset_portal',
      title: 'CITポータル',
      url: 'https://portal.it-chiba.ac.jp/',
      iconName: 'school',
      color: 'blue',
      order: 4,
    ),
    ConvenienceLink(
      id: 'preset_certificate',
      title: '証明書発行',
      url: 'https://conveni.is.it-chiba.ac.jp/cert/z/z_login.html',
      iconName: 'document',
      color: 'teal',
      order: 5,
    ),
    ConvenienceLink(
      id: 'preset_student_portal',
      title: '学生資料室',
      url: 'https://kmsk.is.it-chiba.ac.jp/portal/?',
      iconName: 'info',
      color: 'indigo',
      order: 6,
    ),
    ConvenienceLink(
      id: 'preset_job_system',
      title: '就職システム',
      url: 'https://www2.kyujin-navi.com/GAKUGAI/MENU/menu.asp',
      iconName: 'work',
      color: 'deepOrange',
      order: 7,
    ),
    ConvenienceLink(
      id: 'preset_cjob',
      title: 'CJOB',
      url: 'https://cjob.tech/',
      iconName: 'star',
      color: 'amber',
      order: 8,
    ),
  ];
}