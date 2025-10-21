import 'dart:io';
import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/firebase_menu_provider.dart';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import '../../services/cafeteria/cafeteria_menu_item_service.dart';
import 'cafeteria_review_form_screen.dart';

String? _campusCodeFromCafeteriaId(String cafeteriaId) {
  switch (cafeteriaId) {
    case Cafeterias.tsudanuma:
      return 'td';
    case Cafeterias.narashino1F:
      return 'sd1';
    case Cafeterias.narashino2F:
      return 'sd2';
    default:
      return null;
  }
}

class _FullScreenMenuImagePage extends StatelessWidget {
  const _FullScreenMenuImagePage({
    required this.imageUrl,
    required this.placeholder,
  });

  final String imageUrl;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          placeholder,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.redAccent, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'メニュー画像を表示できませんでした\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CafeteriaMenuItemFormScreen extends ConsumerStatefulWidget {
  const CafeteriaMenuItemFormScreen({
    super.key,
    required this.cafeteriaId,
  });
  
  final String cafeteriaId;

  @override
  ConsumerState<CafeteriaMenuItemFormScreen> createState() => _CafeteriaMenuItemFormScreenState();
}

class _CafeteriaMenuItemFormScreenState extends ConsumerState<CafeteriaMenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _menuNameController = TextEditingController();
  final _priceController = TextEditingController();
  
  File? _selectedImage;
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _menuNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final menuName = _menuNameController.text.trim();
    if (menuName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メニュー名を入力してください')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 重複チェック
      final isDuplicate = await CafeteriaMenuItemService.checkDuplicate(
        widget.cafeteriaId,
        menuName,
      );
      
      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('同じ名前のメニューが既に存在します')),
          );
        }
        return;
      }

      // 画像をFirebase Storageにアップロード
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await CafeteriaMenuItemService.uploadImage(
          _selectedImage!,
          widget.cafeteriaId,
          menuName,
        );
      }

      // 価格をパース
      final priceText = _priceController.text.trim();
      int? price;
      if (priceText.isNotEmpty) {
        price = int.tryParse(priceText);
        if (price == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('価格は数字で入力してください')),
            );
          }
          return;
        }
      }

      // メニューアイテムを作成
      final menuItem = CafeteriaMenuItem(
        id: '',
        cafeteriaId: widget.cafeteriaId,
        menuName: menuName,
        price: price,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await CafeteriaMenuItemService.addMenuItem(menuItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メニューを追加しました')),
        );
        
        // メニュー追加後にレビュー画面に遷移
        final shouldNavigateToReview = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('レビューを書く'),
            content: Text('「$menuName」のレビューを書きますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('後で'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('レビューを書く'),
              ),
            ],
          ),
        );

        if (shouldNavigateToReview == true && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CafeteriaReviewFormScreen(
                initialCafeteriaId: widget.cafeteriaId,
                initialMenuName: menuName,
                fixed: true,
              ),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showCampusMenuImage(String campusCode, String campusName) async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final imageUrl = await ref.read(firebaseTodayMenuProvider(campusCode).future);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (imageUrl == null || imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$campusNameのメニュー画像が見つかりませんでした')),
        );
        return;
      }

      final placeholder =
          campusName.characters.isNotEmpty ? campusName.characters.first : campusName;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => _FullScreenMenuImagePage(
                imageUrl: imageUrl,
                placeholder: placeholder,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メニュー画像の取得に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final campusName = Cafeterias.displayName(widget.cafeteriaId);
    final campusCode = _campusCodeFromCafeteriaId(widget.cafeteriaId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buttonColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('メニューを追加'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '食堂: $campusName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (campusCode != null)
                    TextButton.icon(
                      icon: Icon(
                        Icons.photo_library_outlined,
                        size: 18,
                        color: buttonColor,
                      ),
                      label: Text(
                        'メニューを確認',
                        style: TextStyle(fontSize: 12, color: buttonColor),
                      ),
                      onPressed: () => _showCampusMenuImage(campusCode, campusName),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _menuNameController,
                decoration: const InputDecoration(
                  labelText: 'メニュー名 *(なるべくメニュー表通りの名前でご登録ください)',
                  hintText: '例: 唐揚げ定食、カレーライス',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'メニュー名は必須です';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: '価格（任意）',
                  hintText: '例: 500',
                  border: OutlineInputBorder(),
                  suffixText: '円',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (int.tryParse(value.trim()) == null) {
                      return '価格は数字で入力してください';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              const Text(
                '写真（任意）',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'タップして写真を選択',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isSubmitting ? '追加中...' : 'メニューを追加'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
