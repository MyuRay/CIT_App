import 'package:cloud_firestore/cloud_firestore.dart';

/// ちばちゃんねる スレッド一覧の並び替えキー
enum ChibaChannelThreadSortKey {
  lastActivity,
  createdAt,
  commentCount;

  String get displayName => switch (this) {
        ChibaChannelThreadSortKey.lastActivity => '最終レス順',
        ChibaChannelThreadSortKey.createdAt => '作成日順',
        ChibaChannelThreadSortKey.commentCount => 'レス数順',
      };
}

/// ちばちゃんねる スレッド
class ChibaChannelThread {
  const ChibaChannelThread({
    required this.id,
    required this.title,
    required this.category,
    required this.commentCount,
    required this.createdAt,
    required this.lastActivityAt,
    required this.authorId,
    this.authorEmail,
  });

  static const List<String> categories = [
    '雑談',
    '時事ニュース',
    'キャンパス',
    '勉強',
    '就活・バイト',
    'サークル',
    'イベント',
    'ゲーム・趣味',
    'エンタメ',
    '相談',
    '生活',
  ];

  static const Map<String, String> titlePlaceholders = {
    '雑談': '【雑談】今日の授業どうだった？',
    '時事ニュース': '【時事】〇〇のニュースについてどう思う？',
    'キャンパス': '新習志野キャンパス、自習室の空き状況',
    '勉強': 'プログラミングの課題で詰まってる人集合',
    '就活・バイト': 'おすすめのバイト先ある？',
    'サークル': '〇〇サークルに入ってる人いる？',
    'イベント': '学園祭の出し物、何が面白かった？',
    'ゲーム・趣味': '今ハマってるゲーム教えて',
    'エンタメ': '今期のアニメでおすすめある？',
    '相談': '単位が危なくて相談したい',
    '生活': '電車遅延してた人いる？',
  };

  static String titlePlaceholderFor(String category) {
    return titlePlaceholders[category] ?? 'スレッドのタイトルを入力';
  }

  /// 最終活動からこの期間レスがなければ格納庫へ
  static const Duration archiveInactivityDuration = Duration(days: 30);

  /// この期間以内にレスがあったスレをホット扱い
  static const Duration hotActivityWindow = Duration(hours: 24);

  final String id;
  final String title;
  final String category;
  final int commentCount;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final String authorId;
  final String? authorEmail;

  bool get isArchived =>
      DateTime.now().difference(lastActivityAt) >= archiveInactivityDuration;

  /// 24時間以内にレスがあり、かつ格納庫でないスレ
  bool get isHot =>
      !isArchived &&
      commentCount >= 1 &&
      DateTime.now().difference(lastActivityAt) < hotActivityWindow;

  String get activityLabel =>
      commentCount > 0 ? '最終レス' : '作成';

  factory ChibaChannelThread.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final createdAt = _parseDateTime(data['createdAt']) ?? DateTime.now();
    final lastActivityAt =
        _parseDateTime(data['lastActivityAt']) ?? createdAt;
    return ChibaChannelThread(
      id: doc.id,
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? '',
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt,
      authorId: data['authorId'] as String? ?? '',
      authorEmail: data['authorEmail'] as String?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
