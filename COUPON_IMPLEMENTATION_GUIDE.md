# クーポン機能実装ガイド

## 概要
掲示板投稿にクーポン機能を追加し、使用回数制限と使用履歴追跡を実装する完全なガイドです。

**重要**: クーポン使用回数制限について
- ユーザーごとの使用回数制限
- 各ユーザーは設定された上限回数まで使用可能
- 全体の使用回数も追跡しますが制限はしません

---

## 前提条件

- Flutter 3.7.0+
- Firebase SDK (Firestore, Auth, Storage)
- Riverpod (hooks_riverpod)
- 既存の掲示板システム (BulletinPost モデル)

---

## 1. モデル更新

### `lib/models/bulletin/bulletin_model.dart`

#### BulletinPost クラスにフィールド追加：

```dart
class BulletinPost {
  // 既存のフィールド...
  
  // クーポン関連フィールドを追加
  final bool isCoupon; // クーポン投稿かどうか
  final int? couponMaxUses; // ユーザーごとのクーポン最大使用回数
  final int couponUsedCount; // 全体のクーポン使用済み回数
  final Map<String, int>? couponUsedBy; // ユーザーごとの使用回数

  const BulletinPost({
    // 既存のパラメータ...
    
    // クーポン関連パラメータを追加
    this.isCoupon = false,
    this.couponMaxUses,
    this.couponUsedCount = 0,
    this.couponUsedBy,
  });

  factory BulletinPost.fromJson(Map<String, dynamic> json) {
    try {
      return BulletinPost(
        // 既存のフィールド設定...
        
        // クーポン関連フィールドを追加
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
      // エラーハンドリング
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      // 既存のフィールド...
      
      // クーポン関連フィールドを追加
      'isCoupon': isCoupon,
      'couponMaxUses': couponMaxUses,
      'couponUsedCount': couponUsedCount,
      'couponUsedBy': couponUsedBy,
    };
  }
}
```

#### BulletinCategories クラスにクーポンカテゴリ追加：

```dart
class BulletinCategories {
  // 既存のカテゴリ...
  
  // クーポンカテゴリを追加
  static const coupon = BulletinCategory(
    id: 'coupon',
    name: 'クーポン',
    color: '#E91E63',
    icon: 'local_offer',
  );

  static const List<BulletinCategory> all = [
    event,
    club,
    announcement,
    job,
    coupon, // クーポンを追加
    other,
  ];
}
```

---

## 2. サービス層更新

### `lib/services/bulletin/bulletin_service.dart`

#### useCoupon メソッドを追加：

```dart
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
      
      // クーポン投稿でない場合はエラー
      if (!post.isCoupon) {
        throw Exception('この投稿はクーポンではありません');
      }
      
      // ユーザーごとの使用回数上限チェック
      final usedBy = post.couponUsedBy ?? <String, int>{};
      final currentUserUsageCount = usedBy[userId] ?? 0;
      
      if (post.couponMaxUses != null && currentUserUsageCount >= post.couponMaxUses!) {
        throw Exception('あなたはこのクーポンの使用回数上限に達しています');
      }
      
      // 使用記録を更新（ユーザーごとの使用回数）
      final updatedUsedBy = Map<String, int>.from(usedBy);
      updatedUsedBy[userId] = currentUserUsageCount + 1;
      
      transaction.update(postRef, {
        'couponUsedCount': post.couponUsedCount + 1,
        'couponUsedBy': updatedUsedBy,
      });
    });
  } catch (e) {
    print('クーポン使用エラー: $e');
    rethrow;
  }
}
```

#### getPosts メソッドでピン留め優先ソート：

```dart
static Future<List<BulletinPost>> getPosts({
  int limit = 20,
  DocumentSnapshot? lastDocument,
  String? categoryId,
  bool? isPinned,
}) async {
  try {
    Query query = _firestore
        .collection('bulletin_posts')
        .where('isActive', isEqualTo: true);

    // カテゴリでフィルタリング
    if (categoryId != null) {
      query = query.where('category.id', isEqualTo: categoryId);
    }

    // ピン留めでフィルタリング
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
      // まずピン留めステータスで比較
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // ピン留めステータスが同じ場合は作成日時で比較
      return b.createdAt.compareTo(a.createdAt);
    });

    // ページネーション処理
    if (lastDocument != null) {
      int startIndex = 0;
      for (int i = 0; i < posts.length; i++) {
        if (posts[i].id == lastDocument.id) {
          startIndex = i + 1;
          break;
        }
      }
      posts = posts.skip(startIndex).take(limit).toList();
    } else {
      posts = posts.take(limit).toList();
    }
    
    return posts;
  } catch (e) {
    throw Exception('投稿の取得に失敗しました: $e');
  }
}
```

