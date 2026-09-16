import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bus/bus_timetable_draft.dart';
import '../../widgets/bus/bus_departure_dialog.dart';

enum _InputMode { paste, interval, copy }

class BusTimetableEditorScreen extends StatefulWidget {
  const BusTimetableEditorScreen({
    super.key,
    required this.route,
    required this.sources,
    required this.onSave,
    this.initialDayType = 'weekday',
  });
  final BusTimetableRoute route;
  final List<BusTimetableRoute> sources;
  final String initialDayType;
  final Future<void> Function(List<BusDepartureData>) onSave;

  @override
  State<BusTimetableEditorScreen> createState() =>
      _BusTimetableEditorScreenState();
}

class _BusTimetableEditorScreenState extends State<BusTimetableEditorScreen> {
  late List<BusDepartureData> _entries = copyBusDepartures(
    widget.route.entries,
  );
  late String _day = widget.initialDayType;
  late String _copyRoute = widget.route.id;
  late String _copyDay = _day == 'weekday' ? 'saturday' : 'weekday';
  final _history = <List<BusDepartureData>>[];
  final _paste = TextEditingController();
  final _start = TextEditingController(text: '08:00');
  final _end = TextEditingController(text: '10:00');
  final _interval = TextEditingController(text: '15');
  final _note = TextEditingController();
  final _scroll = ScrollController();
  _InputMode _mode = _InputMode.paste;
  bool _replace = false;
  bool _saving = false;
  bool _allowExit = false;
  bool _confirmingExit = false;
  bool _pendingInput = false;
  String? _inputError;
  String? _saveError;
  String? _message;

  bool get _changed => !busTimetableDataEquals(_entries, widget.route.entries);
  bool get _dirty => _changed || _pendingInput;
  List<BusDepartureData> get _dayEntries =>
      _entries.where((e) => busDepartureDay(e) == _day).toList()..sort(
        (a, b) => busDepartureMinute(a).compareTo(busDepartureMinute(b)),
      );

