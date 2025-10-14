import 'package:cloud_firestore/cloud_firestore.dart';

class BulletinPost {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  // サムネイル表示用のアライメント（-1.0〜1.0）。0,0 が中央。
  final double thumbAlignX;
  final double thumbAlignY;
  final String? externalUrl; // 外部リンク用フィールド追加
  final BulletinCategory category;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String authorId;
  final String authorName;
  final int viewCount;
  final bool isPinned;
  final bool isActive;
  final bool allowComments; // コメント許可フラグ
  final bool pinRequested; // ピン留め申請状態
  final DateTime? pinRequestedAt; // ピン留め申請日時
  final String approvalStatus; // 承認状態: pending, approved, rejected
  final DateTime? submittedAt; // 投稿申請日時
  final DateTime? approvedAt; // 承認日時
  final String? approvedBy; // 承認者のUID
  final bool isCoupon; // クーポン投稿かどうか
  final int? couponMaxUses; // ユーザーごとのクーポン最大使用回数
  final int couponUsedCount; // 全体のクーポン使用済み回数
  final Map<String, int>? couponUsedBy; // ユーザーごとの使用回数

  const BulletinPost({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.thumbAlignX = 0.0,
    this.thumbAlignY = 0.0,
    this.externalUrl,
    required this.category,
    required this.createdAt,
    required this.expiresAt,
    required this.authorId,
    required this.authorName,
    this.viewCount = 0,
    this.isPinned = false,
    this.isActive = true,
    this.allowComments = true, // デフォルトでコメント許可
    this.pinRequested = false, // デフォルトで申請なし
    this.pinRequestedAt,
    this.approvalStatus = 'pending', // デフォルトで承認待ち
    this.submittedAt,
    this.approvedAt,
    this.approvedBy,
    this.isCoupon = false,
    this.couponMaxUses,
    this.couponUsedCount = 0,
    this.couponUsedBy,
  });

  factory BulletinPost.fromJson(Map<String, dynamic> json) {
    try {
      return BulletinPost(
        id: json['id'] ?? '',
        title: json['title'] ?? '無題',
        description: json['description'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        thumbAlignX: (json['thumbAlignX'] as num?)?.toDouble() ?? 0.0,
        thumbAlignY: (json['thumbAlignY'] as num?)?.toDouble() ?? 0.0,
        externalUrl: json['externalUrl'] as String?, // 外部リンク
        category: json['category'] != null 
            ? BulletinCategory.fromJson(json['category'] as Map<String, dynamic>)
            : BulletinCategories.other, // デフォルトカテゴリ
        createdAt: _parseDateTime(json['createdAt']),
        expiresAt: json['expiresAt'] != null ? _parseDateTime(json['expiresAt']) : null,
        authorId: json['authorId'] ?? '',
        authorName: json['authorName'] ?? '匿名',
        viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
        isPinned: json['isPinned'] == true,
        isActive: json['isActive'] != false, // nullの場合はtrue
        allowComments: json['allowComments'] != false, // nullの場合はtrue（デフォルト許可）
        pinRequested: json['pinRequested'] == true, // ピン留め申請状態
        pinRequestedAt: json['pinRequestedAt'] != null ? _parseDateTime(json['pinRequestedAt']) : null, // ピン留め申請日時
        approvalStatus: json['approvalStatus'] ?? 'pending', // 承認状態
        submittedAt: json['submittedAt'] != null ? _parseDateTime(json['submittedAt']) : null, // 投稿申請日時
        approvedAt: json['approvedAt'] != null ? _parseDateTime(json['approvedAt']) : null, // 承認日時
        approvedBy: json['approvedBy'] as String?, // 承認者のUID
        isCoupon: json['isCoupon'] == true,
        couponMaxUses: json['couponMaxUses'] as int?,
        couponUsedCount: (json['couponUsedCount'] as num?)?.toInt() ?? 0,
        couponUsedBy: json['couponUsedBy'] != null ? 
            Map<String, int>.from(
              (json['couponUsedBy'] as Map).map((k, v) => 
                MapEntry(k as String, (v as num).toInt())
              )
            ) : null,
      );
    } catch (e) {
      print('BulletinPost.fromJson エラー: $e');
      print('問題のあるJSON: $json');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) {
      return DateTime.now();
    }
    
    // Firestore Timestamp型の場合
    if (dateTime is Timestamp) {
      return dateTime.toDate();
    }
    
    // DateTime型の場合
    if (dateTime is DateTime) {
      return dateTime;
    }
    
    // String型の場合
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        print('日付の解析に失敗: $dateTime, エラー: $e');
        return DateTime.now();
      }
    }
    
    // その他の場合は現在時刻を返す
    print('未対応の日付型: ${dateTime.runtimeType} - $dateTime');
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'thumbAlignX': thumbAlignX,
      'thumbAlignY': thumbAlignY,
      'externalUrl': externalUrl, // 外部リンクを追加
      'category': category.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'authorId': authorId,
      'authorName': authorName,
      'viewCount': viewCount,
      'isPinned': isPinned,
      'isActive': isActive,
      'allowComments': allowComments, // コメント許可フラグを追加
      'pinRequested': pinRequested, // ピン留め申請状態
      'pinRequestedAt': pinRequestedAt != null ? Timestamp.fromDate(pinRequestedAt!) : null, // ピン留め申請日時
      'approvalStatus': approvalStatus, // 承認状態
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null, // 投稿申請日時
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null, // 承認日時
      'approvedBy': approvedBy, // 承認者のUID
      'isCoupon': isCoupon,
      'couponMaxUses': couponMaxUses,
      'couponUsedCount': couponUsedCount,
      'couponUsedBy': couponUsedBy,
    };
  }
}

class BulletinCategory {
  final String id;
  final String name;
  final String color;
  final String icon;

  const BulletinCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  factory BulletinCategory.fromJson(Map<String, dynamic> json) {
    return BulletinCategory(
      id: json['id'] ?? 'unknown',
      name: json['name'] ?? '不明',
      color: json['color'] ?? '#607D8B',
      icon: json['icon'] ?? 'more_horiz',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
    };
  }
}

// 事前定義カテゴリ
class BulletinCategories {
  static const event = BulletinCategory(
    id: 'event',
    name: 'イベント',
    color: '#2196F3',
    icon: 'event',
  );

  static const club = BulletinCategory(
    id: 'club',
    name: 'サークル・部活',
    color: '#FF9800',
    icon: 'group',
  );

  static const announcement = BulletinCategory(
    id: 'announcement',
    name: 'お知らせ',
    color: '#F44336',
    icon: 'announcement',
  );

  static const job = BulletinCategory(
    id: 'job',
    name: '求人・就職',
    color: '#9C27B0',
    icon: 'work',
  );

  static const coupon = BulletinCategory(
    id: 'coupon',
    name: 'クーポン',
    color: '#E91E63',
    icon: 'local_offer',
  );

  static const other = BulletinCategory(
    id: 'other',
    name: 'その他',
    color: '#607D8B',
    icon: 'more_horiz',
  );

  static const List<BulletinCategory> all = [
    event,
    club,
    announcement,
    job,
    coupon,
    other,
  ];

  static BulletinCategory? findById(String id) {
    try {
      return all.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