---

## 3. プロバイダー更新

### `lib/core/providers/bulletin_provider.dart`

#### ピン留め優先ソートを追加：

```dart
final bulletinPostsProvider = FutureProvider<List<BulletinPost>>((ref) async {
  // データ取得処理...
  
  // ピン留め投稿を優先してソート
  posts.sort((a, b) {
    // まずピン留めステータスで比較
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;
    
    // ピン留めステータスが同じ場合は作成日時で比較
    return b.createdAt.compareTo(a.createdAt);
  });
  
  return posts;
});
```

---

## 4. 投稿作成フォーム更新

### `lib/screens/bulletin/bulletin_post_form_screen.dart`

#### 状態変数を追加：

```dart
class _BulletinPostFormScreenState extends ConsumerState<BulletinPostFormScreen> {
  // 既存の変数...
  
  // クーポン関連状態変数を追加
  bool _isCoupon = false; // クーポン投稿かどうか
  int? _couponMaxUses; // クーポン最大使用回数
  final _couponMaxUsesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // クーポンカテゴリが初期選択されている場合の処理
    _isCoupon = _selectedCategory.id == 'coupon';
  }

  @override
  void dispose() {
    // 既存のdispose...
    _couponMaxUsesController.dispose();
    super.dispose();
  }
}
```

#### カテゴリ選択ロジック更新：

```dart
onSelected: (selected) {
  if (selected) {
    setState(() {
      _selectedCategory = category;
      _isCoupon = category.id == 'coupon';
      if (!_isCoupon) {
        _couponMaxUses = null;
        _couponMaxUsesController.clear();
      }
    });
  }
},
```

#### アイコンマッピング追加：

```dart
IconData _getCategoryIcon(String iconName) {
  switch (iconName) {
    // 既存のケース...
    case 'local_offer':
      return Icons.local_offer;
    default:
      return Icons.circle;
  }
}
```

#### クーポン設定ウィジェット追加：

```dart
// クーポン設定ウィジェット
Widget _buildCouponSettings() {
  return Card(
    color: Colors.pink.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer,
                color: Colors.pink.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'クーポン設定',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _couponMaxUsesController,
            decoration: const InputDecoration(
              labelText: '使用可能回数',
              hintText: '例: 100（空白の場合は無制限）',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.confirmation_num),
              helperText: '空白にすると無制限で使用できます',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _couponMaxUses = value.trim().isNotEmpty ? int.tryParse(value.trim()) : null;
              });
            },
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final intValue = int.tryParse(value.trim());
                if (intValue == null) {
                  return '有効な数値を入力してください';
                }
                if (intValue <= 0) {
                  return '1以上の値を入力してください';
                }
              }
              return null;
            },
          ),
        ],
      ),
    ),
  );
}
```

#### フォームレイアウト更新：

```dart
// カテゴリ選択
_buildCategorySelector(),
const SizedBox(height: 16),

// クーポン設定（クーポンカテゴリ選択時のみ表示）
if (_isCoupon) ...[
  _buildCouponSettings(),
  const SizedBox(height: 16),
],

// 投稿者名
TextFormField(/* 既存の投稿者名フィールド */),
```

#### 投稿作成時にクーポンデータ追加：

```dart
final BulletinPost post = BulletinPost(
  // 既存のフィールド...
  
  // クーポンデータを追加
  isCoupon: _isCoupon, // クーポン投稿フラグ
  couponMaxUses: _isCoupon ? _couponMaxUses : null, // クーポン最大使用回数
  couponUsedCount: 0, // 使用回数は0で初期化
  couponUsedBy: null, // 使用履歴は空で初期化
);
```

---

## 5. 投稿編集フォーム更新

### _BulletinPostEditScreenState クラス

#### 状態変数追加：

```dart
class _BulletinPostEditScreenState extends ConsumerState<BulletinPostEditScreen> {
  // 既存の変数...
  
  // クーポン関連状態変数を追加
  bool _isCoupon = false; // クーポン投稿かどうか
  int? _couponMaxUses; // クーポン最大使用回数
  final _couponMaxUsesController = TextEditingController();
}
```

#### 初期化処理に追加：

