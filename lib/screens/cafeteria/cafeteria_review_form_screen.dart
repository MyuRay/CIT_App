import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/cafeteria_review_provider.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/settings_provider.dart';

class CafeteriaReviewFormScreen extends ConsumerStatefulWidget {
  const CafeteriaReviewFormScreen({
    super.key,
    this.initialCafeteriaId,
    this.initialMenuName,
    this.fixed = false,
    this.editingReview,
  });
  final String? initialCafeteriaId;
  final String? initialMenuName;
  final bool fixed; // 食堂・メニュー名を固定（編集不可）
  final CafeteriaReview? editingReview; // 既存レビューがあれば編集

  @override
  ConsumerState<CafeteriaReviewFormScreen> createState() => _CafeteriaReviewFormScreenState();
}

class _CafeteriaReviewFormScreenState extends ConsumerState<CafeteriaReviewFormScreen> {
  late String _cafeteriaId;
  final _menuController = TextEditingController();
  final _commentController = TextEditingController();
  final _nameController = TextEditingController();
  int _taste = 0, _volume = 0, _recommend = 0;
  bool _submitting = false;
  bool _anonymous = false;
  String _defaultDisplayName = '匿名';
  String _volumeGender = 'male'; // 'male' or 'female'
  double _buttonRight = 16.0; // ボタンの右側からの距離
  double _buttonBottom = 16.0; // ボタンの下部からの距離
  bool get _isEditing => widget.editingReview != null;

