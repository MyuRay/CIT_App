import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../services/ui/ui_feedback_service.dart';

/// 画面上のタップ操作を検知して軽い触覚フィードバックを鳴らす。
class UiFeedbackListener extends StatefulWidget {
  const UiFeedbackListener({super.key, required this.child});

  final Widget child;

  @override
  State<UiFeedbackListener> createState() => _UiFeedbackListenerState();
}

class _UiFeedbackListenerState extends State<UiFeedbackListener> {
  int? _activePointer;
  Offset? _downPosition;
  Duration? _downTime;

  static const _tapSlop = 18.0;
  static const _maxTapDuration = Duration(milliseconds: 450);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _resetPointer(),
      child: widget.child,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.trackpad) return;
    _activePointer = event.pointer;
    _downPosition = event.position;
    _downTime = event.timeStamp;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _downPosition == null) return;
    if ((event.position - _downPosition!).distance > _tapSlop) {
      _resetPointer();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer ||
        _downPosition == null ||
        _downTime == null) {
      return;
    }

    final duration = event.timeStamp - _downTime!;
    _resetPointer();

    if (duration > _maxTapDuration) return;
    if (_shouldSkipFeedback(event.position, event.viewId)) return;

    UiFeedbackService.tap();
  }

  bool _shouldSkipFeedback(Offset globalPosition, int viewId) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, globalPosition, viewId);

    for (final entry in result.path) {
      final target = entry.target;
      final typeName = target.runtimeType.toString();

      if (target is RenderEditable) return true;
      if (typeName.contains('RenderSlider')) return true;
      if (typeName.contains('RenderCupertinoSlider')) return true;
      if (typeName.contains('RenderCupertinoSwitch')) return true;
      if (typeName.contains('RenderSwitch')) return true;
    }

    return false;
  }

  void _resetPointer() {
    _activePointer = null;
    _downPosition = null;
    _downTime = null;
  }
}

/// TabBar / BottomNavigationBar 用の onTap ラッパー
VoidCallback uiFeedbackTabHandler(VoidCallback action) {
  return () {
    UiFeedbackService.tabSwitch();
    action();
  };
}

ValueChanged<int> uiFeedbackTabIndexHandler(ValueChanged<int> onChanged) {
  return (index) {
    UiFeedbackService.tabSwitch();
    onChanged(index);
  };
}
