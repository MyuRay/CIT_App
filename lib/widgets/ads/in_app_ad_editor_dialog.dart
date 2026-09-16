import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/ads/in_app_ad_model.dart';
import 'in_app_ad_creative.dart';
import 'sponsor_presentation.dart';

String adPlacementLabel(AdPlacement placement) => switch (placement) {
  AdPlacement.homeTop => 'ホーム',
  AdPlacement.cafeteria => '学食',
  AdPlacement.scheduleBottom => '時間割',
  AdPlacement.profileTop => 'プロフィール',
  AdPlacement.cwitterFeed => 'Cwitter',
  AdPlacement.chibaChannelThreadList => '千葉チャンネル・スレッド一覧',
  AdPlacement.chibaChannelThreadReplies => '千葉チャンネル・返信',
};

class InAppAdEditorDialog extends StatefulWidget {
  const InAppAdEditorDialog({
    super.key,
    this.ad,
    this.isDuplicate = false,
    required this.onSave,
    required this.pickBulletin,
  });
  final InAppAd? ad;
  final bool isDuplicate;
  final Future<void> Function(InAppAd) onSave;
  final Future<String?> Function() pickBulletin;
  @override
  State<InAppAdEditorDialog> createState() => _InAppAdEditorDialogState();
}

class _InAppAdEditorDialogState extends State<InAppAdEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.ad?.title ?? '');
  late final _body = TextEditingController(text: widget.ad?.body ?? '');
  late final _image = TextEditingController(text: widget.ad?.imageUrl ?? '');
  late final _payload = TextEditingController(
    text: widget.ad?.actionPayload ?? '',
  );
  late final _sponsor = TextEditingController(
    text: widget.ad?.sponsorName ?? '',
  );
  late final _weight = TextEditingController(
    text: (widget.ad?.weight ?? 1).toString(),
  );
  late AdPlacement _placement = widget.ad?.placement ?? AdPlacement.homeTop;
  late AdActionType _action = widget.ad?.actionType ?? AdActionType.bulletin;
  late bool _active = widget.ad?.isActive ?? true;
  late bool _sponsored = widget.ad?.isSponsored ?? false;
  late DateTime? _start = widget.ad?.startAt;
  late DateTime? _end = widget.ad?.endAt;
  bool _saving = false;
  bool _allowExit = false;
  bool _closing = false;
  late final Map<String, dynamic> _initial;
  bool get _dirty =>
      !mapEquals(_initial, _draft().toFirestore()..remove('updatedAt'));
  String? _error;

  @override
  void initState() {
    super.initState();
    // Snapshot before any controller changes, not on the first close attempt.
    _initial = _draft().toFirestore()..remove('updatedAt');
  }

  Future<void> _close() async {
    if (_saving || _closing) return;
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    _closing = true;
    final discard = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('変更を破棄しますか？'),
            content: const Text('保存していない広告の変更が失われます。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('編集を続ける'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('破棄する'),
              ),
            ],
          ),
    );
    _closing = false;
    if (discard == true && mounted) {
      setState(() => _allowExit = true);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _body,
      _image,
      _payload,
      _sponsor,
      _weight,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isWebUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        ['http', 'https'].contains(uri.scheme) &&
        uri.host.isNotEmpty;
  }

  InAppAd _draft({bool preview = false}) => InAppAd(
    id: widget.ad?.id ?? '',
    title:
        preview && _title.text.trim().isEmpty ? '広告のタイトル' : _title.text.trim(),
    body:
        preview && _body.text.trim().isEmpty
            ? 'キャンペーンやサービスの紹介文が入ります。'
            : _body.text.trim(),
    imageUrl: _image.text.trim().isEmpty ? null : _image.text.trim(),
    // Preserve legacy CTA data; the whole banner now opens the destination.
    ctaText: widget.ad?.ctaText,
    placement: _placement,
    actionType: _action,
    actionPayload: _payload.text.trim(),
    isActive: _active,
    startAt: _start,
    endAt: _end,
    weight: int.tryParse(_weight.text) ?? 1,
    isSponsored: _sponsored,
    sponsorName: _sponsored ? _sponsor.text.trim() : '',
  );

  Future<void> _pickDate(bool start) async {
    final initial = (start ? _start : _end) ?? DateTime.now();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year < now.year ? initial.year : now.year),
      lastDate: DateTime(
        (initial.year > now.year ? initial.year : now.year) + 10,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(
        invalid.first.context,
        duration: const Duration(milliseconds: 200),
        alignment: .2,
      );
      return;
    }
    if (_start != null && _end != null && !_end!.isAfter(_start!)) {
      setState(() => _error = '終了日時は開始日時より後にしてください');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_draft());
      if (mounted) {
        setState(() => _allowExit = true);
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存できませんでした。通信状態と管理者権限を確認して再試行してください。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return PopScope(
      canPop: _allowExit || (!_saving && !_dirty),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 820),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isDuplicate
                                ? '広告を複製'
                                : widget.ad == null
                                ? '広告を作成'
                                : '広告を編集',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    if (!largeText)
                      IconButton(
                        tooltip: '編集を閉じる',
                        onPressed: _saving ? null : _close,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide =
                        constraints.maxWidth >= 800 &&
                        MediaQuery.textScalerOf(context).scale(1) <= 1.3;
                    final fields = Form(
                      key: _form,
                      child: AbsorbPointer(
                        absorbing: _saving,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.isDuplicate)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'コピーは配信を停止した状態で作成します。内容と掲載設定を確認してください。',
                                  style: TextStyle(color: colors.primary),
                                ),
                              ),
                            if (!wide) ...[
                              _previewPanel(),
                              const SizedBox(height: 20),
                            ],
                            _section('01', '広告の内容', _creativeFields()),
                            const SizedBox(height: 20),
                            _section('02', '掲載場所とリンク先', _linkFields()),
                            const SizedBox(height: 20),
                            _section('03', '掲載設定', _settingsFields()),
                          ],
                        ),
                      ),
                    );
                    final scroll = SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(20),
                      child: fields,
                    );
                    if (!wide) return scroll;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: scroll),
                        VerticalDivider(width: 1, color: colors.outlineVariant),
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: _previewPanel(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: colors.error)),
                      const SizedBox(height: 8),
                    ],
                    OverflowBar(
                      spacing: 12,
                      overflowSpacing: 8,
                      alignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _saving ? null : _close,
                          child: const Text('キャンセル'),
                        ),
                        FilledButton.icon(
                          key: const Key('ad_editor_save'),
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(_saving ? '保存中…' : '保存'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String number, String title, List<Widget> fields) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    number,
                    style: TextStyle(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _previewPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.visibility_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '表示プレビュー',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      InAppAdCreative(ad: _draft(preview: true), margin: EdgeInsets.zero),
    ],
  );

  List<Widget> _creativeFields() => [
    SponsorFields(
      enabled: _sponsored,
      nameController: _sponsor,
      readOnly: _saving,
      onChanged: (v) => setState(() => _sponsored = v),
      onNameChanged: (_) => setState(() {}),
    ),
    TextFormField(
      controller: _title,
      decoration: const InputDecoration(labelText: 'タイトル'),
      onChanged: (_) => setState(() {}),
      validator: (v) => v?.trim().isEmpty == true ? 'タイトルを入力してください' : null,
    ),
    const SizedBox(height: 12),
    TextFormField(
      controller: _body,
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(labelText: '本文'),
      onChanged: (_) => setState(() {}),
      validator: (v) => v?.trim().isEmpty == true ? '本文を入力してください' : null,
    ),
    const SizedBox(height: 12),

    TextFormField(
      controller: _image,
      decoration: const InputDecoration(labelText: '画像URL（任意）'),
      onChanged: (_) => setState(() {}),
      validator:
          (v) =>
              v!.trim().isNotEmpty && !_isWebUrl(v.trim())
                  ? '画像のURLを確認してください'
                  : null,
    ),
    const SizedBox(height: 20),
  ];

  List<Widget> _linkFields() => [
    DropdownButtonFormField<AdPlacement>(
      initialValue: _placement,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '表示場所'),
      items: [
        for (final p in AdPlacement.values)
          DropdownMenuItem(
            value: p,
            child: Text(
              adPlacementLabel(p),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) => setState(() => _placement = v ?? _placement),
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<AdActionType>(
      initialValue: _action,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'タップしたときの動作'),
      items: const [
        DropdownMenuItem(value: AdActionType.bulletin, child: Text('掲示板投稿を開く')),
        DropdownMenuItem(value: AdActionType.external, child: Text('外部リンクを開く')),
      ],
      onChanged: (v) => setState(() => _action = v ?? _action),
    ),
    const SizedBox(height: 12),
    TextFormField(
      controller: _payload,
      key: const Key('ad_editor_payload'),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: _action == AdActionType.bulletin ? '掲示板投稿' : 'リンクURL',
        hintText:
            _action == AdActionType.bulletin
                ? '一覧から選択できます'
                : 'https://example.com',
        suffixIcon:
            _action != AdActionType.bulletin
                ? null
                : IconButton(
                  tooltip: '掲示板から選択',
                  icon: const Icon(Icons.list_alt),
                  onPressed: () async {
                    final id = await widget.pickBulletin();
                    if (id != null && mounted) {
                      setState(() => _payload.text = id);
                    }
                  },
                ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'リンク先を設定してください';
        if (_action == AdActionType.external && !_isWebUrl(text)) {
          return 'http または https のURLを入力してください';
        }
        if (_action == AdActionType.bulletin &&
            !RegExp(r'^(bulletin_posts/)?[^/\s]+$').hasMatch(text)) {
          return '掲示板一覧から投稿を選択してください';
        }
        return null;
      },
    ),
    const SizedBox(height: 12),
  ];

  List<Widget> _settingsFields() => [
    Text('掲載期間', style: Theme.of(context).textTheme.titleSmall),
    const SizedBox(height: 8),
    _dateControl(true),
    _dateControl(false),
    const SizedBox(height: 12),
    TextFormField(
      controller: _weight,
      onChanged: (_) => setState(() {}),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '表示の重み',
        helperText: '同じ場所の広告より表示されやすくする倍率（推奨1〜10）',
        helperMaxLines: 3,
      ),
      validator: (v) {
        final n = int.tryParse(v ?? '');
        return n == null || n < 1 ? '1以上の整数を入力してください' : null;
      },
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: const Text('配信を有効にする'),
      value: _active,
      onChanged: (v) => setState(() => _active = v),
    ),
  ];
  Widget _dateControl(bool start) {
    final date = start ? _start : _end;
    final label = start ? '開始' : '終了';
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickDate(start),
            icon: const Icon(Icons.calendar_month, size: 18),
            label: Text(
              date == null
                  ? '$label：指定なし'
                  : '$label：${date.toString().substring(0, 16)}',
            ),
          ),
        ),
        if (date != null)
          IconButton(
            tooltip: '$label日時をクリア',
            icon: const Icon(Icons.close),
            onPressed:
                () => setState(() {
                  if (start) {
                    _start = null;
                  } else {
                    _end = null;
                  }
                }),
          ),
      ],
    );
  }
}
