import 'dart:async';
import 'dart:convert';
import '../../services/campus_game/campus_game_view_bridge.dart';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class Campus3dView extends StatefulWidget {
  const Campus3dView({
    super.key,
    required this.campus,
    this.experience = 'map',
    this.reducedMotion = false,
    this.gameBridge,
    this.fullscreen = false,
    this.onToggleFullscreen,
    this.onExitFullscreen,
    this.onResetViewer,
  });
  final String campus;
  final String experience;
  final bool reducedMotion;
  final CampusGameViewBridge? gameBridge;
  final bool fullscreen;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onExitFullscreen;
  final VoidCallback? onResetViewer;
  @override
  State<Campus3dView> createState() => _Campus3dViewState();
}

class _Campus3dViewState extends State<Campus3dView> {
  late final String _type;
  late final web.HTMLIFrameElement _frame;
  late final JSFunction _messages;
  late final JSFunction _loaded;
  bool _hasLoaded = false;
  @override
  void initState() {
    super.initState();
    widget.gameBridge?.addListener(_sendGameEvent);
    _type = 'campus-explorer-${UniqueKey()}';
    _frame =
        web.HTMLIFrameElement()
          ..src =
              'assets/assets/models/campus/viewer.html?campus=${widget.campus}&experience=${widget.experience}&reducedMotion=${widget.reducedMotion ? 1 : 0}'
          ..title = 'キャンパスの3D探索'
          ..allowFullscreen = true
          ..allow = 'fullscreen'
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%';
    _messages =
        ((web.Event e) {
          final m = e as web.MessageEvent;
          if (!mounted ||
              m.origin != web.window.location.origin ||
              m.source != _frame.contentWindow) {
            return;
          }
          final raw = m.data.dartify();
          Object? value = raw;
          if (raw is String && raw.startsWith('{') && raw.length <= 65536) {
            try {
              value = jsonDecode(raw);
            } catch (_) {
              return;
            }
          }
          if (value is Map &&
              value['type'] == 'campus-course' &&
              value['direction'] is String) {
            widget.gameBridge?.onCourseChanged?.call(
              value['direction'] as String,
            );
          }
          if (value is Map &&
              value['type'] == 'campus-overlay' &&
              value['open'] is bool) {
            widget.gameBridge?.onOverlayChanged?.call(value['open'] as bool);
          }
          if (value is Map && value['type'] == 'campus-game-open') {
            widget.gameBridge?.onOpen?.call(
              value['direction'] is String
                  ? value['direction'] as String
                  : null,
            );
          }
          if (value is Map && value['type'] == 'campus-game') {
            unawaited(
              widget.gameBridge?.onRequest(Map<String, dynamic>.from(value)) ??
                  Future<void>.value(),
            );
          }
          if (value == 'campus-fullscreen-toggle') {
            widget.onToggleFullscreen?.call();
          }
          if (value == 'campus-reset-viewer') {
            widget.onResetViewer?.call();
          }
          if (value == 'campus-fullscreen-exit') {
            widget.onExitFullscreen?.call();
          }
        }).toJS;
    _loaded =
        ((web.Event e) {
          if (_hasLoaded) {
            widget.gameBridge?.onDetached();
          }
          _hasLoaded = true;
          _sendFullscreen();
        }).toJS;
    web.window.addEventListener('message', _messages);
    _frame.addEventListener('load', _loaded);
    ui_web.platformViewRegistry.registerViewFactory(_type, (_) => _frame);
  }

  void _sendGameEvent() {
    final event = widget.gameBridge?.event;
    if (event != null) {
      _frame.contentWindow?.postMessage(
        event.jsify(),
        web.window.location.origin.toJS,
      );
    }
  }

  void _sendFullscreen() => _frame.contentWindow?.postMessage(
    ('campus-fullscreen:${widget.fullscreen ? 1 : 0}').toJS,
    web.window.location.origin.toJS,
  );
  @override
  void didUpdateWidget(covariant Campus3dView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullscreen != widget.fullscreen) _sendFullscreen();
  }

  @override
  void dispose() {
    widget.gameBridge?.removeListener(_sendGameEvent);
    widget.gameBridge?.onDetached();
    web.window.removeEventListener('message', _messages);
    _frame.removeEventListener('load', _loaded);
    _frame.contentWindow?.postMessage(
      'campus-dispose'.toJS,
      web.window.location.origin.toJS,
    );
    _frame.src = 'about:blank';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _type);
}
