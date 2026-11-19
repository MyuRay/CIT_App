import 'dart:async';
import '../../services/campus_game/campus_game_service.dart';
import '../../services/campus_game/campus_game_view_bridge.dart';
import 'campus_game_online_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'campus_3d_view.dart';

/// Local assets only: opening the map never downloads a campus from Firebase.
class Campus3dScreen extends StatefulWidget {
  const Campus3dScreen({
    super.key,
    this.initialCampusId = 'tsudanuma',
    this.experience = 'map',
  });
  final String experience;
  bool get isGame => experience == 'game';
  final String initialCampusId;

  @override
  State<Campus3dScreen> createState() => _Campus3dScreenState();
}

class _Campus3dScreenState extends State<Campus3dScreen> {
  late String _campus;
  late Future<String?> _ready;
  int _revision = 0;
  bool _fullscreen = false;
  final CampusGameService _game = CampusGameService();
  late final CampusGameViewBridge _gameBridge;
  int _gameGeneration = 0;
  bool _onlineOpen = false;
  bool _overlayOpen = false;
  String _selectedDirection = 'outward';

  void _detachGame() {
    _gameGeneration++;
    _game.detach();
  }

  Future<void> _openOnline([String? direction]) async {
    final selected =
        const {'outward', 'return', 's_bay', 'neon_city'}.contains(direction)
            ? direction!
            : _selectedDirection;
    _selectedDirection = selected;
    if (!mounted || _onlineOpen) return;
    _onlineOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder:
            (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .88,
                child: CampusGameOnlinePanel(
                  service: _game,
                  direction: selected,
                  onGameEvent: _gameBridge.send,
                ),
              ),
            ),
      );
    } finally {
      _onlineOpen = false;
    }
  }

  @override
  void dispose() {
    _detachGame();
    _game.onEvent = null;
    _game.dispose();
    _gameBridge.dispose();
    super.dispose();
  }

  void _toggleFullscreen() => setState(() => _fullscreen = !_fullscreen);
  void _exitFullscreen() {
    if (_fullscreen) setState(() => _fullscreen = false);
  }

  String get _asset =>
      'assets/models/campus/${_campus == 'narashino' ? 'shinnarashino' : 'tsudanuma'}-campus.glb';

  @override
  void initState() {
    super.initState();
    _campus = widget.initialCampusId == 'narashino' ? 'narashino' : 'tsudanuma';
    _ready = _prepare();
    _gameBridge = CampusGameViewBridge(
      onOpen: _openOnline,
      onCourseChanged: (direction) {
        if (const {
          'outward',
          'return',
          's_bay',
          'neon_city',
        }.contains(direction)) {
          _selectedDirection = direction;
        }
      },
      onOverlayChanged: (open) {
        if (mounted && _overlayOpen != open) {
          setState(() => _overlayOpen = open);
        }
      },
      onDetached: _detachGame,
      onRequest: (request) async {
        final generation = _gameGeneration;
        final response = await _game.handle(request);
        if (mounted && generation == _gameGeneration) {
          _gameBridge.send(response);
        }
      },
    );
    _game.onEvent = _gameBridge.send;
  }

  Future<String?> _prepare() async {
    try {
      if (widget.isGame) {
        return await rootBundle.loadString('assets/models/campus/viewer.html');
      }
      final bytes = await rootBundle.load(_asset);
      if (bytes.lengthInBytes < 12 ||
          bytes.getUint32(0, Endian.little) != 0x46546c67 ||
          bytes.getUint32(4, Endian.little) != 2) {
        return null;
      }
      return await rootBundle.loadString('assets/models/campus/viewer.html');
    } catch (_) {
      // Represent asset failure as data, including when a route is removed
      // before its FutureBuilder can attach a listener.
      return null;
    }
  }

  void _resetView() {
    _gameBridge.send({'type': 'campus-reset-view'});
    if (_overlayOpen) setState(() => _overlayOpen = false);
  }

  void _reload([String? campus]) {
    _detachGame();
    setState(() {
      _campus = campus ?? _campus;
      _overlayOpen = false;
      _revision++;
      _ready = _prepare();
    });
  }

  @override
  Widget build(BuildContext context) {
    final supported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final compact = MediaQuery.sizeOf(context).height < 500;
    return PopScope(
      canPop: !_fullscreen && !_overlayOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_overlayOpen) {
          _gameBridge.send({'type': 'campus-close-overlay'});
          setState(() => _overlayOpen = false);
        } else {
          _exitFullscreen();
        }
      },
      child: Scaffold(
        appBar:
            _fullscreen
                ? null
                : AppBar(
                  toolbarHeight: compact ? 48 : null,
                  title: Text(
                    widget.isGame ? '学バスタイムアタック' : '3Dキャンパスマップ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  actions: [
                    if (widget.isGame)
                      IconButton(
                        onPressed: _openOnline,
                        tooltip: 'オンラインレース',
                        icon: const Icon(Icons.leaderboard),
                      ),
                    IconButton(
                      onPressed: _toggleFullscreen,
                      tooltip: '全画面にする',
                      icon: const Icon(Icons.fullscreen),
                    ),
                    if (widget.isGame)
                      IconButton(
                        onPressed: _resetView,
                        tooltip: '視点をリセット',
                        icon: const Icon(Icons.center_focus_strong),
                      ),
                  ],
                ),
        body: SafeArea(
          child: Column(
            children: [
              Visibility(
                visible: !_fullscreen && !widget.isGame,
                maintainState: true,
                child: Padding(
                  padding: EdgeInsets.all(compact ? 2 : 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final entry
                          in const {
                            'tsudanuma': '津田沼',
                            'narashino': '新習志野',
                          }.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _campus == entry.key,
                          onSelected: (_) {
                            if (_campus != entry.key) _reload(entry.key);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child:
                    !supported
                        ? const Center(
                          child: Text('3D表示はAndroid・iOS・Webで利用できます'),
                        )
                        : FutureBuilder<String?>(
                          key: ValueKey('$_campus-$_revision'),
                          future: _ready,
                          builder: (context, snapshot) {
                            if (snapshot.hasError ||
                                (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.data == null)) {
                              return SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_fullscreen)
                                        TextButton(
                                          onPressed: _exitFullscreen,
                                          child: const Text('全画面を解除'),
                                        ),
                                      const Icon(Icons.error_outline, size: 40),
                                      const SizedBox(height: 12),
                                      const Text(
                                        '3Dモデルを読み込めませんでした',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton(
                                        onPressed: () => _reload(),
                                        child: const Text('再試行'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  semanticsLabel: '3Dモデルを読み込み中',
                                ),
                              );
                            }
                            return Campus3dView(
                              key: ValueKey('viewer-$_campus-$_revision'),
                              campus: _campus,
                              experience: widget.experience,
                              reducedMotion:
                                  MediaQuery.of(context).disableAnimations ||
                                  MediaQuery.of(context).accessibleNavigation,
                              gameBridge: _gameBridge,
                              fullscreen: _fullscreen,
                              onToggleFullscreen: _toggleFullscreen,
                              onExitFullscreen: _exitFullscreen,
                              onResetViewer: _resetView,
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
