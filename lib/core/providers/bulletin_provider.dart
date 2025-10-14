import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../services/cache_service.dart';

// Firestore掲示板データプロバイダー（キャッシュ対応）
final bulletinPostsProvider = FutureProvider<List<BulletinPost>>((ref) async {
  try {
    print('掲示板データを取得中...');
    
    // まずキャッシュから取得を試行
    final cachedPosts = await CacheService.getCachedBulletinPosts();
    if (cachedPosts != null && cachedPosts.isNotEmpty) {
      print('📦 キャッシュからデータを返却: ${cachedPosts.length}件');
      
      // バックグラウンドで最新データを取得してキャッシュ更新
      _updateCacheInBackground();
      
      return cachedPosts;
    }
    
    print('🌐 サーバーからデータを取得中...');
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('bulletin_posts')
        .where('approvalStatus', isEqualTo: 'approved')
        .get();
    
    print('取得した投稿数: ${snapshot.docs.length}');
    
    final posts = <BulletinPost>[];
    for (final doc in snapshot.docs) {
      try {
        print('処理中のドキュメント ID: ${doc.id}');
        final data = doc.data();
        print('生データ: $data');
        
        final postData = {
          'id': doc.id,
          ...data,
        };
        print('fromJson用データ: $postData');
        
        final post = BulletinPost.fromJson(postData);
        // isActiveでフィルタリング
        if (post.isActive) {
          posts.add(post);
          print('✅ 投稿処理成功: ${post.title}');
        } else {
          print('⏭️ 非アクティブ投稿をスキップ: ${post.title}');
        }
      } catch (e, stackTrace) {
        print('❌ 投稿処理エラー (ID: ${doc.id}): $e');
        print('スタックトレース: $stackTrace');
        print('問題のあるデータ: ${doc.data()}');
        // エラーがあっても処理を続行
      }
    }
        
    print('解析した投稿データ: ${posts.length}件');
    
    // ピン留め投稿を優先してソート
    posts.sort((a, b) {
      // まずピン留めステータスで比較
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // ピン留めステータスが同じ場合は作成日時で比較
      return b.createdAt.compareTo(a.createdAt);
    });
    
    // キャッシュに保存
    await CacheService.saveBulletinPosts(posts);
    
    for (final post in posts) {
      print('- ${post.title} (${post.category.name})');
    }
    
    return posts;
  } catch (e, stackTrace) {
    // Firebaseが利用できない場合は空のリストを返す
    print('掲示板データの取得に失敗: $e');
    print('スタックトレース: $stackTrace');
    
    // 詳細なエラー情報をログ出力
    if (e.toString().contains('network')) {
      print('ネットワークエラーの可能性があります');
    } else if (e.toString().contains('permission')) {
      print('権限エラーの可能性があります');
    } else if (e.toString().contains('firebase')) {
      print('Firebase設定エラーの可能性があります');
    }
    
    // エラーを再スローしてUIに表示
    rethrow;
  }
});

// カテゴリ別の投稿フィルター
final bulletinPostsByCategoryProvider = FutureProvider.family<List<BulletinPost>, String?>((ref, categoryId) async {
  final posts = await ref.watch(bulletinPostsProvider.future);
  
  if (categoryId == null) {
    return posts;
  }
  
  return posts.where((post) => post.category.id == categoryId).toList();
});

// ピン留め投稿
final pinnedBulletinPostsProvider = FutureProvider<List<BulletinPost>>((ref) async {
  final posts = await ref.watch(bulletinPostsProvider.future);
  return posts.where((post) => post.isPinned).toList();
});

// 人気投稿（閲覧数順）
final popularBulletinPostsProvider = FutureProvider<List<BulletinPost>>((ref) async {
  final posts = await ref.watch(bulletinPostsProvider.future);
  final sortedPosts = List<BulletinPost>.from(posts);
  sortedPosts.sort((a, b) => b.viewCount.compareTo(a.viewCount));
  return sortedPosts.take(5).toList();
});

// バックグラウンドでキャッシュ更新
Future<void> _updateCacheInBackground() async {
  try {
    print('🔄 バックグラウンドでキャッシュ更新中...');
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('bulletin_posts')
        .where('approvalStatus', isEqualTo: 'approved')
        .get();
    
    final posts = <BulletinPost>[];
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        final postData = {
          'id': doc.id,
          ...data,
        };
        final post = BulletinPost.fromJson(postData);
        if (post.isActive) {
          posts.add(post);
        }
      } catch (e) {
        print('バックグラウンド更新エラー (ID: ${doc.id}): $e');
      }
    }
    
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await CacheService.saveBulletinPosts(posts);
    
    print('✅ バックグラウンドキャッシュ更新完了: ${posts.length}件');
  } catch (e) {
    print('❌ バックグラウンド更新失敗: $e');
  }
}