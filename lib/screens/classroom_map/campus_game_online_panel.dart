import 'package:flutter/material.dart';
import '../../services/campus_game/campus_game_service.dart';

class CampusGameOnlinePanel extends StatefulWidget {
  const CampusGameOnlinePanel({
    super.key,
    required this.service,
    this.direction = 'outward',
    this.onGameEvent,
  });
  final CampusGameService service;
  final String direction;
  final ValueChanged<Map<String, dynamic>>? onGameEvent;
  @override
  State<CampusGameOnlinePanel> createState() => _CampusGameOnlinePanelState();
}

class _CampusGameOnlinePanelState extends State<CampusGameOnlinePanel> {
  final _code = TextEditingController();
  String _nickname = '';
  bool _consent = false, _busy = false, _dismissed = false;
  bool _loadingProfile = true, _profileLoaded = false;
  String? _error;
  Map<String, dynamic>? _standings;
  late String _direction;
  @override
  void initState() {
    super.initState();
    _direction = widget.direction;
    widget.service.addListener(_changed);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _loadingProfile = true;
        _profileLoaded = false;
        _nickname = '';
        _error = null;
      });
    }
    try {
      final profile = await widget.service.call('getProfile');
      if (profile['consent'] is! bool) {
        throw const CampusGameException('公開設定を読み込めません。再読込してください');
      }
      if (!mounted) return;
      setState(() {
        _nickname =
            profile['nickname'] is String ? profile['nickname'] as String : '';
        _consent = profile['consent'] as bool;
        _profileLoaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  void _changed() {
    if (widget.service.room?['status'] == 'racing' && !_dismissed && mounted) {
      _dismissed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.service.removeListener(_changed);
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await task();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _profile() async {
    if (!_profileLoaded) {
      throw const CampusGameException('公開設定を再読込してから操作してください');
    }
    if (_nickname.trim().isEmpty) {
      throw const CampusGameException('マイページでニックネームを設定してから参加してください');
    }
    await widget.service.call('profile', {'consent': _consent});
  }

  Future<void> _room(String action, Map<String, dynamic> payload) async {
    await _profile();
    if (!mounted) return;
    await widget.service.updateRoom(action, payload);
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.service.room;
    final blocked = _busy || _loadingProfile;
    final players =
        room?['players'] is List ? room!['players'] as List : const [];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'バスレース・オンライン',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'ルーム内ではマイページのニックネームが他の参加者に表示されます。ランキングの公開は任意です。2〜4人で同じコースを走れます。',
            ),
            if (_profileLoaded && !_loadingProfile) ...[
              if (_nickname.trim().isNotEmpty)
                Text('マイページのニックネーム: $_nickname')
              else
                const Text('マイページで表示名（ニックネーム）を設定してから参加してください。'),
              TextButton(
                onPressed: blocked ? null : _loadProfile,
                child: const Text('マイページのニックネームを再読込'),
              ),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consent,
              onChanged:
                  blocked || !_profileLoaded
                      ? null
                      : (v) => setState(() => _consent = v ?? false),
              title: const Text('ランキングにニックネームと記録を公開する'),
              subtitle: const Text('公開しない設定を送信すると以前の公開記録も取り下げます。'),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _direction,
              decoration: const InputDecoration(labelText: '方向'),
              items: const [
                DropdownMenuItem(
                  value: 'outward',
                  child: Text(
                    '津田沼 → 新習志野',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'return',
                  child: Text(
                    '新習志野 → 津田沼',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 's_bay',
                  child: Text(
                    'Sベイ・サーキット',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'neon_city',
                  child: Text(
                    'ネオンシティ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged:
                  blocked || room != null
                      ? null
                      : (v) => setState(() => _direction = v!),
            ),
            const SizedBox(height: 12),
            if (blocked) const LinearProgressIndicator(),
            if (_error ?? widget.service.error case final String message)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!_profileLoaded && !_loadingProfile)
              TextButton(
                onPressed: _loadProfile,
                child: const Text('公開設定を再読込'),
              ),
            if (room == null) ...[
              FilledButton(
                onPressed:
                    blocked
                        ? null
                        : () => _run(
                          () => _room('createRoom', {'direction': _direction}),
                        ),
                child: const Text('ルームを作成'),
              ),
              TextField(
                controller: _code,
                maxLength: 12,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'ルームコード',
                  hintText: '12桁のコードを入力',
                ),
              ),
              OutlinedButton(
                onPressed:
                    blocked
                        ? null
                        : () => _run(
                          () => _room('joinRoom', {
                            'code': _code.text.trim().toUpperCase(),
                          }),
                        ),
                child: const Text('コードで参加'),
              ),
            ] else ...[
              Text('ルーム ${room['code']} ・ ${room['status']}'),
              const Text('全員が準備を完了するとホストが開始できます。'),
              for (final player in players)
                if (player is Map)
                  ListTile(
                    title: Text(player['nickname']?.toString() ?? 'プレイヤー'),
                    subtitle: Text(
                      '${player['status'] ?? ''} ・ 準備 ${player['ready'] == true ? '完了' : '待ち'} ・ 進行 ${player['progress'] ?? 0}',
                    ),
                    trailing:
                        player['elapsedMs'] == null
                            ? null
                            : Text(
                              '${((player['elapsedMs'] as num) / 1000).toStringAsFixed(2)} 秒',
                            ),
                  ),
              FilledButton(
                onPressed:
                    blocked
                        ? null
                        : () => _run(() async {
                          await widget.service.updateRoom('readyRoom', {
                            'roomId': room['roomId'],
                            'ready': true,
                          });
                        }),
                child: const Text('準備完了'),
              ),
              FilledButton(
                onPressed:
                    blocked
                        ? null
                        : () => _run(() async {
                          await widget.service.updateRoom('startRoom', {
                            'roomId': room['roomId'],
                          });
                        }),
                child: const Text('ホストがレース開始'),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed:
                        blocked ? null : () => _run(widget.service.reconnect),
                    child: const Text('再接続'),
                  ),
                  TextButton(
                    onPressed:
                        blocked ? null : () => _run(widget.service.leave),
                    child: const Text('退出'),
                  ),
                ],
              ),
            ],
            FilledButton(
              onPressed:
                  blocked || room != null
                      ? null
                      : () => _run(() async {
                        if (!_consent) {
                          throw const CampusGameException('ランキングの公開に同意してください');
                        }
                        await _profile();
                        final challenge = await widget.service.call(
                          'challenge',
                          {'direction': _direction},
                        );
                        widget.onGameEvent?.call({
                          'type': 'campus-game-response',
                          'action': 'challenge',
                          'ok': true,
                          'data': challenge,
                          'direction': _direction,
                        });
                        if (context.mounted) Navigator.of(context).pop();
                      }),
              child: const Text('ランキングに挑戦'),
            ),
            const Divider(),
            OutlinedButton(
              onPressed:
                  blocked
                      ? null
                      : () => _run(() async {
                        final courses = await widget.service.call('courses');
                        final list = courses['courses'] as List? ?? [];
                        final selected = list.whereType<Map>().where(
                          (c) => c['direction'] == _direction,
                        );
                        if (selected.isEmpty) {
                          throw const CampusGameException('コース情報を取得できません');
                        }
                        final result = await widget.service.call('standings', {
                          'courseKey': selected.first['courseKey'],
                        });
                        if (mounted) setState(() => _standings = result);
                      }),
              child: const Text('この方向のランキングを表示'),
            ),
            if (_standings != null) ...[
              Text('コース / バージョン: ${_standings!['courseKey']}'),
              if (_standings!['own'] is Map &&
                  _standings!['own']['elapsedMs'] is num)
                Text(
                  '自分のベスト（個人記録）: ${((_standings!['own']['elapsedMs'] as num) / 1000).toStringAsFixed(2)} 秒',
                ),
              if (_standings!['own'] is Map &&
                  _standings!['own']['publicElapsedMs'] is num)
                Text(
                  '公開記録: ${((_standings!['own']['publicElapsedMs'] as num) / 1000).toStringAsFixed(2)} 秒 ・ ${_standings!['own']['rank'] == null ? '公開順位なし' : "${_standings!['own']['rank']}位"}',
                ),
              for (final (index, entry)
                  in ((_standings!['entries'] as List?) ?? []).indexed)
                if (entry is Map)
                  ListTile(
                    leading: Text('${index + 1}位'),
                    title: Text(entry['nickname']?.toString() ?? ''),
                    trailing: Text(
                      '${((entry['elapsedMs'] as num) / 1000).toStringAsFixed(2)} 秒',
                    ),
                  ),
              if (((_standings!['entries'] as List?) ?? []).isEmpty)
                const Text('まだ記録がありません'),
            ],
          ],
        ),
      ),
    );
  }
}
