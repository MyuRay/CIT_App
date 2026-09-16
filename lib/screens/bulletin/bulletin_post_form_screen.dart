import '../../models/bulletin/bulletin_image_draft.dart';
import '../../services/bulletin/bulletin_image_save_session.dart';
import '../../widgets/bulletin/bulletin_image_picker.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../../core/providers/admin_provider.dart';

class BulletinPostFormScreen extends ConsumerStatefulWidget {
  const BulletinPostFormScreen({super.key});

  @override
  ConsumerState<BulletinPostFormScreen> createState() =>
      _BulletinPostFormScreenState();
}

class BulletinPostEditScreen extends ConsumerStatefulWidget {
  final BulletinPost post;

  const BulletinPostEditScreen({super.key, required this.post});

  @override
  ConsumerState<BulletinPostEditScreen> createState() =>
      _BulletinPostEditScreenState();
}

class _BulletinPostFormScreenState
    extends ConsumerState<BulletinPostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DateTime _createdAt = DateTime.now();
  late final String _postId = FirebaseFirestore.instance.collection('bulletin_posts').doc().id;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _externalUrlController = TextEditingController();

  BulletinCategory _selectedCategory = BulletinCategories.event;
  DateTime? _expiresAt;
  late final BulletinImageDraft _images;
  final _imageSave = BulletinImageSaveSession.firebase();
  bool _isPinned = false;
  bool _allowComments = true; // デフォルトでコメント許可
  bool _isCoupon = false; // クーポン投稿かどうか
  int? _couponMaxUses; // クーポン最大使用回数
  final _couponMaxUsesController = TextEditingController();
  bool _isLoading = false;
  bool _isPickingImages = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _images = BulletinImageDraft();
    // クーポンカテゴリが初期選択されている場合の処理
    _isCoupon = _selectedCategory.id == 'coupon';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorNameController.dispose();
    _externalUrlController.dispose();
    _couponMaxUsesController.dispose();
    _images.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: !_isLoading || _uploadProgress >= 1, child: Scaffold(
      appBar: AppBar(title: const Text('新しい投稿')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BulletinImagePicker(
              draft: _images,
              enabled: !_isLoading,
              onPickingChanged: (picking) => setState(() => _isPickingImages = picking),
            ),
            const SizedBox(height: 16),

            // タイトル
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                hintText: 'イベントやお知らせのタイトルを入力',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'タイトルを入力してください';
                }
                if (value.trim().length < 3) {
                  return 'タイトルは3文字以上で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 説明
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明',
                hintText: '詳細な内容を入力してください',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '説明を入力してください';
                }
                if (value.trim().length < 10) {
                  return '説明は10文字以上で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // カテゴリ選択
            _buildCategorySelector(),
            const SizedBox(height: 16),

            // クーポン設定（クーポンカテゴリ選択時のみ表示）
            if (_isCoupon) ...[
              _buildCouponSettings(),
              const SizedBox(height: 16),
            ],

            // 投稿者名
            TextFormField(
              controller: _authorNameController,
              decoration: const InputDecoration(
                labelText: '投稿者名',
                hintText: 'サークル名、団体名など',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '投稿者名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 外部リンク
            TextFormField(
              controller: _externalUrlController,
              decoration: const InputDecoration(
                labelText: '外部リンク（任意）',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                helperText: '関連するWebサイトのURLを入力してください',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null; // 任意なのでnullでOK
                }

                // URL形式のチェック
                final urlPattern = RegExp(
                  r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
                  caseSensitive: false,
                );
                if (!urlPattern.hasMatch(value.trim())) {
                  return '正しいURL形式で入力してください（例: https://example.com）';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 有効期限
            _buildExpirationPicker(),
            const SizedBox(height: 16),

            // ピン留め申請オプション
            Card(
              child: SwitchListTile(
                title: const Text('ピン留め申請'),
                subtitle: const Text('重要な投稿として上部固定表示を申請できます'),
                value: _isPinned,
                onChanged: (value) {
                  if (value) {
                    _requestPinPost(context);
                  } else {
                    setState(() {
                      _isPinned = false;
                    });
                  }
                },
                secondary: const Icon(Icons.push_pin_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // コメント許可オプション
            Card(
              child: SwitchListTile(
                title: const Text('コメントを許可'),
                subtitle: const Text('他のユーザーがコメントを投稿できるようになります'),
                value: _allowComments,
                onChanged: (value) {
                  setState(() {
                    _allowComments = value;
                  });
                },
                secondary: const Icon(Icons.comment),
              ),
            ),
            const SizedBox(height: 32),

            // 投稿ガイドライン
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '投稿ガイドライン',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• すべての投稿は管理者による承認が必要です\n'
                      '• 大学に関連する内容を投稿してください\n'
                      '• 不適切な内容や誹謗中傷は禁止です\n'
                      '• 画像は適切なサイズ（推奨: 16:9）を使用してください\n'
                      '• 個人情報の掲載にご注意ください\n'
                      '• 外部リンクは信頼できるサイトのみ掲載してください\n'
                      '• 承認まで1-2日程度お待ちください',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 投稿ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading || _isPickingImages ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: AppColors.onColor(Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value:
                                    _uploadProgress > 0
                                        ? _uploadProgress
                                        : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            if (_uploadStatus.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _uploadStatus,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        )
                        : const Text(
                          '投稿申請',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildCategorySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カテゴリ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final isAdmin = ref.watch(isAdminProvider);

                // カテゴリをフィルタリング
                List<BulletinCategory> availableCategories;

                if (isAdmin) {
                  // 管理者: すべてのカテゴリを表示（job と coupon を含む）
                  availableCategories = BulletinCategories.all;
                } else {
                  // 一般ユーザー: job と coupon を除外
                  availableCategories =
                      BulletinCategories.all
                          .where(
                            (category) =>
                                category.id != 'job' && category.id != 'coupon',
                          )
                          .toList();
                }

                // 現在選択されているカテゴリが利用不可能な場合、デフォルトに変更
                if (!availableCategories.any(
                  (cat) => cat.id == _selectedCategory.id,
                )) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedCategory = BulletinCategories.event;
                      _isCoupon = false;
                      _couponMaxUses = null;
                      _couponMaxUsesController.clear();
                    });
                  });
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      availableCategories.map((category) {
                        final isSelected = _selectedCategory.id == category.id;
                        final color = Color(
                          int.parse('0xff${category.color.substring(1)}'),
                        );

                        return FilterChip(
                          selected: isSelected,
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
                          avatar: Icon(
                            _getCategoryIcon(category.icon),
                            size: 18,
                            color: isSelected ? AppColors.onColor(color) : AppColors.accent(context, color),
                          ),
                          label: Text(category.name),
                          selectedColor: color,
                          checkmarkColor: AppColors.onColor(color),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.onColor(color) : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpirationPicker() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: const Text('有効期限'),
        subtitle: Text(
          _expiresAt != null
              ? '${_expiresAt!.year.toString().padLeft(4, '0')}/${_expiresAt!.month.toString().padLeft(2, '0')}/${_expiresAt!.day.toString().padLeft(2, '0')}まで'
              : '期限を設定（任意）',
        ),
        trailing:
            _expiresAt != null
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _expiresAt = null;
                    });
                  },
                )
                : const Icon(Icons.chevron_right),
        onTap: _pickExpirationDate,
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'event':
        return Icons.event;
      case 'group':
        return Icons.group;
      case 'school':
        return Icons.school;
      case 'announcement':
        return Icons.announcement;
      case 'work':
        return Icons.work;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'local_offer':
        return Icons.local_offer;
      default:
        return Icons.circle;
    }
  }

  // クーポン設定ウィジェット
  Widget _buildCouponSettings() {
    return Card(
      color: AppColors.tintedSurface(context, Colors.pink),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: AppColors.accent(context, Colors.pink.shade700)),
                const SizedBox(width: 8),
                Text(
                  'クーポン設定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent(context, Colors.pink.shade700),
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
                  _couponMaxUses =
                      value.trim().isNotEmpty
                          ? int.tryParse(value.trim())
                          : null;
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

  Future<void> _pickExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '有効期限を選択',
      cancelText: 'キャンセル',
      confirmText: '選択',
    );

    if (picked != null) {
      setState(() {
        _expiresAt = picked;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_isLoading || _isPickingImages) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadStatus = '投稿を準備中...';
    });

    try {
      print('🚀 投稿処理開始...');

      await _imageSave.save(
        draft: _images,
        persist: _saveBulletinPost,
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = done / total * 0.85;
              _uploadStatus = '画像をアップロード中 $done/$total枚';
            });
          }
        },
      );
      if (!mounted) return;

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = '完了!';
      });
      print('✅ 投稿処理完了');

      // 少し待ってから閉じる
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('投稿を申請しました。管理者の承認後に公開されます。'),
            backgroundColor: AppColors.snackBarSurface(context, Colors.blue),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ 投稿処理エラー: $e');
      print('スタックトレース: $stackTrace');

      String errorMessage = '投稿に失敗しました';
      final errorText = e.toString();
      if (errorText.contains('permission-denied')) {
        errorMessage = 'アクセス権限が不足しています';
      } else if (errorText.contains('network')) {
        errorMessage = 'ネットワークエラーが発生しました';
      } else if (errorText.contains('Firebase Storage') ||
          errorText.contains('画像のアップロード')) {
        errorMessage = '画像のアップロードに失敗しました';
      } else if (errorText.contains('unknown') ||
          errorText.contains('An unknown error')) {
        errorMessage = 'サーバーとの通信に失敗しました。接続を確認して再試行してください';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $e'),
            backgroundColor: AppColors.snackBarSurface(context, Colors.red),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '詳細',
              textColor: Theme.of(context).colorScheme.onInverseSurface,
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('エラー詳細'),
                        content: SingleChildScrollView(
                          child: Text('$e\n\n$stackTrace'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });
      }
    }
  }

  Future<void> _saveBulletinPost(SavedBulletinImages images) async {
    try {
      // 現在のユーザーIDを取得
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが認証されていません');
      }
      await user.getIdToken(true);

      final String postId = _postId;

      final BulletinPost post = BulletinPost(
        id: postId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: images.coverUrl,
        imageUrls: images.urls,
        thumbScale: images.crop.scale,
        thumbAlignX: images.crop.x,
        thumbAlignY: images.crop.y,
        externalUrl:
            _externalUrlController.text.trim().isNotEmpty
                ? _externalUrlController.text.trim()
                : null, // 外部リンク
        category: _selectedCategory,
        createdAt: _createdAt,
        expiresAt: _expiresAt,
        authorId: user.uid, // 実際のFirebase Auth ユーザーIDを使用
        authorName: _authorNameController.text.trim(),
        viewCount: 0,
        isPinned: false, // 直接的なピン留めは無効、申請のみ
        isActive: true,
        allowComments: _allowComments, // コメント許可フラグ
        pinRequested: _isPinned, // ピン留め申請フラグ
        pinRequestedAt: _isPinned ? DateTime.now() : null, // 申請日時
        approvalStatus: 'pending', // 承認待ち状態
        submittedAt: DateTime.now(), // 申請日時
        isCoupon: _isCoupon, // クーポン投稿フラグ
        couponMaxUses: _isCoupon ? _couponMaxUses : null, // クーポン最大使用回数
        couponUsedCount: 0, // 使用回数は0で初期化
        couponUsedBy: null, // 使用履歴は空で初期化
      );

      print('掲示板投稿を保存中...');
      print('投稿ID: $postId');
      print('タイトル: ${post.title}');

      await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(postId)
          .set(post.toJson());

      print('掲示板投稿が正常に保存されました');
    } catch (e) {
      print('Firestore保存エラー: $e');
      rethrow;
    }
  }

  // ピン留め申請ダイアログを表示
  void _requestPinPost(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.push_pin_outlined),
              SizedBox(width: 8),
              Text('ピン留め申請'),
            ],
          ),
          content: const Text(
            'この投稿をピン留め申請しますか？\n\n'
            'ピン留めは重要度の高いお知らせやイベント情報について管理者の審査の上、承認されます。\n\n'
            '申請後は投稿時に自動的にピン留め申請フラグが設定されます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isPinned = true; // 申請フラグを設定
                });
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                    content: Text('ピン留め申請が設定されました'),
                    backgroundColor: AppColors.snackBarSurface(context, Colors.blue),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: AppColors.onColor(Colors.blue),
              ),
              child: const Text('申請する'),
            ),
          ],
        );
      },
    );
  }
}