  @override
  void dispose() {
    for (final controller in [_paste, _start, _end, _interval, _note]) {
      controller.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _change(List<BusDepartureData> next) {
    if (busTimetableDataEquals(_entries, next)) return;
    _history.add(copyBusDepartures(_entries));
    if (_history.length > 20) _history.removeAt(0);
    _entries = next;
    _saveError = null;
  }

  void _inputChanged(String _) => setState(() {
    _pendingInput = true;
    _inputError = null;
  });

  void _apply() {
    try {
      final List<BusDepartureData> incoming;
      if (_mode == _InputMode.copy) {
        if (_copyRoute == widget.route.id && _copyDay == _day) {
          throw const FormatException('コピー元に、別の曜日または路線を選んでください。');
        }
        final source =
            _copyRoute == widget.route.id
                ? _entries
                : widget.sources
                    .firstWhere((route) => route.id == _copyRoute)
                    .entries;
        validateBusDepartures(source);
        incoming = [
          for (final e in source.where((e) => busDepartureDay(e) == _copyDay))
            newBusDeparture(
              busDepartureMinute(e),
              _day,
              note: e['note'] as String?,
              active: e['isActive'] as bool? ?? true,
            ),
        ];
        if (incoming.isEmpty) throw const FormatException('コピー元のダイヤに便がありません。');
      } else {
        final times =
            _mode == _InputMode.paste
                ? parseBusTimeList(_paste.text)
                : generateBusTimes(_start.text, _end.text, _interval.text);
        incoming =
            times
                .map((time) => newBusDeparture(time, _day, note: _note.text))
                .toList();
      }
      final previousCount = _dayEntries.length;
      final next = mergeBusDepartures(
        _entries,
        incoming,
        _day,
        replace: _replace,
      );
      final added =
          next.where((e) => busDepartureDay(e) == _day).length -
          (_replace ? 0 : previousCount);
      setState(() {
        if (_replace || added > 0) _change(next);
        _pendingInput = false;
        _inputError = null;
        _message =
            '${busDayLabels[_day]}に$added便${_replace ? 'を設定' : '追加'}'
            '（重複${incoming.length - added}便を除外）。保存すると公開されます。';
      });
    } on FormatException catch (error) {
      setState(() => _inputError = error.message);
    }
  }

  Future<void> _edit([BusDepartureData? entry]) async {
    final index = entry == null ? null : _entries.indexOf(entry);
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => BusDepartureDialog(
            entry: entry,
            dayType: _day,
            onSave: (updated) async {
              final collision = _entries.asMap().entries.any(
                (item) =>
                    item.key != index &&
                    busDepartureDay(item.value) == busDepartureDay(updated) &&
                    busDepartureMinute(item.value) ==
                        busDepartureMinute(updated),
              );
              if (collision) throw const FormatException('同じ曜日・時刻の便が既にあります。');
              final next = copyBusDepartures(_entries);
              if (index == null) {
                next.add(updated);
              } else {
                next[index] = updated;
              }
              setState(() {
                _change(next);
                _message = 'リストに反映しました。最後に変更を保存してください。';
              });
            },
          ),
    );
  }

  Future<void> _exit() async {
    if (_saving || _confirmingExit) return;
    if (!_dirty) {
      Navigator.pop(context, false);
      return;
    }
    _confirmingExit = true;
    final discard = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('編集内容を破棄しますか？'),
            content: const Text('まだ保存していないダイヤと入力内容が失われます。'),
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
    _confirmingExit = false;
    if (discard == true && mounted) {
      setState(() => _allowExit = true);
      Navigator.pop(context, false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_changed) return;
    if (_pendingInput) {
      setState(() => _inputError = '入力中の内容を「リストに追加」で反映してから保存してください。');
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(copyBusDepartures(_entries));
      if (!mounted) return;
      setState(() => _allowExit = true);
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = busTimetableSaveError(error);
        });
      }
    }
  }

  Future<void> _copyTimes() async {
    await Clipboard.setData(
      ClipboardData(
        text: _dayEntries
            .map((e) => formatBusMinute(busDepartureMinute(e)))
            .join('\n'),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('表示中の曜日の出発時刻をコピーしました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PopScope(
      canPop: _allowExit || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ダイヤを登録'),
          leading: BackButton(onPressed: _saving ? null : _exit),
          actions: [
            IconButton(
              key: const Key('bus_undo'),
              tooltip: 'ひとつ元に戻す',
              onPressed:
                  _saving || _history.isEmpty
                      ? null
                      : () => setState(() {
                        _entries = _history.removeLast();
                        _message = '直前の変更を元に戻しました。';
                        _saveError = null;
                      }),
              icon: const Icon(Icons.undo),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: AbsorbPointer(
            absorbing: _saving,
            child: SingleChildScrollView(
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.route.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text('曜日を選ぶ → リストに追加 → 変更を保存'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final day in busDayLabels.entries)
                        ChoiceChip(
                          key: ValueKey('bus_day_${day.key}'),
                          label: Text(
                            '${day.value} ${_entries.where((e) => busDepartureDay(e) == day.key).length}便',
                          ),
                          selected: _day == day.key,
                          onSelected:
                              (_) => setState(() {
                                _day = day.key;
                                _inputError = null;
                                _message = null;
                              }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final mode in [
                                (
                                  _InputMode.paste,
                                  'まとめて入力',
                                  Icons.content_paste,
                                ),
                                (
                                  _InputMode.interval,
                                  '等間隔で作成',
                                  Icons.more_time,
                                ),
                                (_InputMode.copy, 'ダイヤをコピー', Icons.copy),
                              ])
                                ChoiceChip(
                                  key: ValueKey('bus_mode_${mode.$1.name}'),
                                  avatar: Icon(mode.$3, size: 18),
                                  label: Text(mode.$2),
                                  selected: _mode == mode.$1,
                                  onSelected:
                                      (_) => setState(() {
                                        _mode = mode.$1;
                                        _inputError = null;
                                      }),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_mode == _InputMode.paste)
                            TextField(
                              key: const Key('bus_paste'),
                              controller: _paste,
                              minLines: 3,
                              maxLines: 7,
                              onChanged: _inputChanged,
                              decoration: const InputDecoration(
                                labelText: '出発時刻を貼り付け・入力',
                                hintText:
                                    '08:10 08:30 09:00\nまたは\n8時 10 30\n9時 00 20',
                                helperText:
                                    '空白・改行・カンマ区切りに対応。Excelの「時＋分」の列も貼り付けできます。',
                                helperMaxLines: 4,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          if (_mode == _InputMode.interval) ...[
                            Wrap(
                              spacing: 10,
                              runSpacing: 12,
                              children: [
                                _intervalField(
                                  'bus_start',
                                  _start,
                                  '開始時刻',
                                  '08:00',
                                ),
                                _intervalField(
                                  'bus_end',
                                  _end,
                                  '終了時刻',
                                  '10:00',
                                ),
                                _intervalField(
                                  'bus_interval',
                                  _interval,
                                  '間隔（分）',
                                  '15',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('開始から終了まで、指定間隔で便を作ります。'),
                          ],
                          if (_mode == _InputMode.copy) ...[
                            DropdownButtonFormField<String>(
                              key: const Key('bus_copy_route'),
                              initialValue: _copyRoute,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'コピー元の路線',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final route
                                    in {
                                      widget.route.id: widget.route,
                                      for (final r in widget.sources) r.id: r,
                                    }.values)
                                  DropdownMenuItem(
                                    value: route.id,
                                    child: Text(
                                      route.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged:
                                  (value) =>
                                      setState(() => _copyRoute = value!),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              key: const Key('bus_copy_day'),
                              initialValue: _copyDay,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'コピー元の曜日',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final day in busDayLabels.entries)
                                  DropdownMenuItem(
                                    value: day.key,
                                    child: Text(day.value),
                                  ),
                              ],
                              onChanged:
                                  (value) => setState(() => _copyDay = value!),
                            ),
                            const SizedBox(height: 8),
                            const Text('備考と運休設定もコピーします。コピー元は変更されません。'),
                          ] else ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _note,
                              onChanged: _inputChanged,
                              decoration: const InputDecoration(
                                labelText: '追加する便の共通備考（任意）',
                                hintText: '授業日のみ運行など',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            key: const Key('bus_replace'),
                            contentPadding: EdgeInsets.zero,
                            title: Text('${busDayLabels[_day]}ダイヤを置き換える'),
                            subtitle: Text(
                              _replace
                                  ? '現在の${_dayEntries.length}便と備考・運休設定を置換。他の曜日は残ります。'
                                  : '既存の便に追加。同じ曜日・時刻の便は重複登録しません。',
                            ),
                            value: _replace,
                            onChanged:
                                (value) => setState(() => _replace = value),
                          ),
                          if (_inputError != null) ...[
                            Text(
                              _inputError!,
                              style: TextStyle(color: colors.error),
                            ),
                            const SizedBox(height: 8),
                          ],
                          FilledButton.icon(
                            key: const Key('bus_apply'),
                            onPressed: _apply,
                            icon: Icon(
                              _replace ? Icons.swap_horiz : Icons.playlist_add,
                            ),
                            label: Text(
                              _replace
                                  ? '${busDayLabels[_day]}のリストを置換'
                                  : 'リストに追加',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_message != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _message!,
                        style: TextStyle(color: colors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${busDayLabels[_day]}・${_dayEntries.length}便',
                        style: theme.textTheme.titleMedium,
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _edit(),
                        icon: const Icon(Icons.add),
                        label: const Text('1便追加'),
                      ),
                      TextButton.icon(
                        onPressed: _copyTimes,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('時刻コピー'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_dayEntries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('この曜日には便がありません。上の入力欄から追加できます。'),
                    ),
                  for (final entry in _dayEntries) _entryTile(entry),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_saveError != null) ...[
                  Text(_saveError!, style: TextStyle(color: colors.error)),
                  const SizedBox(height: 8),
                ],
                Text(
                  _pendingInput ? '入力中の内容をリストに反映してください' : '保存するまで公開ダイヤは変わりません',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('bus_save'),
                  onPressed: _saving || !_changed ? null : _save,
                  child: Text(_saving ? '保存中…' : '変更を保存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _intervalField(
    String key,
    TextEditingController controller,
    String label,
    String hint,
  ) => SizedBox(
    width: 132,
    child: TextField(
      key: ValueKey(key),
      controller: controller,
      keyboardType: TextInputType.datetime,
      onChanged: _inputChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _entryTile(BusDepartureData entry) {
    final active = entry['isActive'] as bool? ?? true;
    final note = entry['note'] as String? ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatBusMinute(busDepartureMinute(entry))}${active ? '' : ' ・運休'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (note.isNotEmpty) Text(note),
                ],
              ),
            ),
            IconButton(
              tooltip: '便を編集',
              onPressed: () => _edit(entry),
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: '便の操作',
              onSelected:
                  (action) => setState(() {
                    final index = _entries.indexOf(entry);
                    final next = copyBusDepartures(_entries);
                    if (action == 'delete') {
                      next.removeAt(index);
                    } else {
                      next[index]['isActive'] = !active;
                    }
                    _change(next);
                    _message = 'リストを変更しました。上部の「元に戻す」で取り消せます。';
                  }),
              itemBuilder:
                  (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(active ? '運休にする' : '運行に戻す'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('リストから削除'),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }
}
