import 'dart:convert';
import '../../services/campus_game/campus_race_best_store.dart';
import '../../services/campus_game/campus_game_view_bridge.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _Campus3dViewState extends State<Campus3dView>
    with WidgetsBindingObserver {
  HttpServer? _server;
  WebViewController? _controller;
  bool _failed = false;
  bool _disposed = false;
  bool _paused = false;
  bool _hasStarted = false;
  static const _assets = {
    '/pop_courses.json': 'application/json; charset=utf-8',
    '/region.json': 'application/json; charset=utf-8',
    '/region-source-manifest.json': 'application/json; charset=utf-8',
    '/region/photo16-58254-25803.jpg': 'image/jpeg',
    '/region/photo16-58254-25804.jpg': 'image/jpeg',
    '/region/photo16-58254-25806.jpg': 'image/jpeg',
    '/region/photo16-58254-25807.jpg': 'image/jpeg',
    '/region/photo16-58254-25808.jpg': 'image/jpeg',
    '/region/photo16-58254-25811.jpg': 'image/jpeg',
    '/region/photo16-58254-25812.jpg': 'image/jpeg',
    '/region/photo16-58255-25803.jpg': 'image/jpeg',
    '/region/photo16-58255-25804.jpg': 'image/jpeg',
    '/region/photo16-58255-25805.jpg': 'image/jpeg',
    '/region/photo16-58255-25807.jpg': 'image/jpeg',
    '/region/photo16-58255-25811.jpg': 'image/jpeg',
    '/region/photo16-58256-25804.jpg': 'image/jpeg',
    '/region/photo16-58256-25807.jpg': 'image/jpeg',
    '/region/photo16-58256-25809.jpg': 'image/jpeg',
    '/region/photo16-58257-25803.jpg': 'image/jpeg',
    '/region/photo16-58257-25806.jpg': 'image/jpeg',
    '/region/photo16-58257-25807.jpg': 'image/jpeg',
    '/region/photo16-58257-25808.jpg': 'image/jpeg',
    '/region/photo16-58258-25804.jpg': 'image/jpeg',
    '/region/photo16-58258-25805.jpg': 'image/jpeg',
    '/region/photo16-58258-25807.jpg': 'image/jpeg',
    '/region/photo16-58258-25810.jpg': 'image/jpeg',
    '/region/photo16-58258-25811.jpg': 'image/jpeg',
    '/region/photo16-58259-25803.jpg': 'image/jpeg',
    '/region/photo16-58259-25804.jpg': 'image/jpeg',
    '/region/photo16-58259-25805.jpg': 'image/jpeg',
    '/region/photo16-58259-25806.jpg': 'image/jpeg',
    '/region/photo16-58259-25807.jpg': 'image/jpeg',
    '/region/photo16-58259-25808.jpg': 'image/jpeg',
    '/region/photo16-58259-25811.jpg': 'image/jpeg',
    '/region/photo16-58259-25812.jpg': 'image/jpeg',
    '/region/photo18-233025-103242.jpg': 'image/jpeg',
    '/region/photo18-233025-103243.jpg': 'image/jpeg',
    '/region/photo18-233026-103242.jpg': 'image/jpeg',
    '/region/photo18-233026-103244.jpg': 'image/jpeg',
    '/region/photo18-233027-103242.jpg': 'image/jpeg',
    '/region/photo18-233027-103243.jpg': 'image/jpeg',
    '/region/photo18-233027-103244.jpg': 'image/jpeg',
    '/region/photo18-233027-103245.jpg': 'image/jpeg',
    '/region/photo18-233028-103242.jpg': 'image/jpeg',
    '/region/photo18-233028-103243.jpg': 'image/jpeg',
    '/region/photo18-233029-103244.jpg': 'image/jpeg',
    '/region/photo18-233030-103217.jpg': 'image/jpeg',
    '/region/photo18-233030-103218.jpg': 'image/jpeg',
    '/region/photo18-233030-103219.jpg': 'image/jpeg',
    '/region/photo18-233030-103220.jpg': 'image/jpeg',
    '/region/photo18-233031-103218.jpg': 'image/jpeg',
    '/region/photo18-233031-103219.jpg': 'image/jpeg',
    '/region/photo18-233031-103220.jpg': 'image/jpeg',
    '/region/photo18-233032-103217.jpg': 'image/jpeg',
    '/region/photo18-233032-103218.jpg': 'image/jpeg',
    '/region/photo18-233032-103219.jpg': 'image/jpeg',
    '/region/photo18-233033-103221.jpg': 'image/jpeg',
    '/region/photo18-233034-103217.jpg': 'image/jpeg',
    '/region/photo18-233034-103218.jpg': 'image/jpeg',
    '/region/photo18-233034-103219.jpg': 'image/jpeg',
    '/region/photo18-233034-103220.jpg': 'image/jpeg',
    '/region/photo18-233034-103221.jpg': 'image/jpeg',
    '/viewer.html': 'text/html; charset=utf-8',
    '/campus_engine.js': 'application/javascript',
    '/tsudanuma-campus.glb': 'model/gltf-binary',
    '/shinnarashino-campus.glb': 'model/gltf-binary',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.gameBridge?.addListener(_sendGameEvent);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      if (_disposed) {
        await server.close(force: true);
        return;
      }
      _server = server;
      server.listen((request) => unawaited(_serve(request)));
      final uri = Uri.parse(
        'http://127.0.0.1:${server.port}/viewer.html?campus=${widget.campus}&experience=${widget.experience}&reducedMotion=${widget.reducedMotion ? 1 : 0}',
      );
      final controller = WebViewController();
      await controller.addJavaScriptChannel(
        'CampusHost',
        onMessageReceived: (m) {
          if (!mounted || _disposed) return;
          unawaited(_handleGameMessage(m.message));
          if (m.message == 'campus-fullscreen-toggle') {
            widget.onToggleFullscreen?.call();
          }
          if (m.message == 'campus-source:gsi') {
            unawaited(
              launchUrl(
                Uri.parse('https://maps.gsi.go.jp/development/ichiran.html'),
                mode: LaunchMode.externalApplication,
              ),
            );
          }
          if (m.message == 'campus-source:osm') {
            unawaited(
              launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
                mode: LaunchMode.externalApplication,
              ),
            );
          }
          if (m.message == 'campus-reset-viewer') {
            widget.onResetViewer?.call();
          }
          if (m.message == 'campus-fullscreen-exit') {
            widget.onExitFullscreen?.call();
          }
        },
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(const Color(0xffe8eef2));
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (r) {
            final destination = Uri.tryParse(r.url);
            return destination?.scheme == uri.scheme &&
                    destination?.host == uri.host &&
                    destination?.port == uri.port
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            if (_hasStarted) {
              widget.gameBridge?.onDetached();
            }
            _hasStarted = true;
          },
          onPageFinished: (_) {
            unawaited(_loadBests());
            _execute('window.campusExplorer?.pause($_paused)');
            _execute(
              'window.campusExplorer?.setFullscreen(${widget.fullscreen})',
            );
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame == true && mounted) {
              setState(() => _failed = true);
            }
          },
        ),
      );
      if (_disposed) {
        return;
      }
      _controller = controller;
      await controller.loadRequest(uri);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _serve(HttpRequest request) async {
    try {
      final type = _assets[request.uri.path];
      if (type == null || request.method != 'GET') {
        request.response.statusCode = HttpStatus.notFound;
      } else {
        final data = await rootBundle.load(
          'assets/models/campus${request.uri.path}',
        );
        request.response.headers.set(HttpHeaders.contentTypeHeader, type);
        request.response.headers.set(
          HttpHeaders.cacheControlHeader,
          'no-store',
        );
        request.response.add(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
      await request.response.close();
    } catch (_) {
      try {
        await request.response.close();
      } catch (_) {}
    }
  }

  void _sendGameEvent() {
    final event = widget.gameBridge?.event;
    if (event != null && !_disposed) {
      _execute('window.campusExplorer?.gameOnline(${jsonEncode(event)})');
    }
  }

  final CampusRaceBestStore _bestStore = CampusRaceBestStore();
  Future<void> _loadBests() async {
    final bests = await _bestStore.load();
    if (!_disposed) {
      _execute('window.campusExplorer?.setRaceBests(${jsonEncode(bests)})');
    }
  }

  Future<void> _handleGameMessage(String message) async {
    if (!message.startsWith('{') || message.length > 65536) return;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map) return;
      final value = Map<String, dynamic>.from(decoded);
      if (value['type'] == 'campus-course' && value['direction'] is String) {
        widget.gameBridge?.onCourseChanged?.call(value['direction'] as String);
      } else if (value['type'] == 'campus-overlay' && value['open'] is bool) {
        widget.gameBridge?.onOverlayChanged?.call(value['open'] as bool);
      } else if (value['type'] == 'campus-game-open') {
        widget.gameBridge?.onOpen?.call(
          value['direction'] is String ? value['direction'] as String : null,
        );
      } else if (value['type'] == 'campus-game') {
        await widget.gameBridge?.onRequest(value);
      } else if (value['type'] == 'campus-bus-best') {
        final saved = await _bestStore.save(
          value['key'],
          value['milliseconds'],
        );
        if (!_disposed) {
          _execute(
            'window.campusExplorer?.gameOnline(${jsonEncode({'type': 'campus-best-save', 'ok': saved, 'key': value['key'] is String ? value['key'] : null})})',
          );
        }
      }
    } catch (_) {
      /* malformed viewer messages are ignored */
    }
  }

  void _execute(String source) {
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.runJavaScript(source).catchError((Object _) {}));
    }
  }

  @override
  void didUpdateWidget(covariant Campus3dView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullscreen != widget.fullscreen) {
      _execute('window.campusExplorer?.setFullscreen(${widget.fullscreen})');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    _execute('window.campusExplorer?.pause($_paused)');
  }

  @override
  void dispose() {
    _disposed = true;
    widget.gameBridge?.removeListener(_sendGameEvent);
    widget.gameBridge?.onDetached();
    WidgetsBinding.instance.removeObserver(this);
    _execute('window.campusExplorer?.dispose()');
    if (_server != null) {
      unawaited(_server!.close(force: true));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(child: Text('3D表示を開始できません。上部のリセットで再試行してください。'));
    }
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(controller: controller);
  }
}
