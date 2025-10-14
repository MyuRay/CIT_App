import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/providers/firebase_menu_provider.dart';
import '../../services/firebase/firebase_menu_service.dart';
import '../../services/firebase/firebase_diagnostics.dart';

class FirebaseDebugScreen extends ConsumerWidget {
  const FirebaseDebugScreen({super.key});

  /// Firebase Storage URLの有効性を確認し、必要に応じて新しいURLを取得
  Future<String?> _getValidImageUrl(String originalUrl) async {
    try {
      // まず元のURLを試す
      final response = await http.head(Uri.parse(originalUrl));
      if (response.statusCode == 200) {
        return originalUrl;
      }
      
      // 失敗した場合、Firebase SDKから新しいURLを取得
      debugPrint('Original URL failed (${response.statusCode}), getting fresh URL...');
      
      // URLからファイル名を抽出
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.lastWhere(
        (segment) => segment.contains('.png'),
        orElse: () => '',
      );
      
      if (fileName.isEmpty) {
        throw Exception('Invalid file name');
      }
      
      // Firebase Storageから新しいURLを取得
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child('menu_images/$fileName');
      final newUrl = await ref.getDownloadURL();
      
      debugPrint('Got fresh URL: $newUrl');
      return newUrl;
      
    } catch (e) {
      debugPrint('_getValidImageUrl failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Storage デバッグ'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 詳細診断ボタン
            _buildDiagnosticsButton(),
            
            const Divider(height: 32),
            
            // Firebase接続テスト
            _buildConnectionTest(ref),
            
            const Divider(height: 32),
            
            // Storage上の全画像リスト
            _buildImagesList(ref),
            
            const Divider(height: 32),
            
            // 個別画像URL取得テスト
            _buildIndividualImageTest(ref),
            
            const Divider(height: 32),
            
            // 統計情報
            _buildStats(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsButton() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.medical_services, color: Colors.orange),
                SizedBox(width: 8),
                Text('Firebase詳細診断', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Firebase接続の問題を詳しく診断します。結果はコンソールに出力されます。'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseDiagnostics.runFullDiagnostics();
                    },
                    icon: const Icon(Icons.psychology),
                    label: const Text('全体診断実行'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FirebaseDiagnostics.testStorageRules();
                      debugPrint('Storage Rules Test: $result');
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('ルールテスト'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTest(WidgetRef ref) {
    final connectionTest = ref.watch(firebaseStorageConnectionProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi_tethering, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Firebase Storage 接続テスト', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.refresh(firebaseStorageConnectionProvider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            connectionTest.when(
              data: (isConnected) => Row(
                children: [
                  Icon(
                    isConnected ? Icons.check_circle : Icons.error,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? '接続成功' : '接続失敗',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('接続テスト中...'),
                ],
              ),
              error: (error, _) => Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '接続エラー: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesList(WidgetRef ref) {
    final imagesList = ref.watch(firebaseMenuListProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Storage上の画像一覧', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.refresh(firebaseMenuListProvider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            imagesList.when(
              data: (images) {
                if (images.isEmpty) {
                  return const Text(
                    'Storage上に画像がありません',
                    style: TextStyle(color: Colors.orange),
                  );
                }
                
                return Column(
                  children: images.map((image) {
                    final name = image['name'] as String;
                    final size = image['size'] as int?;
                    final downloadUrl = image['download_url'] as String;
                    
                    return Builder(
                      builder: (context) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: kIsWeb
                                  ? FutureBuilder<String?>(
                                      future: _getValidImageUrl(downloadUrl),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          );
                                        }
                                        
                                        if (snapshot.hasError || !snapshot.hasData) {
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.image_not_supported, size: 24),
                                          );
                                        }
                                        
                                        return Image.network(
                                          snapshot.data!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          headers: const {
                                            'Accept': 'image/*',
                                            'Cache-Control': 'no-cache',
                                          },
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.image_not_supported, size: 24),
                                          ),
                                        );
                                      },
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: downloadUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image_not_supported, size: 24),
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text('サイズ: ${(size ?? 0) ~/ 1024}KB'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () => _showImageDialog(context, name, downloadUrl),
                                tooltip: 'プレビュー',
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () async {
                                  final uri = Uri.parse(downloadUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                                tooltip: '新しいタブで開く',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'エラー: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualImageTest(WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.crop_original, color: Colors.purple),
                SizedBox(width: 8),
                Text('個別画像URL取得テスト', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            
            // 津田沼テスト
            _buildCampusTest(ref, 'td', '津田沼キャンパス'),
            const SizedBox(height: 8),
            
            // 新習志野テスト
            _buildCampusTest(ref, 'sd1', '新習志野キャンパス'),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusTest(WidgetRef ref, String campus, String campusName) {
    final imageUrl = ref.watch(firebaseTodayMenuProvider(campus));
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(campusName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => ref.refresh(firebaseTodayMenuProvider(campus)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          imageUrl.when(
            data: (url) => url != null 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          const Text('URL取得成功', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        url,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : const Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('URL取得失敗', style: TextStyle(color: Colors.red)),
                    ],
                  ),
            loading: () => const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('URL取得中...'),
              ],
            ),
            error: (error, _) => Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'エラー: $error',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(WidgetRef ref) {
    final stats = ref.watch(firebaseStorageStatsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text('Storage統計情報', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.refresh(firebaseStorageStatsProvider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            stats.when(
              data: (statsData) {
                if (statsData.containsKey('error')) {
                  return const Text('統計情報の取得でエラーが発生しました');
                }
                
                return Column(
                  children: [
                    _buildStatRow('総画像数', '${statsData['total_images'] ?? 0}件'),
                    _buildStatRow('津田沼画像', '${statsData['td_images'] ?? 0}件'),
                    _buildStatRow('新習志野画像', '${statsData['sd1_images'] ?? 0}件'),
                    _buildStatRow('総サイズ', '${statsData['total_size_mb'] ?? 0}MB'),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('エラー: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String name, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.image, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () async {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            tooltip: '新しいタブで開く',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: 400,
                          maxHeight: 300,
                        ),
                        child: kIsWeb
                            ? FutureBuilder<String?>(
                                future: _getValidImageUrl(url),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Container(
                                      height: 200,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  
                                  if (snapshot.hasError || !snapshot.hasData) {
                                    return Container(
                                      height: 200,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error, size: 48, color: Colors.red),
                                          const SizedBox(height: 8),
                                          Text('画像の読み込みに失敗しました', 
                                               style: TextStyle(color: Colors.red)),
                                          const SizedBox(height: 8),
                                          Text('Firebase Storage認証エラー', 
                                               style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  return Image.network(
                                    snapshot.data!,
                                    fit: BoxFit.contain,
                                    headers: const {
                                      'Accept': 'image/*',
                                      'Cache-Control': 'no-cache',
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error, size: 48, color: Colors.red),
                                            const SizedBox(height: 8),
                                            Text('画像の読み込みに失敗しました', 
                                                 style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                            : CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, size: 48, color: Colors.red),
                                      const SizedBox(height: 8),
                                      Text('画像の読み込みに失敗しました'),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        url,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}