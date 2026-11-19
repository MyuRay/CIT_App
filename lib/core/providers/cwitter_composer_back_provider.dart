import 'package:hooks_riverpod/hooks_riverpod.dart';

/// コンポーザーの戻る/離脱処理。
///
/// 戻り値は「この後の画面遷移を続行してよいか」を表す。
/// 破棄が確定した（または破棄するドラフトが無い）場合は true、
/// ユーザーがキャンセルした、または投稿処理中などで離脱を止める場合は false。
typedef CwitterComposerBackHandler = Future<bool> Function();

class CwitterComposerBackGate {
  const CwitterComposerBackGate({
    this.shouldIntercept = false,
    this.handleBack,
  });

  final bool shouldIntercept;
  final CwitterComposerBackHandler? handleBack;
}

class CwitterComposerBackGateNotifier
    extends Notifier<CwitterComposerBackGate> {
  bool _isDisposed = false;

  @override
  CwitterComposerBackGate build() {
    ref.onDispose(() => _isDisposed = true);
    return const CwitterComposerBackGate();
  }

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
    if (_isDisposed) return;
    state = const CwitterComposerBackGate();
  }
}

final cwitterComposerBackGateProvider =
    NotifierProvider<CwitterComposerBackGateNotifier, CwitterComposerBackGate>(
      CwitterComposerBackGateNotifier.new,
    );
