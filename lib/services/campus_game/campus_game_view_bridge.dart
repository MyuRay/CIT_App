import 'package:flutter/foundation.dart';

/// Delivers host responses without exposing authentication to the viewer.
class CampusGameViewBridge extends ChangeNotifier {
  CampusGameViewBridge({
    required this.onRequest,
    required this.onDetached,
    this.onOpen,
    this.onOverlayChanged,
    this.onCourseChanged,
  });
  final Future<void> Function(Map<String, dynamic>) onRequest;
  final VoidCallback onDetached;
  final void Function(String? direction)? onOpen;
  final ValueChanged<bool>? onOverlayChanged;
  final ValueChanged<String>? onCourseChanged;
  Map<String, dynamic>? event;
  bool _closed = false;
  void send(Map<String, dynamic> value) {
    if (_closed) return;
    event = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
