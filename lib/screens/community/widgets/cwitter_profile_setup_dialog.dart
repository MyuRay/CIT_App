import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/community/cwitter_service.dart';

/// Cwitter ID 初回設定後に表示するプロフィール設定ダイアログ
class CwitterProfileSetupDialog {
  CwitterProfileSetupDialog._();

  static Future<void> show(
    BuildContext context, {
    required String uid,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CwitterProfileSetupDialogBody(uid: uid),
    );
  }
}

class _CwitterProfileSetupDialogBody extends StatefulWidget {
  const _CwitterProfileSetupDialogBody({required this.uid});

  final String uid;

  @override
  State<_CwitterProfileSetupDialogBody> createState() =>
      _CwitterProfileSetupDialogBodyState();
}

class _CwitterProfileSetupDialogBodyState
    extends State<_CwitterProfileSetupDialogBody> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _tag1Controller = TextEditingController();
  final _tag2Controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _bioController.dispose();
    _tag1Controller.dispose();
    _tag2Controller.dispose();
    super.dispose();
  }

  String? _validateTag(String? value, {bool optional = false}) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return optional ? null : '1つ目のハッシュタグを入力してください';
    }
    final normalized =
        trimmed.startsWith('#') ? trimmed.substring(1).trim() : trimmed;
    if (!AppConstants.isValidCwitterTag(normalized)) {
      return AppConstants.errorCwitterTagFormat;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final bio = _bioController.text.trim();
    final tag1 = _tag1Controller.text.trim();
    final tag2 = _tag2Controller.text.trim();

    setState(() => _isSaving = true);
    try {
      if (bio.isNotEmpty) {
        await CwitterService.updateCwitterBio(uid: widget.uid, bio: bio);
      }
      if (tag1.isNotEmpty || tag2.isNotEmpty) {
        await CwitterService.updateCwitterTags(
          uid: widget.uid,
          tags: [tag1, tag2],
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールを保存しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.person_outline,
        color: theme.colorScheme.primary,
        size: 32,
      ),
      title: const Text('プロフィールを設定しましょう'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '自己紹介とハッシュタグを設定すると、'
                '他のユーザーに自分を伝えやすくなります。',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                minLines: 3,
                maxLength: AppConstants.cwitterBioMaxLength,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: '自己紹介',
                  hintText: '例: 27卒・建築学科です。サークル募集中！',
                  helperText: AppConstants.cwitterBioInputHelper,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final length = (value ?? '').trim().length;
                  if (length > AppConstants.cwitterBioMaxLength) {
                    return '${AppConstants.cwitterBioMaxLength}文字以内で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tag1Controller,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'ハッシュタグ 1',
                  hintText: '例: 27卒',
                  helperText: AppConstants.cwitterTagsInputHelper,
                  border: OutlineInputBorder(),
                  prefixText: '#',
                ),
                validator: (value) {
                  final tag2 = _tag2Controller.text.trim();
                  if ((value ?? '').trim().isEmpty && tag2.isNotEmpty) {
                    return '1つ目のハッシュタグを入力してください';
                  }
                  if ((value ?? '').trim().isEmpty) return null;
                  return _validateTag(value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tag2Controller,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'ハッシュタグ 2（任意）',
                  hintText: '例: 建築',
                  border: OutlineInputBorder(),
                  prefixText: '#',
                ),
                validator: (value) => _validateTag(value, optional: true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('あとで'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
