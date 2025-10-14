import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bulletin/bulletin_model.dart';

class TestDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// テスト用の掲示板投稿データを作成
  static Future<void> createTestBulletinPost() async {
    try {
      final testPost = BulletinPost(
        id: '',
        title: 'テスト投稿 - 学園祭のお知らせ',
        description: 'これはテスト用の投稿です。来月開催される学園祭の詳細情報をお知らせします。多数の企画をご用意しておりますので、ぜひご参加ください。',
        imageUrl: 'https://picsum.photos/800/600?random=1',
        category: BulletinCategories.all.firstWhere((c) => c.id == 'event'),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        authorId: 'test_user_123',
        authorName: 'テストユーザー',
        viewCount: 0,
        isPinned: true,
        isActive: true,
      );

      await _firestore.collection('bulletin_posts').add(testPost.toJson());
      print('テスト投稿が作成されました');
    } catch (e) {
      print('テスト投稿の作成に失敗しました: $e');
    }
  }

  /// 複数のテスト投稿を作成
  static Future<void> createMultipleTestPosts() async {
    final testPosts = [
      {
        'title': '千葉工業大学 学園祭開催のお知らせ',
        'description': '来月開催される学園祭の詳細情報です。各学部・サークルの出展や模擬店、ステージイベントなど多数の企画をご用意しております。',
        'category': 'event',
        'isPinned': true,
      },
      {
        'title': 'プログラミングサークル メンバー募集',
        'description': 'プログラミングに興味のある学生を募集しています！初心者歓迎、一緒に技術を学びましょう。',
        'category': 'club',
        'isPinned': false,
      },
      {
        'title': '前期試験のお知らせ',
        'description': '前期試験の日程および注意事項をお知らせします。試験会場や時間割の詳細は後日掲示します。',
        'category': 'academic',
        'isPinned': false,
      },
      {
        'title': 'アルバイト情報 - 塾講師募集',
        'description': '近隣の学習塾でアルバイト講師を募集しています。理系科目を教えられる方を歓迎します。',
        'category': 'job',
        'isPinned': false,
      },
    ];

    for (int i = 0; i < testPosts.length; i++) {
      final postData = testPosts[i];
      final category = BulletinCategories.all.firstWhere((c) => c.id == postData['category']);
      
      final post = BulletinPost(
        id: '',
        title: postData['title'] as String,
        description: postData['description'] as String,
        imageUrl: 'https://picsum.photos/800/600?random=${i + 1}',
        category: category,
        createdAt: DateTime.now().subtract(Duration(hours: i * 2)),
        expiresAt: DateTime.now().add(Duration(days: 30 + i)),
        authorId: 'test_user_${i + 1}',
        authorName: 'テストユーザー${i + 1}',
        viewCount: i * 5,
        isPinned: postData['isPinned'] as bool,
        isActive: true,
      );

      try {
        await _firestore.collection('bulletin_posts').add(post.toJson());
        print('テスト投稿 "${post.title}" が作成されました');
      } catch (e) {
        print('テスト投稿の作成に失敗しました: $e');
      }
    }
  }

  /// テスト投稿を全て削除
  static Future<void> deleteAllTestPosts() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('bulletin_posts')
          .where('authorId', arrayContains: 'test_user')
          .get();

      final WriteBatch batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('テスト投稿を削除しました');
    } catch (e) {
      print('テスト投稿の削除に失敗しました: $e');
    }
  }
}