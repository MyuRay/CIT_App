import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/contact_provider.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({super.key});

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  // 名前・メールは不要のため入力欄を表示しない（匿名でも送信可）
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void dispose() {
    // 名前・メールのコントローラは使用しないため解放不要
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お問い合わせ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 説明カード
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'お問い合わせについて',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ご質問やご要望、不具合の報告などがございましたら、以下のフォームよりお気軽にお問い合わせください。',
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 名前・メールの入力欄は非表示
            // 匿名での送信に対応
            
            // カテゴリ選択
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'お問い合わせ種別 *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              value: _selectedCategory,
              items: ContactCategories.categories.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Text(ContactCategories.getIcon(entry.key), style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'お問い合わせ種別を選択してください';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // 件名
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: '件名 *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '件名を入力してください';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // お問い合わせ内容
            TextFormField(
              controller: _messageController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'お問い合わせ内容 *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
                alignLabelWithHint: true,
                hintText: 'お問い合わせ内容を詳しくご記入ください...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'お問い合わせ内容を入力してください';
                }
                if (value.trim().length < 10) {
                  return 'お問い合わせ内容は10文字以上で入力してください';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // 送信ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '送信',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 注意事項
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'ご注意',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• お問い合わせの内容によっては回答までお時間をいただく場合があります\n'
                      '• 緊急の場合は直接担当者までご連絡ください\n'
                      '• 個人情報は適切に管理し、本件以外の目的では使用いたしません',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(contactActionsProvider).createContact(
        name: null,
        email: null,
        category: _selectedCategory!,
        categoryName: ContactCategories.getDisplayName(_selectedCategory!),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (mounted) {
        // 成功ダイアログを表示
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text('送信完了'),
              ],
            ),
            content: const Text('お問い合わせを送信しました。\n担当者から返信をお待ちください。'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ダイアログを閉じる
                  context.pop(); // フォーム画面を閉じる
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
