import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/cafeteria/cafeteria_menu_item_model.dart';
import '../../models/cafeteria/cafeteria_review_model.dart';
import '../../services/cafeteria/cafeteria_menu_item_service.dart';
import 'cafeteria_review_form_screen.dart';

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

  @override
  Widget build(BuildContext context) {
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
              Text(
                '食堂: ${Cafeterias.displayName(widget.cafeteriaId)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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