```dart
void _initializeFormData() {
  final post = widget.post;
  // 既存の初期化...
  
  // クーポン設定を初期化
  _isCoupon = post.isCoupon; // クーポン設定を初期化
  _couponMaxUses = post.couponMaxUses; // クーポン最大使用回数を初期化
  _couponMaxUsesController.text = post.couponMaxUses?.toString() ?? ''; // クーポン使用回数フィールドを初期化
}
```

#### 更新処理にクーポンデータ追加：

```dart
final updatedPost = BulletinPost(
  // 既存のフィールド...
  
  // クーポンデータを追加
  isCoupon: _isCoupon, // クーポン投稿フラグ
  couponMaxUses: _isCoupon ? _couponMaxUses : null, // クーポン最大使用回数
  couponUsedCount: widget.post.couponUsedCount, // 既存の使用回数を保持
  couponUsedBy: widget.post.couponUsedBy, // 既存の使用履歴を保持
);
```

---

## 6. 詳細画面更新

### `lib/screens/bulletin/bulletin_post_detail_screen.dart`

#### インポート追加：

```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/bulletin/bulletin_service.dart';
```

#### クーポンセクション表示：

```dart
// 投稿者情報の後に追加
if (widget.post.isCoupon) ...[
  const SizedBox(height: 16),
  _buildCouponSection(),
],
```

#### クーポンセクションウィジェット：

```dart
// クーポンセクションを構築
Widget _buildCouponSection() {
  return Card(
    color: Colors.pink.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer,
                color: Colors.pink.shade700,
                size: 24,
              ),
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
          if (widget.post.couponMaxUses != null) ...[
            Row(
              children: [
                Icon(Icons.confirmation_num, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '残り使用回数: ${widget.post.couponMaxUses! - widget.post.couponUsedCount} / ${widget.post.couponMaxUses!}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ] else ...[
            Row(
              children: [
                Icon(Icons.confirmation_num, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '使用回数: ${widget.post.couponUsedCount}回（無制限）',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // クーポン使用ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canUseCoupon() ? () => _useCoupon() : null,
              icon: const Icon(Icons.redeem),
              label: Text(_getCouponButtonText()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

#### クーポン使用チェックメソッド：

```dart
// クーポン使用可能かチェック
bool _canUseCoupon() {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return false;
  
  // ユーザーごとの使用回数上限チェック
  final usedBy = widget.post.couponUsedBy ?? <String, int>{};
  final currentUserUsageCount = usedBy[currentUser.uid] ?? 0;
  
  if (widget.post.couponMaxUses != null && 
      currentUserUsageCount >= widget.post.couponMaxUses!) {
    return false;
  }
  
  return true;
}

