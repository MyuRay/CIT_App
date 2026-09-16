import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRulesTestScreen extends ConsumerStatefulWidget {
  const FirestoreRulesTestScreen({super.key});

  @override
  ConsumerState<FirestoreRulesTestScreen> createState() =>
      _FirestoreRulesTestScreenState();
}

class _FirestoreRulesTestScreenState
    extends ConsumerState<FirestoreRulesTestScreen> {
  String _testResult = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Rules テスト'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firestore Rules テスト',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('管理者権限コレクションへのアクセスをテストします'),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testReadAccess,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('読み取りテスト'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testWriteAccess,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('書き込みテスト'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testStreamAccess,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('リアルタイム監視テスト'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_testResult.isNotEmpty)
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'テスト結果',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _testResult = ''),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _testResult,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ エラーが発生した場合',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Firebase Console → Firestore Database → Rules',
                    ),
                    const SizedBox(height: 4),
                    const Text('2. 以下のルールを追加:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'match /admin_permissions/{document} {\n'
                        '  allow read, write: if request.auth != null;\n'
                        '}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('3. 「公開」ボタンをクリック'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testReadAccess() async {
    setState(() {
      _isLoading = true;
      _testResult = '';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません');
      }

      setState(() {
        _testResult = '🔍 読み取りテスト開始...\n';
        _testResult += 'ユーザーID: ${currentUser.uid}\n';
      });

      final doc =
          await FirebaseFirestore.instance
              .collection('admin_permissions')
              .doc(currentUser.uid)
              .get();

      setState(() {
        _testResult += '✅ 読み取り成功\n';
        _testResult += 'ドキュメント存在: ${doc.exists}\n';
        if (doc.exists) {
          _testResult += 'データ: ${doc.data()}\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ 読み取りエラー: $e\n';
        if (e.toString().contains('permission-denied')) {
          _testResult +=
              '\n🛠️ 解決方法: Firestore Rulesに admin_permissions の読み取り権限を追加してください';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testWriteAccess() async {
    setState(() {
      _isLoading = true;
      _testResult = '';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません');
      }

      setState(() {
        _testResult = '✍️ 書き込みテスト開始...\n';
        _testResult += 'ユーザーID: ${currentUser.uid}\n';
      });

      await FirebaseFirestore.instance
          .collection('admin_permissions')
          .doc(currentUser.uid)
          .set({
            'userId': currentUser.uid,
            'isAdmin': true,
            'canManagePosts': true,
            'canManageUsers': true,
            'canViewContacts': true,
            'canManageCategories': true,
            'grantedAt': Timestamp.now(),
            'grantedBy': currentUser.uid,
          });

      setState(() {
        _testResult += '✅ 書き込み成功\n';
        _testResult += '管理者権限ドキュメントを作成しました\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ 書き込みエラー: $e\n';
        if (e.toString().contains('permission-denied')) {
          _testResult +=
              '\n🛠️ 解決方法: Firestore Rulesに admin_permissions の書き込み権限を追加してください';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testStreamAccess() async {
    setState(() {
      _isLoading = true;
      _testResult = '';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません');
      }

      setState(() {
        _testResult = '🔄 リアルタイム監視テスト開始...\n';
        _testResult += 'ユーザーID: ${currentUser.uid}\n';
      });

      // 3秒間リアルタイム監視をテスト
      final stream =
          FirebaseFirestore.instance
              .collection('admin_permissions')
              .doc(currentUser.uid)
              .snapshots();

      bool hasData = false;
      final subscription = stream.listen(
        (doc) {
          if (!hasData) {
            hasData = true;
            setState(() {
              _testResult += '✅ リアルタイム監視成功\n';
              _testResult += 'ドキュメント存在: ${doc.exists}\n';
              if (doc.exists) {
                final data = doc.data();
                _testResult += 'isAdmin: ${data?['isAdmin']}\n';
              }
              _testResult += '\n🎉 StreamProviderが正常に動作します！';
            });
          }
        },
        onError: (e) {
          setState(() {
            _testResult += '❌ リアルタイム監視エラー: $e\n';
            if (e.toString().contains('permission-denied')) {
              _testResult +=
                  '\n🛠️ 解決方法: Firestore Rulesに admin_permissions の読み取り権限を追加してください';
            }
          });
        },
      );

      // 3秒後にサブスクリプションを停止
      await Future.delayed(const Duration(seconds: 3));
      subscription.cancel();

      if (!hasData) {
        setState(() {
          _testResult += '⏱️ タイムアウト: リアルタイム監視データを受信できませんでした';
        });
      }
    } catch (e) {
      setState(() {
        _testResult += '❌ リアルタイム監視テストエラー: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
