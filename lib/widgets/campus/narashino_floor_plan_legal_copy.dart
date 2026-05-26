import 'package:flutter/material.dart';

/// 教室マップのフロア図表示などに使う免責・注意文言。

/// ボトムシートのタブ直下などに表示できる免責（全画面下部の文言とは別）。
const String kNarashinoLocalFloorPlanDisclaimer =
    'アプリ内で表示されるフロア図は実際の区画等と異なる場合があるため、実際の地図情報等と照らし合わせながらご活用ください';

/// 全画面拡大の**下段**（免責の下）に表示する避難・消防の注意。
const String kNarashinoFloorPlanEvacuationNotice =
    '避難・消防の指示はキャンパス内の公示に従ってください。';

Widget _disclaimerBox() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      kNarashinoLocalFloorPlanDisclaimer,
      style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.25),
      textAlign: TextAlign.center,
    ),
  );
}

Widget _evacuationBox() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.amber.shade900.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      kNarashinoFloorPlanEvacuationNotice,
      style: TextStyle(
        color: Colors.amber.shade50,
        fontSize: 11,
        height: 1.25,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

/// タップで開く全画面フロア図（ピンなし）の下部：免責 → 避難・消防。
Widget narashinoFloorPlanFullscreenLegalFooter() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _disclaimerBox(),
      const SizedBox(height: 8),
      _evacuationBox(),
    ],
  );
}

/// ピン付きフロア図ダイアログの下部：免責 → 避難・消防。
///
/// キャンパス・講義棟・階・教室は [AppBar] 側にまとめるため、ここでは位置説明を載せない。
Widget narashinoFloorPlanPinDialogLegalFooter() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _disclaimerBox(),
      const SizedBox(height: 8),
      _evacuationBox(),
    ],
  );
}
