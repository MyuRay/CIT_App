import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../utils/test_data_helper.dart';
import '../../core/providers/bulletin_provider.dart';

class BulletinDebugScreen extends ConsumerStatefulWidget {
  const BulletinDebugScreen({super.key});

  @override
  ConsumerState<BulletinDebugScreen> createState() => _BulletinDebugScreenState();
}

class _BulletinDebugScreenState extends ConsumerState<BulletinDebugScreen> {
  List<Map<String, dynamic>> _debugLogs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _debugLogs.insert(0, {
        'time': DateTime.now(),
        'message': message,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掲示板デバッグ'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // デバッグボタン
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testFirebaseConnection,
                        child: const Text('Firebase接続テスト'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createTestPost,
                        child: const Text('テスト投稿作成'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _listAllPosts,
                        child: const Text('全投稿リスト'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _deleteTestPosts,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('テスト投稿削除'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testBulletinProvider,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        child: const Text('プロバイダーテスト'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _debugLogs.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        child: const Text('ログクリア'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // ローディングインジケーター
          if (_isLoading)
            const LinearProgressIndicator(),
            
          // ログ表示
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _debugLogs.length,
              itemBuilder: (context, index) {
                final log = _debugLogs[index];
                final time = log['time'] as DateTime;
                final message = log['message'] as String;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testFirebaseConnection() async {
    setState(() => _isLoading = true);
    _addLog('Firebase接続テストを開始...');

    try {
      final firestore = FirebaseFirestore.instance;
      
      // 設定情報の確認
      _addLog('Firestore インスタンス取得: 成功');
      _addLog('App ID: ${firestore.app.name}');
      
      // 簡単な読み取りテスト
      final testDoc = await firestore.collection('test').doc('connection').get();
      _addLog('テスト読み取り: 成功 (exists: ${testDoc.exists})');
      
      // 簡単な書き込みテスト
      await firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
      });
      _addLog('テスト書き込み: 成功');
      
      _addLog('✅ Firebase接続テスト: 全て成功');
    } catch (e) {
      _addLog('❌ Firebase接続エラー: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTestPost() async {
    setState(() => _isLoading = true);
    _addLog('テスト投稿を作成中...');

    try {
      final firestore = FirebaseFirestore.instance;
      
      final testPost = BulletinPost(
        id: '',
        title: 'テスト投稿 - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'これはAndroidデバッグ用のテスト投稿です。現在時刻: ${DateTime.now()}',
        imageUrl: '',
        category: BulletinCategories.all.first,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        authorId: 'debug_user',
        authorName: 'デバッグユーザー',
        viewCount: 0,
        isPinned: false,
        isActive: true,
      );

      final docRef = await firestore.collection('bulletin_posts').add(testPost.toJson());
      _addLog('✅ テスト投稿作成成功: ${docRef.id}');
      _addLog('投稿タイトル: ${testPost.title}');
    } catch (e) {
      _addLog('❌ テスト投稿作成失敗: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _listAllPosts() async {
    setState(() => _isLoading = true);
    _addLog('全投稿を取得中...');

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('bulletin_posts')
          .orderBy('createdAt', descending: true)
          .get();

      _addLog('取得した投稿数: ${snapshot.docs.length}');
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _addLog('📝 ID: ${doc.id}');
        _addLog('   タイトル: ${data['title']}');
        _addLog('   アクティブ: ${data['isActive']}');
        
        // 詳細な型情報をログ出力
        _addLog('   作成日時の型: ${data['createdAt']?.runtimeType}');
        _addLog('   作成日時の値: ${data['createdAt']}');
        
        try {
          if (data['createdAt'] != null) {
            final createdAt = data['createdAt'];
            if (createdAt.runtimeType.toString().contains('Timestamp')) {
              _addLog('   Timestamp変換: ${createdAt.toDate()}');
            }
          }
        } catch (e) {
          _addLog('   ❌ 日付変換エラー: $e');
        }
        
        // 全データの構造を確認
        _addLog('   全データキー: ${data.keys.toList()}');
        _addLog('   category型: ${data['category']?.runtimeType}');
        _addLog('   category値: ${data['category']}');
        
        _addLog('   ---');
      }
      
      if (snapshot.docs.isEmpty) {
        _addLog('⚠️ 投稿が見つかりませんでした');
      } else {
        _addLog('✅ 投稿リスト表示完了');
        
        // 実際のBulletinPost.fromJson()を試行
        _addLog('BulletinPost.fromJson()テスト開始...');
        try {
          for (final doc in snapshot.docs.take(1)) { // 最初の1件のみテスト
            final data = {
              'id': doc.id,
              ...doc.data(),
            };
            _addLog('fromJson用データ: $data');
            final post = BulletinPost.fromJson(data);
            _addLog('✅ fromJson成功: ${post.title}');
          }
        } catch (e, stackTrace) {
          _addLog('❌ fromJsonエラー: $e');
          _addLog('スタックトレース: $stackTrace');
        }
      }
    } catch (e, stackTrace) {
      _addLog('❌ 投稿取得エラー: $e');
      _addLog('スタックトレース: $stackTrace');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTestPosts() async {
    setState(() => _isLoading = true);
    _addLog('テスト投稿を削除中...');

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('bulletin_posts')
          .where('authorId', isEqualTo: 'debug_user')
          .get();

      _addLog('削除対象: ${snapshot.docs.length}件');

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        _addLog('削除予定: ${doc.data()['title']}');
      }

      await batch.commit();
      _addLog('✅ テスト投稿削除完了');
    } catch (e) {
      _addLog('❌ 削除エラー: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testBulletinProvider() async {
    setState(() => _isLoading = true);
    _addLog('Riverpodプロバイダーテストを開始...');

    try {
      // プロバイダーを直接呼び出してテスト
      _addLog('bulletinPostsProviderを呼び出し中...');
      await ref.read(bulletinFeedProvider.notifier).refresh();
      final posts = ref.read(bulletinPostsProvider).valueOrNull ?? const [];
      _addLog('✅ プロバイダー呼び出し成功');
      _addLog('取得した投稿数: ${posts.length}');
      
      for (final post in posts) {
        _addLog('- ${post.title} (${post.authorName})');
      }
      
    } catch (e, stackTrace) {
      _addLog('❌ プロバイダーエラー: $e');
      _addLog('スタックトレース: ${stackTrace.toString().substring(0, 500)}...');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}