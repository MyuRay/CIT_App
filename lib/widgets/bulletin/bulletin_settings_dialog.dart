import 'package:flutter/material.dart';
import '../../models/bulletin/bulletin_model.dart';
import '../ads/sponsor_presentation.dart';

typedef SaveBulletinSettings =
    Future<void> Function({
      required bool isSponsored,
      required String sponsorName,
      required bool isActive,
      required bool isPinned,
      required bool allowComments,
      required DateTime? expiresAt,
    });

class BulletinSettingsDialog extends StatefulWidget {
  const BulletinSettingsDialog({
    super.key,
    required this.post,
    required this.onSave,
  });
  final BulletinPost post;
  final SaveBulletinSettings onSave;

  @override
  State<BulletinSettingsDialog> createState() => _BulletinSettingsDialogState();
}

class _BulletinSettingsDialogState extends State<BulletinSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.post.sponsorName);
  late bool _sponsored = widget.post.isSponsored;
  late bool _active = widget.post.isActive;
  late bool _pinned = widget.post.isPinned;
  late bool _comments = widget.post.allowComments;
  late DateTime? _expiry = widget.post.expiresAt;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final expiry = _expiry?.toLocal();
    final initial =
        expiry == null
            ? now.add(const Duration(days: 30))
            : expiry == DateTime(expiry.year, expiry.month, expiry.day)
            ? expiry.subtract(const Duration(microseconds: 1))
            : expiry;
    final selected = await showDatePicker(
      context: context,
      helpText: '最後に掲載する日',
      initialDate: initial,
      firstDate: DateTime(initial.year < now.year ? initial.year : now.year),
      lastDate: DateTime(
        (initial.year > now.year ? initial.year : now.year) + 10,
      ),
    );
    if (selected != null && mounted) {
      // Inclusive selected day: expire at the following local midnight.
      setState(
        () =>
            _expiry = DateTime(selected.year, selected.month, selected.day + 1),
      );
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        isSponsored: _sponsored,
        sponsorName: _name.text.trim(),
        isActive: _active,
        isPinned: _pinned,
        allowComments: _comments,
        expiresAt: _expiry,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = '保存できませんでした。通信状態と管理者権限を確認し、再試行してください。';
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('掲載設定'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.post.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SponsorFields(
                  enabled: _sponsored,
                  nameController: _name,
                  readOnly: _saving,
                  onChanged: (value) => setState(() => _sponsored = value),
                  onNameChanged: (_) => setState(() {}),
                ),
                if (_sponsored) ...[
                  const Text('表示プレビュー'),
                  const SizedBox(height: 8),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: SponsorPalette.of(context).border,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SponsorBanner(name: _name.text),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(widget.post.title),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('掲載を有効にする'),
                  subtitle: const Text('承認済み・掲載期限内の投稿が公開されます'),
                  value: _active,
                  onChanged:
                      _saving ? null : (v) => setState(() => _active = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ピン留め'),
                  value: _pinned,
                  onChanged:
                      _saving ? null : (v) => setState(() => _pinned = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('コメントを許可'),
                  value: _comments,
                  onChanged:
                      _saving ? null : (v) => setState(() => _comments = v),
                ),
                const SizedBox(height: 8),
                Text(
                  _expiry == null
                      ? '掲載期限：なし'
                      : '掲載終了：' +
                          _expiry!.toLocal().toString().substring(0, 16),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickExpiry,
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('期限を変更'),
                    ),
                    TextButton(
                      onPressed:
                          _saving || _expiry == null
                              ? null
                              : () => setState(() => _expiry = null),
                      child: const Text('期限なし'),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '保存中…' : '保存'),
        ),
      ],
    ),
  );
}
