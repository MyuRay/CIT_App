/// サークル・部活のモデル
class Circle {
  final int id;
  final String name;
  final String affiliation; // 体育会, 文化会
  final String positionCategory; // 部, 同好会, 愛好会, 自治会
  final List<String> tags;
  final int memberCount;
  final CircleSns? sns;
  final String? mail;
  final List<CircleEvent> events;

  const Circle({
    required this.id,
    required this.name,
    required this.affiliation,
    required this.positionCategory,
    required this.tags,
    required this.memberCount,
    this.sns,
    this.mail,
    this.events = const [],
  });

  /// 提供JSON形式（affiliation, category, snsX, snsInstagram）からパース
  factory Circle.fromJson(Map<String, dynamic> json, {required int id}) {
    final snsX = json['snsX'] as String?;
    final snsInsta = json['snsInstagram'] as String?;
    final x = snsX?.replaceFirst(RegExp(r'^@'), '');
    return Circle(
      id: id,
      name: json['name'] as String,
      affiliation: json['affiliation'] as String? ?? '文化会',
      positionCategory: _normalizeCategory(json['category'] as String?),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      memberCount: json['memberCount'] as int? ?? 0,
      sns: (x != null || snsInsta != null)
          ? CircleSns(x: x, instagram: snsInsta)
          : null,
      mail: json['mail'] as String?,
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => CircleEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static String _normalizeCategory(String? c) {
    if (c == null) return '部';
    if (c == '愛愛好会') return '愛好会';
    return c;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'affiliation': affiliation,
        'positionCategory': positionCategory,
        'tags': tags,
        'memberCount': memberCount,
        'sns': sns?.toJson(),
        'mail': mail,
        'events': events.map((e) => e.toJson()).toList(),
      };

  /// 人数規模のバッジ用ラベル
  String get memberCountLabel {
    if (memberCount >= 100) return '100人以上';
    if (memberCount >= 50) return '50人以上';
    if (memberCount <= 10) return '10人以下';
    if (memberCount <= 30) return '30人以下';
    return '$memberCount人';
  }

  /// 表示用: 所属・位置付け（例: 体育会 部）
  String get affiliationLabel => '$affiliation $positionCategory';
}

/// SNS情報
class CircleSns {
  final String? x; // X (Twitter) のユーザー名（@なし）
  final String? instagram;

  const CircleSns({this.x, this.instagram});

  factory CircleSns.fromJson(Map<String, dynamic> json) {
    final xRaw = json['x'] as String?;
    return CircleSns(
      x: xRaw?.replaceFirst(RegExp(r'^@'), ''),
      instagram: json['instagram'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'instagram': instagram,
      };

  String? get xUrl => (x?.isNotEmpty == true) ? 'https://x.com/$x' : null;
  String? get instagramUrl =>
      (instagram?.isNotEmpty == true)
          ? 'https://www.instagram.com/$instagram/'
          : null;
}

/// 体験会・新歓イベント
class CircleEvent {
  final String date; // YYYY-MM-DD
  final String time; // 例: 17:00-
  final String place;
  final String campus; // tsudanuma, narashino, shibazono

  const CircleEvent({
    required this.date,
    required this.time,
    required this.place,
    required this.campus,
  });

  factory CircleEvent.fromJson(Map<String, dynamic> json) {
    return CircleEvent(
      date: json['date'] as String,
      time: json['time'] as String? ?? '',
      place: json['place'] as String,
      campus: json['campus'] as String? ?? 'tsudanuma',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'time': time,
        'place': place,
        'campus': campus,
      };

  DateTime get dateTime {
    final parts = date.split('-');
    if (parts.length >= 3) {
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }
    return DateTime.now();
  }

  String get campusLabel {
    switch (campus) {
      case 'tsudanuma':
        return '津田沼';
      case 'narashino':
        return '新習志野';
      case 'shibazono':
        return '芝園';
      default:
        return campus;
    }
  }
}