// ボタンテキストを取得
String _getCouponButtonText() {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return 'ログインが必要';
  
  // ユーザーごとの使用回数上限チェック
  final usedBy = widget.post.couponUsedBy ?? <String, int>{};
  final currentUserUsageCount = usedBy[currentUser.uid] ?? 0;
  
  if (widget.post.couponMaxUses != null && 
      currentUserUsageCount >= widget.post.couponMaxUses!) {
    return '使用回数上限に達しています';
  }
  
  return 'クーポンを使用する';
}
```

#### クーポン使用処理メソッド：

```dart
// クーポン使用処理
void _useCoupon() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ログインが必要です')),
    );
    return;
  }

  // 確認ダイアログ
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
      content: Text('「${widget.post.title}」のクーポンを使用しますか？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('使用する'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await BulletinService.useCoupon(widget.post.id, currentUser.uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('クーポンを使用しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 詳細画面を更新するために親画面に戻る
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('クーポン使用に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

---

## 7. 掲示板表示画面更新

### `lib/screens/main/main_screen.dart`

#### モック画像実装：

```dart
// カテゴリに応じたモック画像を生成
Widget _buildMockImage(BulletinCategory category) {
  IconData iconData;
  Color backgroundColor;
  Color iconColor;
  String categoryText;

  switch (category.id) {
    case 'event':
      iconData = Icons.event;
      backgroundColor = const Color(0xFF2196F3).withOpacity(0.1);
      iconColor = const Color(0xFF2196F3);
      categoryText = 'イベント';
      break;
    case 'club':
      iconData = Icons.group;
      backgroundColor = const Color(0xFFFF9800).withOpacity(0.1);
      iconColor = const Color(0xFFFF9800);
      categoryText = 'サークル・部活';
      break;
    case 'announcement':
      iconData = Icons.announcement;
      backgroundColor = const Color(0xFFF44336).withOpacity(0.1);
      iconColor = const Color(0xFFF44336);
      categoryText = 'お知らせ';
      break;
    case 'job':
      iconData = Icons.work;
      backgroundColor = const Color(0xFF9C27B0).withOpacity(0.1);
      iconColor = const Color(0xFF9C27B0);
      categoryText = '求人・就職';
      break;
    case 'coupon':
      iconData = Icons.local_offer;
      backgroundColor = const Color(0xFFE91E63).withOpacity(0.1);
      iconColor = const Color(0xFFE91E63);
      categoryText = 'クーポン';
      break;
    default:
      iconData = Icons.article;
      backgroundColor = const Color(0xFF607D8B).withOpacity(0.1);
      iconColor = const Color(0xFF607D8B);
      categoryText = 'その他';
      break;
  }

  return Container(
    width: double.infinity,
    color: backgroundColor,
    child: Stack(
      children: [
        // 背景パターン
        Positioned.fill(
          child: CustomPaint(
            painter: MockImagePainter(iconColor.withOpacity(0.05)),
          ),
        ),
        // メインコンテンツ
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconData,
                size: 48,
                color: iconColor.withOpacity(0.8),
              ),
              const SizedBox(height: 8),
              Text(
                categoryText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

#### CustomPainterクラス追加：

```dart
// モック画像の背景パターンを描画するCustomPainter
class MockImagePainter extends CustomPainter {
  final Color color;

  MockImagePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 格子パターンを描画
    const gridSize = 30.0;
    
    // 縦線
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    
    // 横線
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

#### 画像表示ロジック更新：

```dart
// 画像部分（常に表示）
ClipRRect(
  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
  child: AspectRatio(
    aspectRatio: 16 / 9,
    child: post.imageUrl.isNotEmpty 
      ? Image.network(
          post.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildMockImage(post.category),
        )
      : _buildMockImage(post.category),
  ),
),
```

#### ピン留め表示追加：

```dart
// ヘッダー行
Row(
  children: [
    // ピン留めアイコン
    if (post.isPinned) ...[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.push_pin,
              size: 12,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 2),
            Text(
              'ピン留め',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 4),
    ],
    // 既存のカテゴリ表示...
  ],
),
```

---

## 8. Firebase Firestore セキュリティルール

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /bulletin_posts/{postId} {
      // 既存のルール...
      
      // クーポン使用時のルール
      allow update: if request.auth != null 
        && (resource.data.isCoupon == true)
        && (request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['couponUsedCount', 'couponUsedBy']))
        && (request.resource.data.couponUsedCount == resource.data.couponUsedCount + 1)
        && (!(resource.data.couponUsedBy.keys().hasAny([request.auth.uid])));
    }
  }
}
```

---

## 9. 実装チェックリスト

### ✅ 必須実装項目

1. **モデル更新**
   - [ ] BulletinPost にクーポンフィールド追加
   - [ ] fromJson/toJson でクーポンデータ処理
   - [ ] クーポンカテゴリ追加

2. **サービス層**
   - [ ] useCoupon メソッド実装
   - [ ] ピン留め優先ソート実装
   - [ ] nullセーフなチェックロジック

3. **UI実装**
   - [ ] 投稿フォームにクーポン設定追加
   - [ ] カテゴリ選択時の動的表示
   - [ ] 詳細画面にクーポンセクション追加
   - [ ] モック画像表示
   - [ ] ピン留め表示

4. **権限・セキュリティ**
   - [ ] Firebase認証チェック
   - [ ] 使用済みチェック
   - [ ] 使用回数制限チェック
   - [ ] トランザクション処理

### 🔧 トラブルシューティング

**問題**: ユーザーごとの使用制限が正しく動作しない
**解決**: `Map<String, int>`でユーザーごとの使用回数を追跡し、個別制限をチェック

**問題**: ピン留めが優先されない  
**解決**: データ取得後にアプリケーション側でソート

**問題**: モック画像が表示されない
**解決**: 画像URL空チェック + AspectRatio設定

---

## 10. テスト手順

1. **クーポン投稿作成**
   - クーポンカテゴリ選択
   - 使用回数設定（空白=無制限）
   - 投稿作成確認

2. **クーポン使用テスト**
   - 詳細画面でクーポンセクション表示確認
   - 使用可能状態でボタン有効確認
   - クーポン使用実行
   - 使用済み状態に変更確認

3. **表示テスト**
   - ピン留め投稿の優先表示
   - モック画像表示
   - カテゴリ別表示確認

この実装ガイドに従うことで、完全に同じクーポン機能を他の環境で再現できます。