  // 15文字で折り返すヘルパーメソッド
  String _wrapText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i += maxLength) {
      if (i > 0) buffer.write('\n');
      buffer.write(text.substring(i, (i + maxLength).clamp(0, text.length)));
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    _cafeteriaId = widget.editingReview?.cafeteriaId ?? widget.initialCafeteriaId ?? Cafeterias.tsudanuma;
    if (widget.editingReview?.menuName != null) {
      _menuController.text = widget.editingReview!.menuName!;
    } else if (widget.initialMenuName != null) {
      _menuController.text = widget.initialMenuName!;
    }
    final user = FirebaseAuth.instance.currentUser;
    _defaultDisplayName = user?.displayName ?? (user?.email ?? '匿名');
    _nameController.text = widget.editingReview?.userName ?? _defaultDisplayName;

    // 読み込み: 量の評価の性別デフォルト
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      _volumeGender = widget.editingReview?.volumeGender ?? (prefs.getString('cafeteria_volume_gender') ?? 'male');
    } catch (_) {}

    // 編集時は既存評価・コメントを初期値に反映
    if (widget.editingReview != null) {
      _taste = widget.editingReview!.taste;
      _volume = widget.editingReview!.volume;
      _recommend = widget.editingReview!.recommend;
      _commentController.text = widget.editingReview!.comment ?? '';
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    _commentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    // 初期位置を設定（右下固定）
    if (_buttonRight == 16.0 && _buttonBottom == 16.0) {
      _buttonRight = 16.0; // 右側から16px
      _buttonBottom = padding.bottom + 16.0; // 下部から16px（パディング考慮）
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'レビューを更新' : 'レビューを書く'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: '削除',
              icon: const Icon(Icons.delete_outline),
              onPressed: _submitting ? null : () => _confirmAndDelete(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('食堂', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _cafeteriaId,
              items: const [
                DropdownMenuItem(value: Cafeterias.tsudanuma, child: Text('津田沼')),
                DropdownMenuItem(value: Cafeterias.narashino1F, child: Text('新習志野 1F')),
                DropdownMenuItem(value: Cafeterias.narashino2F, child: Text('新習志野 2F')),
              ],
              onChanged: (widget.fixed || _isEditing) ? null : (v) => setState(() => _cafeteriaId = v ?? Cafeterias.tsudanuma),
              // disabled when onChanged is null
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _menuController,
              decoration: const InputDecoration(
                labelText: 'メニュー名',
                hintText: '例: 唐揚げ定食、カレー など',
              ),
              enabled: !(widget.fixed || _isEditing),
              minLines: 1,
              maxLines: 2,
              expands: false,
            ),
            const SizedBox(height: 16),
            _RatingPicker(label: '美味しさ', value: _taste, onChanged: (v) => setState(() => _taste = v)),
          _RatingPicker(label: '量', value: _volume, onChanged: (v) => setState(() => _volume = v)),
            Padding(
              padding: const EdgeInsets.only(left: 70, top: 4),
              child: Row(
                children: [
                  _GenderRadio(
                    label: '男性',
                    value: 'male',
                    groupValue: _volumeGender,
                    onChanged: (v) async {
                      setState(() => _volumeGender = v);
                      try {
                        final prefs = ref.read(sharedPreferencesProvider);
                        await prefs.setString('cafeteria_volume_gender', v);
                      } catch (_) {}
                    },
                  ),
                  const SizedBox(width: 8),
                  _GenderRadio(
                    label: '女性',
                    value: 'female',
                    groupValue: _volumeGender,
                    onChanged: (v) async {
                      setState(() => _volumeGender = v);
                      try {
                        final prefs = ref.read(sharedPreferencesProvider);
                        await prefs.setString('cafeteria_volume_gender', v);
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),
          _RatingPicker(label: 'おすすめ', value: _recommend, onChanged: (v) => setState(() => _recommend = v)),
          const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    enabled: !_anonymous,
                    decoration: const InputDecoration(
                      labelText: '表示名',
                      hintText: '投稿に表示される名前',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _anonymous,
                          onChanged: (v) {
                            setState(() {
                              _anonymous = v ?? false;
                              if (_anonymous) {
                                _nameController.text = '匿名';
                              } else {
                                _nameController.text = _defaultDisplayName;
                              }
                            });
                          },
                        ),
                        const Text('匿名で投稿する'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'コメント（任意）',
            ),
              maxLines: 4,
            ),
                const SizedBox(height: 24),
                // スペーサーを追加してボタン分のスペースを確保
                const SizedBox(height: 80),
              ],
            ),
          ),
          // ドラッグ可能なボタン（右下固定）
          Positioned(
            right: _buttonRight,
            bottom: _buttonBottom,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  // 右下を固定してドラッグ（rightとbottomを更新）
                  _buttonRight = (_buttonRight - details.delta.dx).clamp(0.0, screenSize.width - 200);
                  _buttonBottom = (_buttonBottom - details.delta.dy).clamp(padding.bottom, screenSize.height - 80);
                });
              },
              onTap: () {
                if (!_submitting) {
                  _submit(context);
                }
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _wrapText(
                              _submitting ? '送信中...' : (_isEditing ? '更新する' : '投稿する'),
                              25,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_taste == 0 || _volume == 0 || _recommend == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('各評価（美味しさ・量・おすすめ）を選択してください')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final actions = ref.read(cafeteriaReviewActionsProvider);
      if (_isEditing) {
        final reviewId = widget.editingReview!.id;
        print('Updating review with ID: "$reviewId" (length: ${reviewId.length})'); // デバッグ用
        
        if (reviewId.isEmpty) {
          throw Exception('レビューIDが空です。編集できません。');
        }
        
        await actions.update(
          reviewId: reviewId,
          taste: _taste,
          volume: _volume,
          recommend: _recommend,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          userName: _nameController.text.trim().isEmpty ? '匿名' : _nameController.text.trim(),
          volumeGender: _volumeGender,
        );
      } else {
        await actions.create(
          cafeteriaId: _cafeteriaId,
          menuName: _menuController.text.trim().isEmpty ? null : _menuController.text.trim(),
          taste: _taste,
          volume: _volume,
          recommend: _recommend,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          userName: _nameController.text.trim().isEmpty ? '匿名' : _nameController.text.trim(),
          volumeGender: _volumeGender,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'レビューを更新しました' : 'レビューを投稿しました')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final reviewId = widget.editingReview?.id ?? '';
    if (reviewId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レビューIDが無効です')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('レビューを削除'),
        content: const Text('このレビューを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _submitting = true);
    try {
      final actions = ref.read(cafeteriaReviewActionsProvider);
      await actions.delete(reviewId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを削除しました')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _RatingPicker extends StatelessWidget {
  const _RatingPicker({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  String _getVolumeDescription(int rating) {
    switch (rating) {
      case 1:
        return '少ない';
      case 2:
        return 'やや少ない';
      case 3:
        return '適量';
      case 4:
        return 'やや多い';
      case 5:
        return '多い';
      default:
        return '';
    }
  }

  Color _getVolumeColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return Colors.orange; // 少ない
      case 3:
        return Colors.green; // 適量
      case 4:
      case 5:
        return Colors.blue; // 多い
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label)),
        ...List.generate(5, (i) {
          final filled = i < value;
          Color starColor;
          
          if (label == '量') {
            // 量の場合：星3が適量（緑）、星1-2が少ない（オレンジ）、星4-5が多い（青）
            if (i == 2) { // 星3（適量）
              starColor = filled ? Colors.green : Colors.grey;
            } else if (i < 2) { // 星1-2（少ない）
              starColor = filled ? Colors.orange : Colors.grey;
            } else { // 星4-5（多い）
              starColor = filled ? Colors.blue : Colors.grey;
            }
          } else {
            // 他の評価は通常の色
            starColor = filled ? Colors.amber : Colors.grey;
          }
          
          return IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: Icon(
              filled ? Icons.star : Icons.star_border,
              color: starColor,
            ),
            onPressed: () => onChanged(i + 1),
          );
        }),
        const SizedBox(width: 8),
        Text('$value/5', style: const TextStyle(color: Colors.grey)),
        if (label == '量' && value > 0) ...[
          const SizedBox(width: 8),
          Text(
            _getVolumeDescription(value),
            style: TextStyle(
              fontSize: 12,
              color: _getVolumeColor(value),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _GenderRadio extends StatelessWidget {
  const _GenderRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });
  final String label;
  final String value;
  final String groupValue;
  final Future<void> Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: (v) {
            if (v != null) {
              onChanged(v);
            }
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        GestureDetector(
          onTap: () => onChanged(value),
          child: Text(label),
        ),
      ],
    );
  }
}