class _BulletinPostEditScreenState
    extends ConsumerState<BulletinPostEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _externalUrlController = TextEditingController();

  BulletinCategory _selectedCategory = BulletinCategories.event;
  DateTime? _expiresAt;
  late final BulletinImageDraft _images;
  final _imageSave = BulletinImageSaveSession.firebase();
  bool _isPinned = false;
  bool _allowComments = true; // デフォルトでコメント許可
  bool _isCoupon = false; // クーポン投稿かどうか
  int? _couponMaxUses; // クーポン最大使用回数
  final _couponMaxUsesController = TextEditingController();
  bool _isLoading = false;
  bool _isPickingImages = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final post = widget.post;
    _titleController.text = post.title;
    _descriptionController.text = post.description;
    _authorNameController.text = post.authorName;
    _externalUrlController.text = post.externalUrl ?? ''; // 外部リンクの初期化
    _selectedCategory = post.category;
    _expiresAt = post.expiresAt;
    _isPinned = false; // 編集時は常にfalseにして再申請可能にする
    _allowComments = post.allowComments; // コメント許可設定を初期化
    _images = BulletinImageDraft(post: post);
    _isCoupon = post.isCoupon; // クーポン設定を初期化
    _couponMaxUses = post.couponMaxUses; // クーポン最大使用回数を初期化
    _couponMaxUsesController.text =
        post.couponMaxUses?.toString() ?? ''; // クーポン使用回数フィールドを初期化
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorNameController.dispose();
    _externalUrlController.dispose();
    _couponMaxUsesController.dispose();
    _images.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: !_isLoading || _uploadProgress >= 1, child: Scaffold(
      appBar: AppBar(
        title: const Text('投稿を編集'),
        actions: [
          TextButton(
            onPressed: _isLoading || _isPickingImages ? null : _updatePost,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text(
                      '再申請',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BulletinImagePicker(
              draft: _images,
              enabled: !_isLoading,
              onPickingChanged: (picking) => setState(() => _isPickingImages = picking),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress),
              Text(_uploadStatus),
            ],
            const SizedBox(height: 16),

            // タイトル
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                hintText: 'イベントやお知らせのタイトルを入力',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'タイトルを入力してください';
                }
                if (value.trim().length < 3) {
                  return 'タイトルは3文字以上で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 説明
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明',
                hintText: '詳細な内容を入力してください',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '説明を入力してください';
                }
                if (value.trim().length < 10) {
                  return '説明は10文字以上で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // カテゴリ選択
            _buildCategorySelector(),
            const SizedBox(height: 16),

            // クーポン設定（クーポンカテゴリ選択時のみ表示）
            if (_isCoupon) ...[
              _buildCouponSettings(),
              const SizedBox(height: 16),
            ],

            // 投稿者名
            TextFormField(
              controller: _authorNameController,
              decoration: const InputDecoration(
                labelText: '投稿者名',
                hintText: 'サークル名、団体名など',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '投稿者名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 外部リンク
            TextFormField(
              controller: _externalUrlController,
              decoration: const InputDecoration(
                labelText: '外部リンク（任意）',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                helperText: '関連するWebサイトのURLを入力してください',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null; // 任意なのでnullでOK
                }

                // URL形式のチェック
                final urlPattern = RegExp(
                  r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
                  caseSensitive: false,
                );
                if (!urlPattern.hasMatch(value.trim())) {
                  return '正しいURL形式で入力してください（例: https://example.com）';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 有効期限
            _buildExpirationPicker(),
            const SizedBox(height: 16),

            // ピン留め申請オプション
            Card(
              child: SwitchListTile(
                title: const Text('ピン留め申請'),
                subtitle: const Text('重要な投稿として上部固定表示を申請できます'),
                value: _isPinned,
                onChanged: (value) {
                  if (value) {
                    _requestPinPost(context);
                  } else {
                    setState(() {
                      _isPinned = false;
                    });
                  }
                },
                secondary: const Icon(Icons.push_pin_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // コメント許可オプション
            Card(
              child: SwitchListTile(
                title: const Text('コメントを許可'),
                subtitle: const Text('他のユーザーがコメントを投稿できるようになります'),
                value: _allowComments,
                onChanged: (value) {
                  setState(() {
                    _allowComments = value;
                  });
                },
                secondary: const Icon(Icons.comment),
              ),
            ),
            const SizedBox(height: 32),

            // 編集ガイドライン
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '編集ガイドライン',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 投稿を編集すると再度管理者による承認が必要になります\n'
                      '• 編集中は投稿が一時的に非表示になります\n'
                      '• ピン留め申請も新たに申請が必要です\n'
                      '• 承認まで1-2日程度お待ちください\n'
                      '• 大学に関連する適切な内容にしてください',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildCategorySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カテゴリ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final isAdmin = ref.watch(isAdminProvider);

                // カテゴリをフィルタリング
                List<BulletinCategory> availableCategories;

                if (isAdmin) {
                  // 管理者: すべてのカテゴリを表示（job と coupon を含む）
                  availableCategories = BulletinCategories.all;
                } else {
                  // 一般ユーザー: job と coupon を除外
                  availableCategories =
                      BulletinCategories.all
                          .where(
                            (category) =>
                                category.id != 'job' && category.id != 'coupon',
                          )
                          .toList();
                }

                // 現在選択されているカテゴリが利用不可能な場合、デフォルトに変更
                if (!availableCategories.any(
                  (cat) => cat.id == _selectedCategory.id,
                )) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedCategory = BulletinCategories.event;
                      _isCoupon = false;
                      _couponMaxUses = null;
                      _couponMaxUsesController.clear();
                    });
                  });
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      availableCategories.map((category) {
                        final isSelected = _selectedCategory.id == category.id;
                        final color = Color(
                          int.parse('0xff${category.color.substring(1)}'),
                        );

                        return FilterChip(
                          selected: isSelected,
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
                          avatar: Icon(
                            _getCategoryIcon(category.icon),
                            size: 18,
                            color: isSelected ? AppColors.onColor(color) : AppColors.accent(context, color),
                          ),
                          label: Text(category.name),
                          selectedColor: color,
                          checkmarkColor: AppColors.onColor(color),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.onColor(color) : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpirationPicker() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: const Text('有効期限'),
        subtitle: Text(
          _expiresAt != null
              ? '${_expiresAt!.year.toString().padLeft(4, '0')}/${_expiresAt!.month.toString().padLeft(2, '0')}/${_expiresAt!.day.toString().padLeft(2, '0')}まで'
              : '期限を設定（任意）',
        ),
        trailing:
            _expiresAt != null
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _expiresAt = null;
                    });
                  },
                )
                : const Icon(Icons.chevron_right),
        onTap: _pickExpirationDate,
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'event':
        return Icons.event;
      case 'group':
        return Icons.group;
      case 'school':
        return Icons.school;
      case 'announcement':
        return Icons.announcement;
      case 'work':
        return Icons.work;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'local_offer':
        return Icons.local_offer;
      default:
        return Icons.circle;
    }
  }

  // クーポン設定ウィジェット
  Widget _buildCouponSettings() {
    return Card(
      color: AppColors.tintedSurface(context, Colors.pink),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: AppColors.accent(context, Colors.pink.shade700)),
                const SizedBox(width: 8),
                Text(
                  'クーポン設定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent(context, Colors.pink.shade700),
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
                  _couponMaxUses =
                      value.trim().isNotEmpty
                          ? int.tryParse(value.trim())
                          : null;
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

  Future<void> _pickExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '有効期限を選択',
      cancelText: 'キャンセル',
      confirmText: '選択',
    );

    if (picked != null) {
      setState(() {
        _expiresAt = picked;
      });
    }
  }

  Future<void> _updatePost() async {
    if (_isLoading || _isPickingImages) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadStatus = '更新を準備中...';
    });

    try {
      print('🔄 投稿更新処理開始...');

      await _imageSave.save(
        draft: _images,
        previousUrls: widget.post.galleryImageUrls,
        persist: _updateBulletinPost,
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = done / total * 0.85;
              _uploadStatus = '画像をアップロード中 $done/$total枚';
            });
          }
        },
      );
      if (!mounted) return;

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = '更新完了!';
      });
      print('✅ 投稿更新完了');

      // 少し待ってから閉じる
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('投稿を更新しました。管理者の再承認後に公開されます。'),
            backgroundColor: AppColors.snackBarSurface(context, Colors.blue),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ 投稿更新エラー: $e');
      print('スタックトレース: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新に失敗しました: $e'),
            backgroundColor: AppColors.snackBarSurface(context, Colors.red),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });
      }
    }
  }

  Future<void> _updateBulletinPost(SavedBulletinImages images) async {
    try {
      final updatedPost = BulletinPost(
        id: widget.post.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: images.coverUrl,
        imageUrls: images.urls,
        thumbScale: images.crop.scale,
        thumbAlignX: images.crop.x,
        thumbAlignY: images.crop.y,
        externalUrl:
            _externalUrlController.text.trim().isNotEmpty
                ? _externalUrlController.text.trim()
                : null, // 外部リンク
        category: _selectedCategory,
        createdAt: widget.post.createdAt, // 作成日は変更しない
        expiresAt: _expiresAt,
        authorId: widget.post.authorId, // 投稿者IDは変更しない
        authorName: _authorNameController.text.trim(),
        viewCount: widget.post.viewCount, // 閲覧数は変更しない
        isPinned: widget.post.isPinned, // 既存のピン留め状態は保持
        isActive: widget.post.isActive, // アクティブ状態は変更しない
        allowComments: _allowComments, // コメント許可設定を更新
        pinRequested: _isPinned, // ピン留め申請フラグ
        pinRequestedAt: _isPinned ? DateTime.now() : null, // 申請日時
        approvalStatus: 'pending', // 編集時は再審査のため承認待ちに戻す
        submittedAt: DateTime.now(), // 再申請日時を更新
        isCoupon: _isCoupon, // クーポン投稿フラグ
        couponMaxUses: _isCoupon ? _couponMaxUses : null, // クーポン最大使用回数
        couponUsedCount: widget.post.couponUsedCount, // 既存の使用回数を保持
        couponUsedBy: widget.post.couponUsedBy, // 既存の使用履歴を保持
      );

      print('投稿を更新中...');
      print('投稿ID: ${widget.post.id}');
      print('タイトル: ${updatedPost.title}');

      await FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc(widget.post.id)
          .update(updatedPost.toJson()..removeWhere((key, _) => const {
            'id', 'authorId', 'createdAt', 'viewCount', 'isPinned',
            'isSponsored', 'sponsorName', 'couponUsedCount', 'couponUsedBy',
          }.contains(key)));

      print('投稿が正常に更新されました');
    } catch (e) {
      print('Firestore更新エラー: $e');
      rethrow;
    }
  }

  // ピン留め申請ダイアログを表示
  void _requestPinPost(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.push_pin_outlined),
              SizedBox(width: 8),
              Text('ピン留め申請'),
            ],
          ),
          content: const Text(
            'この投稿をピン留め申請しますか？\n\n'
            'ピン留めは重要度の高いお知らせやイベント情報について管理者の審査の上、承認されます。\n\n'
            '申請後は投稿時に自動的にピン留め申請フラグが設定されます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isPinned = true; // 申請フラグを設定
                });
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                    content: Text('ピン留め申請が設定されました'),
                    backgroundColor: AppColors.snackBarSurface(context, Colors.blue),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: AppColors.onColor(Colors.blue),
              ),
              child: const Text('申請する'),
            ),
          ],
        );
      },
    );
  }
}
