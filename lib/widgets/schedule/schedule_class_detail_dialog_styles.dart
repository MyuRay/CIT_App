import 'package:flutter/material.dart';

/// 時間割講義詳細ダイアログ下部の共通フォントサイズ。
const double scheduleClassDetailDialogActionFontSize = 11;

const EdgeInsets scheduleClassDetailDialogActionPadding = EdgeInsets.symmetric(
  horizontal: 8,
  vertical: 8,
);

/// アクション一行の共通文字スタイル（メモ／閉じる／教室／保存で揃える）。
TextStyle scheduleClassDetailDialogActionTextStyle({Color? foreground}) =>
    TextStyle(
      fontSize: scheduleClassDetailDialogActionFontSize,
      fontWeight: FontWeight.w500,
      height: 1.12,
      color: foreground,
    );

/// 「教室の場所を調べる」：青ベタ・白文字（枠線なし）。
ButtonStyle scheduleClassLookupRoomButtonStyle() {
  final blue = Colors.blue.shade700;
  return FilledButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: blue,
    elevation: 0,
    shadowColor: Colors.transparent,
    padding: scheduleClassDetailDialogActionPadding,
    minimumSize: const Size(0, 38),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: scheduleClassDetailDialogActionTextStyle(
      foreground: Colors.white,
    ),
  );
}

/// 「メモを編集」「閉じる」「キャンセル」など。
ButtonStyle scheduleClassDetailDialogSecondaryActionStyle(
  BuildContext context,
) {
  final scheme = Theme.of(context).colorScheme;
  return TextButton.styleFrom(
    foregroundColor: scheme.primary,
    padding: scheduleClassDetailDialogActionPadding,
    minimumSize: const Size(0, 38),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: scheduleClassDetailDialogActionTextStyle(
      foreground: scheme.primary,
    ),
  );
}

/// メモ保存の [FilledButton]（文字サイズを他と揃える）。
ButtonStyle scheduleClassDetailDialogSaveButtonStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    backgroundColor: scheme.primary,
    foregroundColor: scheme.onPrimary,
    elevation: 0,
    padding: scheduleClassDetailDialogActionPadding,
    minimumSize: const Size(0, 38),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: scheduleClassDetailDialogActionTextStyle(
      foreground: scheme.onPrimary,
    ),
  );
}
