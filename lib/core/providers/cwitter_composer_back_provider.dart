import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef CwitterComposerBackHandler = Future<void> Function();

class CwitterComposerBackGate {
  const CwitterComposerBackGate({
    this.shouldIntercept = false,
    this.handleBack,
  });

  final bool shouldIntercept;
  final CwitterComposerBackHandler? handleBack;
}

class CwitterComposerBackGateNotifier extends Notifier<CwitterComposerBackGate> {
  @override
  CwitterComposerBackGate build() => const CwitterComposerBackGate();

  void set({
    required bool isTabVisible,
    required bool isInputActive,
    CwitterComposerBackHandler? handleBack,
  }) {
    state = CwitterComposerBackGate(
      shouldIntercept: isTabVisible && isInputActive,
      handleBack: handleBack,
    );
  }

  void clear() {
    state = const CwitterComposerBackGate();
  }
}

final cwitterComposerBackGateProvider =
    NotifierProvider<CwitterComposerBackGateNotifier, CwitterComposerBackGate>(
  CwitterComposerBackGateNotifier.new,
);
