import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  
  const BulletinPostEditScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<BulletinPostEditScreen> createState() =>
      _BulletinPostEditScreenState();
}

class _BulletinPostFormScreenState
    extends ConsumerState<BulletinPostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _externalUrlController = TextEditingController();

  BulletinCategory _selectedCategory = BulletinCategories.event;
  DateTime? _expiresAt;
  File? _selectedImage;
  bool _isPinned = false;
  bool _allowComments = true; // デフォルトでコメント許可
  bool _isCoupon = false; // クーポン投稿かどうか
  int? _couponMaxUses; // クーポン最大使用回数
  final _couponMaxUsesController = TextEditingController();
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  // サムネイル位置（-1.0〜1.0）
  double _thumbAlignX = 0.0;
  double _thumbAlignY = 0.0;
  // 16:9サムネイルの表示位置（-1.0〜1.0）
  // double _thumbAlignX = 0.0; // duplicate removed
  // double _thumbAlignY = 0.0; // duplicate removed

  @override
  void initState() {
    super.initState();
    // クーポンカテゴリが初期選択されている場合の処理
    _isCoupon = _selectedCategory.id == 'coupon';
  }

  void _openThumbnailEditor(ImageProvider imageProvider) {
    double x = _thumbAlignX;
    double y = _thumbAlignY;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('サムネイル位置（16:9）'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        alignment: Alignment(x, y),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('水平'),
                      Expanded(
                        child: Slider(
                          min: -1.0,
                          max: 1.0,
                          value: x,
                          onChanged: (v) => setLocal(() => x = v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('垂直'),
                      Expanded(
                        child: Slider(
                          min: -1.0,
                          max: 1.0,
                          value: y,
                          onChanged: (v) => setLocal(() => y = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () => setLocal(() { x = 0; y = 0; }),
                  child: const Text('リセット'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() { _thumbAlignX = x; _thumbAlignY = y; });
                    Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorNameController.dispose();
    _externalUrlController.dispose();
    _couponMaxUsesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新しい投稿'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 画像選択
            _buildImagePicker(),
            const SizedBox(height: 12),
            if (_selectedImage != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('サムネイル（16:9）'),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _InteractiveThumb(
                            image: Image.file(_selectedImage!).image,
                            alignX: _thumbAlignX,
                            alignY: _thumbAlignY,
                            onAlignChanged: (ax, ay) {
                              setState(() { _thumbAlignX = ax; _thumbAlignY = ay; });
                            },
                            showGuides: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

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
                onPressed: _isLoading ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: _uploadProgress > 0 ? _uploadProgress : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                          ]
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
    );
  }

  Widget _buildImagePicker() {
    return Card(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment(_thumbAlignX, _thumbAlignY),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                          ),
                        ),
                       ),
                      // 位置調整ボタンは廃止（ドラッグ操作に統一）
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '画像を選択（任意）',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'タップして画像を追加してください（省略可能）',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer(builder: (context, ref, child) {
              final isAdmin = ref.watch(isAdminProvider);
              
              // カテゴリをフィルタリング
              List<BulletinCategory> availableCategories;
              
              if (isAdmin) {
                // 管理者: すべてのカテゴリを表示（job と coupon を含む）
                availableCategories = BulletinCategories.all;
              } else {
                // 一般ユーザー: job と coupon を除外
                availableCategories = BulletinCategories.all
                    .where((category) => category.id != 'job' && category.id != 'coupon')
                    .toList();
              }
              
              // 現在選択されているカテゴリが利用不可能な場合、デフォルトに変更
              if (!availableCategories.any((cat) => cat.id == _selectedCategory.id)) {
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
                children: availableCategories.map((category) {
                  final isSelected = _selectedCategory.id == category.id;
                  final color = Color(int.parse('0xff${category.color.substring(1)}'));

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
                      color: isSelected ? Colors.white : color,
                    ),
                    label: Text(category.name),
                    selectedColor: color,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              );
            }),
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
        trailing: _expiresAt != null
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('カメラで撮影'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  print('📷 カメラで画像を撮影中...');
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    // 制限を緩和: より高解像度・高品質で取得
                    maxWidth: 2048,
                    maxHeight: 2048,
                    imageQuality: 90,
                  );
                  if (image != null) {
                    print('✅ カメラ撮影成功: ${image.path}');
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  } else {
                    print('カメラ撮影がキャンセルされました');
                  }
                } catch (e) {
                  print('❌ カメラアクセスエラー: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('カメラにアクセスできません: $e'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  print('📁 ギャラリーから画像を選択中...');
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    // 制限を緩和: より高解像度・高品質で取得
                    maxWidth: 2048,
                    maxHeight: 2048,
                    imageQuality: 90,
                  );
                  if (image != null) {
                    print('✅ ギャラリー選択成功: ${image.path}');
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  } else {
                    print('ギャラリー選択がキャンセルされました');
                  }
                } catch (e) {
                  print('❌ ギャラリーアクセスエラー: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ギャラリーにアクセスできません: $e'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
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
      
      // 画像をFirebase Storageにアップロード（画像がある場合のみ）
      String? imageUrl;
      if (_selectedImage != null) {
        setState(() {
          _uploadStatus = '画像をアップロード中...';
        });
        print('画像ファイルが選択されています。アップロード開始...');
        imageUrl = await _uploadImage();
        print('画像アップロード完了: $imageUrl');
      } else {
        print('画像なしの投稿です');
      }

      // 投稿をFirestoreに保存
      setState(() {
        _uploadProgress = 0.9;
        _uploadStatus = '投稿を保存中...';
      });
      print('Firestoreに投稿を保存中...');
      await _saveBulletinPost(imageUrl);
      
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
          const SnackBar(
            content: Text('投稿申請が完了しました！管理者の承認をお待ちください。'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ 投稿処理エラー: $e');
      print('スタックトレース: $stackTrace');
      
      String errorMessage = '投稿に失敗しました';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'アクセス権限が不足しています';
      } else if (e.toString().contains('network')) {
        errorMessage = 'ネットワークエラーが発生しました';
      } else if (e.toString().contains('Firebase Storage')) {
        errorMessage = '画像のアップロードに失敗しました';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '詳細',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
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

  Future<String> _uploadImage() async {
    try {
      print('📤 画像アップロード開始...');
      final String fileName =
          'bulletin_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref =
          FirebaseStorage.instance.ref().child('bulletin_images/$fileName');

      final fileSize = await _selectedImage!.length();
      print('アップロード先: ${ref.fullPath}');
      print('画像ファイル: ${_selectedImage!.path}');
      print('ファイルサイズ: ${(fileSize / 1024).toStringAsFixed(1)} KB');

      // Firebase Storageのタイムアウト設定を最適化
      final storage = FirebaseStorage.instance;
      storage.setMaxUploadRetryTime(const Duration(minutes: 2));
      
      // メタデータを追加してキャッシュ最適化
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=31536000', // 1年キャッシュ
        customMetadata: {
          'uploaded_by': 'bulletin_app',
          'upload_time': DateTime.now().toIso8601String(),
        },
      );

      final UploadTask uploadTask = ref.putFile(_selectedImage!, metadata);
      
      // アップロード進行状況をUIに反映
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        final percentage = (progress * 100).toStringAsFixed(1);
        print('進行状況: $percentage%');
        
        if (mounted) {
          setState(() {
            _uploadProgress = progress * 0.8; // 80%までをアップロード、残り20%をFirestore保存に割り当て
            _uploadStatus = 'アップロード中... $percentage%';
          });
        }
      });
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (mounted) {
        setState(() {
          _uploadProgress = 0.8;
          _uploadStatus = 'アップロード完了!';
        });
      }
      
      print('✅ 画像アップロード成功');
      print('ダウンロードURL: $downloadUrl');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      print('❌ 画像アップロードエラー: $e');
      print('スタックトレース: $stackTrace');
      
      if (e.toString().contains('permission-denied')) {
        throw 'Firebase Storage の権限が不足しています。管理者にお問い合わせください。';
      } else if (e.toString().contains('network')) {
        throw 'ネットワークエラーが発生しました。接続を確認してください。';
      } else if (e.toString().contains('quota-exceeded')) {
        throw 'ストレージ容量が上限に達しています。';
      }
      
      rethrow;
    }
  }

  Future<void> _saveBulletinPost(String? imageUrl) async {
    try {
      // 現在のユーザーIDを取得
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final String postId = FirebaseFirestore.instance
          .collection('bulletin_posts')
          .doc()
          .id;

      final BulletinPost post = BulletinPost(
        id: postId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl ?? '', // 画像がない場合は空文字
        thumbAlignX: _thumbAlignX,
        thumbAlignY: _thumbAlignY,
        externalUrl: _externalUrlController.text.trim().isNotEmpty 
            ? _externalUrlController.text.trim() 
            : null, // 外部リンク
        category: _selectedCategory,
        createdAt: DateTime.now(),
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
                  const SnackBar(
                    content: Text('ピン留め申請が設定されました'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('申請する'),
            ),
          ],
        );
      },
    );
  }
}

class _InteractiveThumb extends StatefulWidget {
  final ImageProvider image;
  final double alignX;
  final double alignY;
  final bool showGuides;
  final void Function(double ax, double ay) onAlignChanged;

  const _InteractiveThumb({
    required this.image,
    required this.alignX,
    required this.alignY,
    required this.onAlignChanged,
    this.showGuides = true,
  });

  @override
  State<_InteractiveThumb> createState() => _InteractiveThumbState();
}

class _InteractiveThumbState extends State<_InteractiveThumb> {
  late double ax;
  late double ay;

  @override
  void initState() {
    super.initState();
    ax = widget.alignX;
    ay = widget.alignY;
  }

  @override
  void didUpdateWidget(covariant _InteractiveThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    ax = widget.alignX;
    ay = widget.alignY;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return GestureDetector(
          onPanUpdate: (details) {
            // ドラッグ量をアライメントに変換（[-1,1]に正規化）
            final dx = details.delta.dx;
            final dy = details.delta.dy;
            double nextX = (ax - (dx / (w / 2))).clamp(-1.0, 1.0);
            double nextY = (ay - (dy / (h / 2))).clamp(-1.0, 1.0);
            setState(() { ax = nextX; ay = nextY; });
            widget.onAlignChanged(nextX, nextY);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: widget.image,
                fit: BoxFit.cover,
                alignment: Alignment(ax, ay),
              ),
              if (widget.showGuides)
                CustomPaint(
                  painter: _ThumbGuidesPainter(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ThumbGuidesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // 外枠
    canvas.drawRect(Offset.zero & size, border);

    // 三分割ガイド線（rule of thirds）
    final guide = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dx = size.width / 3;
    final dy = size.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(dx * i, 0), Offset(dx * i, size.height), guide);
      canvas.drawLine(Offset(0, dy * i), Offset(size.width, dy * i), guide);
    }

    // セーフマージン（5%）
    final margin = Paint()
      ..color = const Color(0x22FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final m = 0.05;
    final rect = Rect.fromLTWH(size.width * m, size.height * m, size.width * (1 - 2 * m), size.height * (1 - 2 * m));
    canvas.drawRect(rect, margin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BulletinPostEditScreenState extends ConsumerState<BulletinPostEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _externalUrlController = TextEditingController();

  BulletinCategory _selectedCategory = BulletinCategories.event;
  DateTime? _expiresAt;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isPinned = false;
  bool _allowComments = true; // デフォルトでコメント許可
  bool _isCoupon = false; // クーポン投稿かどうか
  int? _couponMaxUses; // クーポン最大使用回数
  final _couponMaxUsesController = TextEditingController();
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  // 16:9サムネイルの表示位置（-1.0〜1.0）
  double _thumbAlignX = 0.0;
  double _thumbAlignY = 0.0;

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
    _existingImageUrl = post.imageUrl.isNotEmpty ? post.imageUrl : null;
    // サムネ初期位置（編集）
    _thumbAlignX = post.thumbAlignX;
    _thumbAlignY = post.thumbAlignY;
    _isCoupon = post.isCoupon; // クーポン設定を初期化
    _couponMaxUses = post.couponMaxUses; // クーポン最大使用回数を初期化
    _couponMaxUsesController.text = post.couponMaxUses?.toString() ?? ''; // クーポン使用回数フィールドを初期化
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorNameController.dispose();
    _externalUrlController.dispose();
    _couponMaxUsesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿を編集'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updatePost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('再申請', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 画像選択
            _buildImagePicker(),
            const SizedBox(height: 12),
            if (_selectedImage != null || _existingImageUrl != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('サムネイル（16:9）'),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _InteractiveThumb(
                            image: (_selectedImage != null)
                                ? Image.file(_selectedImage!).image
                                : Image.network(_existingImageUrl!).image,
                            alignX: _thumbAlignX,
                            alignY: _thumbAlignY,
                            onAlignChanged: (ax, ay) {
                              setState(() { _thumbAlignX = ax; _thumbAlignY = ay; });
                            },
                            showGuides: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

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
    );
  }

  Widget _buildImagePicker() {
    return Card(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _selectedImage != null
              ? _buildSelectedImageWidget()
              : _existingImageUrl != null 
                ? _buildExistingImageWidget()
                : _buildPlaceholderWidget(),
        ),
      ),
    );
  }

  Widget _buildSelectedImageWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.file(
            _selectedImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            alignment: Alignment(_thumbAlignX, _thumbAlignY),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '新しい画像',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingImageWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.network(
            _existingImageUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            alignment: Alignment(_thumbAlignX, _thumbAlignY),
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderWidget(),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _existingImageUrl = null;
                  });
                },
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '現在の画像',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          '画像を選択（任意）',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'タップして画像を変更してください',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer(builder: (context, ref, child) {
              final isAdmin = ref.watch(isAdminProvider);
              
              // カテゴリをフィルタリング
              List<BulletinCategory> availableCategories;
              
              if (isAdmin) {
                // 管理者: すべてのカテゴリを表示（job と coupon を含む）
                availableCategories = BulletinCategories.all;
              } else {
                // 一般ユーザー: job と coupon を除外
                availableCategories = BulletinCategories.all
                    .where((category) => category.id != 'job' && category.id != 'coupon')
                    .toList();
              }
              
              // 現在選択されているカテゴリが利用不可能な場合、デフォルトに変更
              if (!availableCategories.any((cat) => cat.id == _selectedCategory.id)) {
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
                children: availableCategories.map((category) {
                  final isSelected = _selectedCategory.id == category.id;
                  final color = Color(int.parse('0xff${category.color.substring(1)}'));

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
                      color: isSelected ? Colors.white : color,
                    ),
                    label: Text(category.name),
                    selectedColor: color,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              );
            }),
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
        trailing: _expiresAt != null
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('カメラで撮影'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  print('📷 カメラで画像を撮影中...');
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    // 制限を緩和: より高解像度・高品質で取得
                    maxWidth: 2048,
                    maxHeight: 2048,
                    imageQuality: 90,
                  );
                  if (image != null) {
                    print('✅ カメラ撮影成功: ${image.path}');
                    setState(() {
                      _selectedImage = File(image.path);
                      _existingImageUrl = null; // 新しい画像が選択されたら既存画像をクリア
                    });
                  }
                } catch (e) {
                  print('❌ カメラアクセスエラー: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('カメラにアクセスできません: $e'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  print('📁 ギャラリーから画像を選択中...');
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    // 制限を緩和: より高解像度・高品質で取得
                    maxWidth: 2048,
                    maxHeight: 2048,
                    imageQuality: 90,
                  );
                  if (image != null) {
                    print('✅ ギャラリー選択成功: ${image.path}');
                    setState(() {
                      _selectedImage = File(image.path);
                      _existingImageUrl = null; // 新しい画像が選択されたら既存画像をクリア
                    });
                  }
                } catch (e) {
                  print('❌ ギャラリーアクセスエラー: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ギャラリーにアクセスできません: $e'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
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
      
      // 画像処理
      String? imageUrl = _existingImageUrl;
      
      if (_selectedImage != null) {
        print('📤 新しい画像をアップロード中...');
        // 既存の画像を削除
        if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
          try {
            final oldRef = FirebaseStorage.instance.refFromURL(_existingImageUrl!);
            await oldRef.delete();
            print('🗑️ 既存画像を削除: ${oldRef.fullPath}');
          } catch (e) {
            print('⚠️ 既存画像削除エラー (続行): $e');
          }
        }
        
        // 新しい画像をアップロード
        imageUrl = await _uploadImage();
        print('✅ 新しい画像アップロード完了: $imageUrl');
      } else if (_existingImageUrl == null && widget.post.imageUrl.isNotEmpty) {
        // 画像が削除された場合
        print('🗑️ 画像を削除...');
        try {
          final oldRef = FirebaseStorage.instance.refFromURL(widget.post.imageUrl);
          await oldRef.delete();
          print('✅ 既存画像を削除: ${oldRef.fullPath}');
        } catch (e) {
          print('⚠️ 既存画像削除エラー (続行): $e');
        }
        imageUrl = '';
      }

      // 投稿をFirestoreで更新
      setState(() {
        _uploadProgress = 0.9;
        _uploadStatus = '投稿を保存中...';
      });
      print('📝 Firestoreで投稿を更新中...');
      await _updateBulletinPost(imageUrl ?? '');
      
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
          const SnackBar(
            content: Text('投稿を更新しました！再度管理者の承認をお待ちください。'),
            backgroundColor: Colors.blue,
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
            backgroundColor: Colors.red,
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

  Future<String> _uploadImage() async {
    try {
      print('📤 画像アップロード開始(編集)...');
      final String fileName =
          'bulletin_edit_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref =
          FirebaseStorage.instance.ref().child('bulletin_images/$fileName');

      final fileSize = await _selectedImage!.length();
      print('アップロード先: ${ref.fullPath}');
      print('画像ファイル: ${_selectedImage!.path}');
      print('ファイルサイズ: ${(fileSize / 1024).toStringAsFixed(1)} KB');

      // 最適化されたメタデータ
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=31536000',
        customMetadata: {
          'uploaded_by': 'bulletin_edit',
          'upload_time': DateTime.now().toIso8601String(),
        },
      );

      final UploadTask uploadTask = ref.putFile(_selectedImage!, metadata);
      
      // 進行状況監視
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        final percentage = (progress * 100).toStringAsFixed(1);
        
        if (mounted) {
          setState(() {
            _uploadProgress = progress * 0.8;
            _uploadStatus = 'アップロード中... $percentage%';
          });
        }
      });
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (mounted) {
        setState(() {
          _uploadProgress = 0.8;
          _uploadStatus = 'アップロード完了!';
        });
      }
      
      print('✅ 画像アップロード成功: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ 画像アップロードエラー: $e');
      rethrow;
    }
  }

  Future<void> _updateBulletinPost(String imageUrl) async {
    try {
      final updatedPost = BulletinPost(
        id: widget.post.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        thumbAlignX: _thumbAlignX,
        thumbAlignY: _thumbAlignY,
        externalUrl: _externalUrlController.text.trim().isNotEmpty 
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
          .set(updatedPost.toJson());
          
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
                  const SnackBar(
                    content: Text('ピン留め申請が設定されました'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('申請する'),
            ),
          ],
        );
      },
    );
  }
}
