import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/cwitter_provider.dart';
import '../../../models/community/cwitter_social_platform.dart';
import '../../../services/community/cwitter_service.dart';
import 'cwitter_body_text.dart';

class CwitterSocialLinksSection extends ConsumerStatefulWidget {
  const CwitterSocialLinksSection({
    super.key,
    required this.authorId,
    required this.isSelf,
    this.initialLinks = const {},
  });

  final String authorId;
  final bool isSelf;
  final Map<String, String> initialLinks;

  @override
  ConsumerState<CwitterSocialLinksSection> createState() =>
      _CwitterSocialLinksSectionState();
}

class _CwitterSocialLinksSectionState
    extends ConsumerState<CwitterSocialLinksSection> {
  bool _isSaving = false;

  Map<String, String> get _links {
    final asyncLinks =
        ref.watch(cwitterUserSocialLinksProvider(widget.authorId)).valueOrNull;
    return asyncLinks ?? widget.initialLinks;
  }

  bool get _hasAnyLink =>
      CwitterSocialPlatform.values.any((platform) {
        final value = _links[platform.storageKey];
        return value != null && value.trim().isNotEmpty;
      });

  Future<void> _showEditDialog(CwitterSocialPlatform platform) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return _SocialLinkEditDialog(
          platform: platform,
          initialValue: _links[platform.storageKey] ?? '',
        );
      },
    );

    if (!mounted || result == null) return;

    final nextLinks = Map<String, String>.from(_links);
    if (result.isEmpty) {
      nextLinks.remove(platform.storageKey);
    } else {
      nextLinks[platform.storageKey] = result;
    }

    setState(() => _isSaving = true);
    try {
      await CwitterService.updateCwitterSocialLinks(
        uid: widget.authorId,
        links: nextLinks,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isEmpty
                ? '${platform.label} を削除しました'
                : '${platform.label} を保存しました',
          ),
        ),
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

  Future<void> _openRegisteredLink(
    BuildContext context,
    CwitterSocialPlatform platform,
    String value,
  ) async {
    final url = platform.resolveLaunchUrl(value);
    if (url != null) {
      await launchExternalUrlWithConfirmation(context, url);
      return;
    }

    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${platform.label} IDをコピーしました')),
    );
  }

  Future<void> _handleIconTap(
    BuildContext context,
    CwitterSocialPlatform platform,
    String? value,
  ) async {
    final registered = value != null && value.trim().isNotEmpty;
    if (registered) {
      await _openRegisteredLink(context, platform, value!.trim());
      return;
    }
    if (widget.isSelf) {
      await _showEditDialog(platform);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSelf && !_hasAnyLink) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final mutedColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isSelf)
          Text(
            'SNSリンク',
            style: theme.textTheme.labelLarge?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (widget.isSelf) const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final platform in CwitterSocialPlatform.values)
              _SocialLinkIconButton(
                platform: platform,
                value: _links[platform.storageKey],
                isSelf: widget.isSelf,
                isSaving: _isSaving,
                onTap: () => _handleIconTap(
                  context,
                  platform,
                  _links[platform.storageKey],
                ),
                onLongPress: widget.isSelf &&
                        (_links[platform.storageKey]?.trim().isNotEmpty ?? false)
                    ? () => _showEditDialog(platform)
                    : null,
              ),
          ],
        ),
        if (widget.isSelf) ...[
          const SizedBox(height: 6),
          Text(
            widget.isSelf
                ? '未登録のアイコンをタップして追加。登録済みはタップで開き、長押しで編集できます'
                : '',
            style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
        ],
      ],
    );
  }
}

class _SocialLinkEditDialog extends StatefulWidget {
  const _SocialLinkEditDialog({
    required this.platform,
    required this.initialValue,
  });

  final CwitterSocialPlatform platform;
  final String initialValue;

  @override
  State<_SocialLinkEditDialog> createState() => _SocialLinkEditDialogState();
}

class _SocialLinkEditDialogState extends State<_SocialLinkEditDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  void _delete() {
    Navigator.of(context).pop('');
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final platform = widget.platform;

    return AlertDialog(
      title: Text('${platform.label} を設定'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: AppConstants.cwitterSocialLinkMaxLength,
          decoration: InputDecoration(
            labelText: platform.label,
            hintText: platform.inputHint,
            helperText: platform.inputHelper,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final trimmed = (value ?? '').trim();
            if (trimmed.length > AppConstants.cwitterSocialLinkMaxLength) {
              return '${AppConstants.cwitterSocialLinkMaxLength}文字以内で入力してください';
            }
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        if (widget.initialValue.isNotEmpty)
          TextButton(
            onPressed: _delete,
            child: const Text('削除'),
          ),
        TextButton(
          onPressed: _cancel,
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _SocialLinkIconButton extends StatelessWidget {
  const _SocialLinkIconButton({
    required this.platform,
    required this.value,
    required this.isSelf,
    required this.isSaving,
    required this.onTap,
    this.onLongPress,
  });

  final CwitterSocialPlatform platform;
  final String? value;
  final bool isSelf;
  final bool isSaving;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  bool get _isRegistered => value != null && value!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!isSelf && !_isRegistered) {
      return const SizedBox.shrink();
    }

    final color = platform.iconColor(context, registered: _isRegistered);
    final borderColor = _isRegistered
        ? color.withValues(alpha: 0.45)
        : platform.brandColor.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSaving ? null : onTap,
        onLongPress: isSaving ? null : onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _isRegistered
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              FaIcon(
                platform.brandIcon,
                color: color,
                size: 22,
              ),
              if (_isRegistered)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
