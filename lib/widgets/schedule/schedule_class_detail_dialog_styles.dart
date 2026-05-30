import 'package:flutter/material.dart';

/// 時間割講義詳細ダイアログ下部の共通フォントサイズ。
const double scheduleClassDetailDialogActionFontSize = 15;

const EdgeInsets scheduleClassDetailDialogActionPadding = EdgeInsets.symmetric(
  horizontal: 6,
  vertical: 10,
);

const double scheduleClassDetailDialogActionMinHeight = 48;

/// アクション一行の共通文字スタイル（メモ／閉じる／教室／保存で揃える）。
TextStyle scheduleClassDetailDialogActionTextStyle({Color? foreground}) =>
    TextStyle(
      fontSize: scheduleClassDetailDialogActionFontSize,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: foreground,
    );

/// ダイアログ下部アクションを同一行・幅いっぱいに並べる。
Widget scheduleClassDetailDialogActionsWrap({required List<Widget> children}) {
  if (children.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    ),
  );
}

/// ボタンラベル（同一行内で幅に合わせて縮小）。
Widget scheduleClassDetailDialogActionLabel(String label) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(label, maxLines: 1),
  );
}

/// 「教室の場所を調べる」：青ベタ・白文字（枠線なし）。
ButtonStyle scheduleClassLookupRoomButtonStyle() {
  final blue = Colors.blue.shade700;
  return FilledButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: blue,
    elevation: 0,
    shadowColor: Colors.transparent,
    padding: scheduleClassDetailDialogActionPadding,
    minimumSize: const Size(0, scheduleClassDetailDialogActionMinHeight),
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
    minimumSize: const Size(0, scheduleClassDetailDialogActionMinHeight),
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
    minimumSize: const Size(0, scheduleClassDetailDialogActionMinHeight),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: scheduleClassDetailDialogActionTextStyle(
      foreground: scheme.onPrimary,
    ),
  );
}
