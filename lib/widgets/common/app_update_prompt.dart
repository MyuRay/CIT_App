import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/app_update_service.dart';

/// Wait until an existing tutorial, consent dialog, or bottom sheet has closed.
class AppUpdateNavigatorObserver extends NavigatorObserver with ChangeNotifier {
  final _routes = <Route<dynamic>>[];

  bool get canShowPrompt => _routes.isNotEmpty && _routes.last is PageRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    notifyListeners();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    notifyListeners();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    notifyListeners();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    }
    notifyListeners();
  }
}

Future<bool> openAppUpdateStore(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// One check and at most one prompt per process launch. Resuming from the store
/// does not reopen the prompt. No network work blocks the first app frame.
class AppUpdatePromptHost extends StatefulWidget {
  const AppUpdatePromptHost({
    super.key,
    required this.navigatorKey,
    required this.observer,
    required this.checkForUpdate,
    required this.child,
    this.openStore = openAppUpdateStore,
    this.onNoUpdate,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final AppUpdateNavigatorObserver observer;
  final Future<AppUpdateInfo?> Function() checkForUpdate;
  final Future<bool> Function(Uri) openStore;
  final VoidCallback? onNoUpdate;
  final Widget child;

  @override
  State<AppUpdatePromptHost> createState() => _AppUpdatePromptHostState();
}

class _AppUpdatePromptHostState extends State<AppUpdatePromptHost>
    with WidgetsBindingObserver {
  AppUpdateInfo? _pendingUpdate;
  Timer? _idleTimer;
  bool _didShow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.observer.addListener(_schedulePrompt);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    AppUpdateInfo? update;
    try {
      update = await widget.checkForUpdate();
    } catch (_) {
      // Keep startup usable even if a custom check throws.
    }
    if (!mounted) return;
    if (update == null) {
      widget.onNoUpdate?.call();
      return;
    }
    _pendingUpdate = update;
    _schedulePrompt();
  }

  @override
  void didUpdateWidget(covariant AppUpdatePromptHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observer != widget.observer) {
      oldWidget.observer.removeListener(_schedulePrompt);
      widget.observer.addListener(_schedulePrompt);
      _schedulePrompt();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedulePrompt();
  }

  void _schedulePrompt() {
    _idleTimer?.cancel();
    if (_didShow || _pendingUpdate == null) return;
    // Leave room for startup navigation and subsequent tutorial dialogs.
    _idleTimer = Timer(const Duration(milliseconds: 750), _showIfReady);
  }

  void _showIfReady() {
    if (!mounted || _didShow || _pendingUpdate == null) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null || !widget.observer.canShowPrompt) return;
    _didShow = true;
    unawaited(
      showDialog<void>(
        context: navigator.context,
        builder:
            (_) => AppUpdateDialog(
              update: _pendingUpdate!,
              openStore: widget.openStore,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    widget.observer.removeListener(_schedulePrompt);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({
    super.key,
    required this.update,
    this.openStore = openAppUpdateStore,
  });

  final AppUpdateInfo update;
  final Future<bool> Function(Uri) openStore;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _opening = false;
  bool _failed = false;

  Future<void> _openStore() async {
    setState(() {
      _opening = true;
      _failed = false;
    });
    var opened = false;
    try {
      opened = await widget
          .openStore(widget.update.storeUrl)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
    if (!mounted) return;
    if (opened) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _opening = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      scrollable: true,
      icon: Icon(Icons.system_update_rounded, color: colors.primary),
      title: const Text('アップデートのお知らせ'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '新しいバージョン ${widget.update.latestVersion} が公開されています。\n'
            '最新版にアップデートしてご利用ください。',
          ),
          const SizedBox(height: 12),
          Text(
            '現在のバージョン：${widget.update.currentVersion}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_failed) ...[
            const SizedBox(height: 12),
            Text(
              'ストアを開けませんでした。もう一度お試しください。',
              style: TextStyle(color: colors.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('あとで'),
        ),
        FilledButton(
          onPressed: _opening ? null : _openStore,
          child: Text(_opening ? 'ストアを開いています…' : '更新する'),
        ),
      ],
    );
  }
}
