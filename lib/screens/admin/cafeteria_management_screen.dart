import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/firebase_menu_provider.dart';
import '../../core/services/cache_service.dart';
import '../../services/firebase/firebase_menu_service.dart';

class CafeteriaManagementScreen extends ConsumerStatefulWidget {
  const CafeteriaManagementScreen({super.key});

  @override
  ConsumerState<CafeteriaManagementScreen> createState() => _CafeteriaManagementScreenState();
}

class _CafeteriaManagementScreenState extends ConsumerState<CafeteriaManagementScreen> {
  final List<_CafeTarget> _targets = const [
    _CafeTarget(label: '津田沼', campusCode: 'td', icon: Icons.restaurant),
    _CafeTarget(label: '新習志野 1F', campusCode: 'sd1', icon: Icons.ramen_dining),
    _CafeTarget(label: '新習志野 2F', campusCode: 'sd2', icon: Icons.rice_bowl),
  ];

  final Map<String, bool> _loading = {};
  int _refreshTick = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeaderHelp(context),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _targets.length,
            itemBuilder: (context, index) {
              final t = _targets[index];
              final busy = _loading[t.campusCode] == true;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(t.icon, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            t.label,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // プレビュー
                      FutureBuilder<String?>(
                        key: ValueKey('${t.campusCode}_$_refreshTick'),
                        future: FirebaseMenuService.getMenuImageDownloadUrlDirect(t.campusCode),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          }
                          final url = snapshot.data;
                          if (url == null || url.isEmpty) {
                            return Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, color: Colors.grey.shade500, size: 36),
                                    const SizedBox(height: 8),
                                    Text('画像未登録 (${t.campusCode}.png)', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(url, height: 160, fit: BoxFit.cover),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: busy ? null : () => _onUploadPressed(t.campusCode),
                            icon: const Icon(Icons.upload),
                            label: const Text('アップロード（PNG）'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: busy ? null : () => _onDeletePressed(t.campusCode),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('削除'),
                          ),
                          const Spacer(),
                          Text('${t.campusCode}.png', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderHelp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        color: Colors.blueGrey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.blueGrey.shade700),
                  const SizedBox(width: 8),
                  Text('学食メニュー画像 管理', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('・PNG画像のみ対応（自動で所定のファイル名に保存します）\n・既存画像がある場合は上書き保存されます\n・削除でFirebase Storageから画像を削除します'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onUploadPressed(String campus) async {
    try {
      setState(() => _loading[campus] = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowedExtensions: const ['png'],
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _loading[campus] = false);
        return;
      }

      final PlatformFile file = result.files.single;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ファイル読み込みに失敗しました')));
        }
        setState(() => _loading[campus] = false);
        return;
      }

      final url = await FirebaseMenuService.uploadMenuImage(campus, bytes);
      if (mounted) {
        if (url != null) {
          // 関連キャッシュを無効化
          await CacheService().removePersistentCache('firebase_today_menu_$campus');
          try { ref.invalidate(firebaseTodayMenuProvider(campus)); } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('アップロードしました')));
          setState(() => _refreshTick++);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('アップロードに失敗しました')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading[campus] = false);
    }
  }

  Future<void> _onDeletePressed(String campus) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('画像を削除'),
        content: Text('「$campus.png」をFirebaseから削除します。よろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      setState(() => _loading[campus] = true);
      final success = await FirebaseMenuService.deleteMenuImage(campus);
      if (mounted) {
        if (success) {
          await CacheService().removePersistentCache('firebase_today_menu_$campus');
          try { ref.invalidate(firebaseTodayMenuProvider(campus)); } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除しました')));
          setState(() => _refreshTick++);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除に失敗しました')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading[campus] = false);
    }
  }
}

class _CafeTarget {
  final String label;
  final String campusCode;
  final IconData icon;

  const _CafeTarget({required this.label, required this.campusCode, required this.icon});
}
