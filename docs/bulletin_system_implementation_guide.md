# 掲示板システム実装完全ガイド

このドキュメントは、クーポン機能、リアルタイム更新、管理者権限を含む完全な掲示板システムの実装指示書です。

## 目次
1. [プロジェクト構造](#1-プロジェクト構造)
2. [Firebase設定](#2-firebase設定)
3. [データモデル](#3-データモデル)
4. [管理者権限システム](#4-管理者権限システム)
5. [サービス層](#5-サービス層)
6. [プロバイダー設定](#6-プロバイダー設定)
7. [画面実装](#7-画面実装)
8. [重要な実装ポイント](#8-重要な実装ポイント)

## 1. プロジェクト構造

```
lib/
├── models/
│   ├── bulletin/
│   │   └── bulletin_model.dart
│   ├── admin/
│   │   └── admin_model.dart
│   └── comment/
│       └── comment_model.dart
├── services/
│   └── bulletin/
│       └── bulletin_service.dart
├── core/
│   └── providers/
│       ├── admin_provider.dart
│       ├── auth_provider.dart
│       └── bulletin_provider.dart
└── screens/
    └── bulletin/
        ├── bulletin_post_form_screen.dart
        └── bulletin_post_detail_screen.dart
```

## 2. Firebase設定

### 2.1 必要なFirebaseサービス
- **Firebase Authentication**: ユーザー認証
- **Cloud Firestore**: データベース
- **Firebase Storage**: 画像ストレージ

### 2.2 Firestoreコレクション構造

#### `bulletin_posts` コレクション
```javascript
{
  "id": "自動生成ID",
  "title": "投稿タイトル",
  "description": "投稿内容",
  "imageUrl": "画像URL",
  "externalUrl": "外部リンク（任意）",
  "category": {
    "id": "event",
    "name": "イベント",
    "color": "#2196F3",
    "icon": "event"
  },
  "createdAt": "Timestamp",
  "expiresAt": "Timestamp（任意）",
  "authorId": "投稿者のUID",
  "authorName": "投稿者名",
  "viewCount": 0,
  "isPinned": false,
  "isActive": true,
  "allowComments": true,
  "isCoupon": false,
  "couponMaxUses": null,
  "couponUsedCount": 0,
  "couponUsedBy": {}
}
```

#### `admin_permissions` コレクション
```javascript
{
  "userId": "ユーザーUID",
  "isAdmin": true,
  "canManagePosts": true,
  "canViewContacts": true,
  "canManageUsers": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

## 3. データモデル

### 3.1 BulletinPost モデル (`lib/models/bulletin/bulletin_model.dart`)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BulletinPost {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? externalUrl;
  final BulletinCategory category;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String authorId;
  final String authorName;
  final int viewCount;
  final bool isPinned;
  final bool isActive;
  final bool allowComments;
  final bool isCoupon;
  final int? couponMaxUses;
  final int couponUsedCount;
  final Map<String, int>? couponUsedBy; // ユーザーごとの使用回数

  const BulletinPost({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.externalUrl,
    required this.category,
    required this.createdAt,
    required this.expiresAt,
    required this.authorId,
    required this.authorName,
    this.viewCount = 0,
    this.isPinned = false,
    this.isActive = true,
    this.allowComments = true,
    this.isCoupon = false,
    this.couponMaxUses,
    this.couponUsedCount = 0,
    this.couponUsedBy,
  });

  factory BulletinPost.fromJson(Map<String, dynamic> json) {
    return BulletinPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '無題',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      externalUrl: json['externalUrl'] as String?,
      category: json['category'] != null 
          ? BulletinCategory.fromJson(json['category'] as Map<String, dynamic>)
          : BulletinCategories.other,
      createdAt: _parseDateTime(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? _parseDateTime(json['expiresAt']) : null,
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '匿名',
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] == true,
      isActive: json['isActive'] != false,
      allowComments: json['allowComments'] != false,
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
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'externalUrl': externalUrl,
      'category': category.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'authorId': authorId,
      'authorName': authorName,
      'viewCount': viewCount,
      'isPinned': isPinned,
      'isActive': isActive,
      'allowComments': allowComments,
      'isCoupon': isCoupon,
      'couponMaxUses': couponMaxUses,
      'couponUsedCount': couponUsedCount,
      'couponUsedBy': couponUsedBy,
    };
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is Timestamp) return dateTime.toDate();
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
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
```

### 3.2 AdminPermissions モデル (`lib/models/admin/admin_model.dart`)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPermissions {
  final String userId;
  final bool isAdmin;
  final bool canManagePosts;
  final bool canViewContacts;
  final bool canManageUsers;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AdminPermissions({
    required this.userId,
    required this.isAdmin,
    required this.canManagePosts,
    required this.canViewContacts,
    required this.canManageUsers,
    required this.createdAt,
    this.updatedAt,
  });

  factory AdminPermissions.fromJson(Map<String, dynamic> json) {
    return AdminPermissions(
      userId: json['userId'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      canManagePosts: json['canManagePosts'] ?? false,
      canViewContacts: json['canViewContacts'] ?? false,
      canManageUsers: json['canManageUsers'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? _parseDateTime(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isAdmin': isAdmin,
      'canManagePosts': canManagePosts,
      'canViewContacts': canViewContacts,
      'canManageUsers': canManageUsers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is Timestamp) return dateTime.toDate();
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
```

## 4. 管理者権限システム

### 4.1 管理者プロバイダー (`lib/core/providers/admin_provider.dart`)

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/admin/admin_model.dart';
import 'auth_provider.dart';

// 管理者権限プロバイダー（特定ユーザーID用）
final adminPermissionsProvider = StreamProvider.family<AdminPermissions?, String>((ref, userId) {
  if (userId.isEmpty) {
    return Stream.value(null);
  }
  
  return FirebaseFirestore.instance
      .collection('admin_permissions')
      .doc(userId)
      .snapshots()
      .map((doc) {
    if (doc.exists) {
      final data = doc.data()!;
      final permissions = AdminPermissions.fromJson(data);
      return permissions;
    }
    return null;
  }).handleError((e) {
    return null;
  });
});

// 現在ユーザーの管理者権限プロバイダー
final currentUserAdminProvider = StreamProvider<AdminPermissions?>((ref) {
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) {
      return Stream.value(null);
    }
    
    return FirebaseFirestore.instance
        .collection('admin_permissions')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        try {
          final permissions = AdminPermissions.fromJson(data);
          return permissions;
        } catch (parseError) {
          return null;
        }
      }
      return null;
    }).handleError((e) {
      return null;
    });
  });
});

// 管理者かどうかの判定プロバイダー
final isAdminProvider = Provider<bool>((ref) {
  final adminPermissions = ref.watch(currentUserAdminProvider);
  return adminPermissions.when(
    data: (permissions) => permissions?.isAdmin ?? false,
    loading: () => false,
    error: (error, _) => false,
  );
});
```

## 5. サービス層

### 5.1 BulletinService (`lib/services/bulletin/bulletin_service.dart`)

```dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/bulletin/bulletin_model.dart';

class BulletinService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 掲示板投稿を作成
  static Future<void> createPost({
    required String title,
    required String description,
    File? imageFile,
    required BulletinCategory category,
    required String authorName,
    required String authorId,
    DateTime? expiresAt,
    bool isPinned = false,
    bool isCoupon = false,
    int? couponMaxUses,
    String? externalUrl,
    bool allowComments = true,
  }) async {
    try {
      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
      }

      final BulletinPost post = BulletinPost(
        id: '',
        title: title,
        description: description,
        imageUrl: imageUrl,
        externalUrl: externalUrl,
        category: category,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        authorId: authorId,
        authorName: authorName,
        viewCount: 0,
        isPinned: isPinned,
        isActive: true,
        allowComments: allowComments,
        isCoupon: isCoupon,
        couponMaxUses: couponMaxUses,
        couponUsedCount: 0,
        couponUsedBy: isCoupon ? <String, int>{} : null,
      );

      await _firestore.collection('bulletin_posts').add(post.toJson());
    } catch (e) {
      throw Exception('投稿の作成に失敗しました: $e');
    }
  }

  /// 画像をFirebase Storageにアップロード
  static Future<String> _uploadImage(File imageFile) async {
    try {
      final String userId = _getCurrentUserId();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference ref = _storage
          .ref()
          .child('bulletin_images')
          .child(userId)
          .child(fileName);
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('画像のアップロードに失敗しました: $e');
    }
  }

  /// 現在のユーザーIDを取得
  static String _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ユーザーが認証されていません');
    }
    return user.uid;
  }

  /// 投稿を取得（ピン留め優先ソート）
  static Future<List<BulletinPost>> getPosts({
    int limit = 20,
    String? categoryId,
    bool? isPinned,
  }) async {
    try {
      Query query = _firestore
          .collection('bulletin_posts')
          .where('isActive', isEqualTo: true);

      if (categoryId != null) {
        query = query.where('category.id', isEqualTo: categoryId);
      }

      if (isPinned != null) {
        query = query.where('isPinned', isEqualTo: isPinned);
      }

      final QuerySnapshot snapshot = await query.get();
      
      List<BulletinPost> posts = snapshot.docs
          .map((doc) => BulletinPost.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();

      // ピン留め投稿を優先してソート
      posts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return posts.take(limit).toList();
    } catch (e) {
      throw Exception('投稿の取得に失敗しました: $e');
    }
  }

  /// 投稿の閲覧数を増加
  static Future<void> incrementViewCount(String postId) async {
    try {
      await _firestore.collection('bulletin_posts').doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('閲覧数の更新に失敗: $e');
    }
  }

  /// クーポンを使用
  static Future<void> useCoupon(String postId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('bulletin_posts').doc(postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('投稿が見つかりません');
        }
        
        final post = BulletinPost.fromJson(postDoc.data()!);
        
        if (!post.isCoupon) {
          throw Exception('この投稿はクーポンではありません');
        }
        
        // ユーザーごとの使用回数上限チェック
        final usedBy = post.couponUsedBy ?? <String, int>{};
        final currentUserUsageCount = usedBy[userId] ?? 0;
        
        if (post.couponMaxUses != null && currentUserUsageCount >= post.couponMaxUses!) {
          throw Exception('あなたはこのクーポンの使用回数上限に達しています');
        }
        
        // 使用記録を更新
        final updatedUsedBy = Map<String, int>.from(usedBy);
        updatedUsedBy[userId] = currentUserUsageCount + 1;
        
        transaction.update(postRef, {
          'couponUsedCount': post.couponUsedCount + 1,
          'couponUsedBy': updatedUsedBy,
        });
      });
    } catch (e) {
      rethrow;
    }
  }
}
```

## 6. プロバイダー設定

### 6.1 掲示板プロバイダー (`lib/core/providers/bulletin_provider.dart`)

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../services/bulletin/bulletin_service.dart';

// 全体の掲示板投稿プロバイダー
final bulletinPostsProvider = FutureProvider<List<BulletinPost>>((ref) async {
  return await BulletinService.getPosts();
});

// ピン留め投稿プロバイダー
final pinnedBulletinPostsProvider = FutureProvider<List<BulletinPost>>((ref) async {
  return await BulletinService.getPosts(isPinned: true);
});

// カテゴリ別投稿プロバイダー
final bulletinPostsByCategoryProvider = FutureProvider.family<List<BulletinPost>, String>((ref, categoryId) async {
  return await BulletinService.getPosts(categoryId: categoryId);
});
```

## 7. 画面実装

### 7.1 投稿フォーム画面のカテゴリ制限

投稿フォーム画面で、管理者のみにクーポンと求人カテゴリを表示する実装：

```dart
// 管理者権限に基づいてカテゴリを制限
List<BulletinCategory> availableCategories;
final isAdmin = ref.watch(isAdminProvider);

if (isAdmin) {
  // 管理者の場合：すべてのカテゴリを表示
  availableCategories = BulletinCategories.all;
} else {
  // 一般ユーザーの場合：制限されたカテゴリを表示
  availableCategories = BulletinCategories.all
      .where((category) => category.id != 'job' && category.id != 'coupon')
      .toList();
}
```

### 7.2 投稿詳細画面のリアルタイム更新

```dart
class BulletinPostDetailScreen extends ConsumerStatefulWidget {
  final BulletinPost post;
  // ...

  // リアルタイム更新用のStreamを取得
  Stream<BulletinPost> get _postStream {
    return FirebaseFirestore.instance
        .collection('bulletin_posts')
        .doc(widget.post.id)
        .snapshots()
        .map((doc) => BulletinPost.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 他のコンテンツ...
            
            // クーポンセクション（リアルタイム更新）
            if (widget.post.isCoupon) ...[
              const SizedBox(height: 16),
              StreamBuilder<BulletinPost>(
                stream: _postStream,
                initialData: widget.post,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _buildCouponSection(snapshot.data!);
                  }
                  return _buildCouponSection(widget.post);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(BulletinPost post) {
    return Card(
      color: Colors.pink.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: Colors.pink.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'クーポン',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 使用状況表示
            Consumer(
              builder: (context, ref, child) {
                final currentUser = FirebaseAuth.instance.currentUser;
                final usedBy = post.couponUsedBy ?? <String, int>{};
                final currentUserUsageCount = currentUser != null ? (usedBy[currentUser.uid] ?? 0) : 0;
                
                return Text(
                  post.couponMaxUses != null 
                    ? '使用回数: $currentUserUsageCount / ${post.couponMaxUses!}'
                    : '使用回数: ${currentUserUsageCount}回（無制限）',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // クーポン使用ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canUseCoupon(post) ? () => _useCoupon(post) : null,
                icon: const Icon(Icons.redeem),
                label: Text(_getCouponButtonText(post)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _useCoupon(BulletinPost post) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_offer, color: Colors.pink),
            SizedBox(width: 8),
            Text('クーポン使用確認'),
          ],
        ),
        content: Text('「${post.title}」のクーポンを使用しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('使用する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BulletinService.useCoupon(post.id, currentUser.uid);
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('クーポン使用完了'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('「${post.title}」のクーポンを使用しました！'),
                  const SizedBox(height: 8),
                  Text('投稿者: ${post.authorName}'),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('クーポン使用に失敗しました: $e')),
          );
        }
      }
    }
  }
}
```

## 8. 重要な実装ポイント

### 8.1 変数名・メソッド名の統一

- **クーポン使用記録**: `couponUsedBy` (Map<String, int>)
- **ユーザーごとの使用回数**: `currentUserUsageCount`
- **最大使用回数**: `couponMaxUses`
- **管理者権限チェック**: `isAdminProvider`
- **リアルタイムストリーム**: `_postStream`

### 8.2 Firebase連携パターン

```dart
// Firestoreリアルタイム監視
FirebaseFirestore.instance
    .collection('bulletin_posts')
    .doc(postId)
    .snapshots()
    .map((doc) => BulletinPost.fromJson(doc.data()!))

// トランザクションによる安全な更新
await FirebaseFirestore.instance.runTransaction((transaction) async {
  // データ読み取り → 検証 → 更新
});

// Firebase Storage画像アップロード
final Reference ref = FirebaseStorage.instance
    .ref()
    .child('bulletin_images')
    .child(userId)
    .child(fileName);
```

### 8.3 権限チェックの実装パターン

```dart
// プロバイダーベースの権限チェック
final isAdmin = ref.watch(isAdminProvider);

// コンポーネント内でのセキュリティチェック
final canEdit = isOwner || adminState.when(
  data: (permissions) => permissions?.isAdmin == true,
  loading: () => false,
  error: (_, __) => false,
);
```

### 8.4 エラーハンドリング

```dart
try {
  // 処理実行
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('エラー: $e')),
    );
  }
  rethrow; // 必要に応じて再スロー
}
```

このガイドに従って実装することで、同一の機能、変数名、Firebase連携パターンを持つ掲示板システムを構築できます。