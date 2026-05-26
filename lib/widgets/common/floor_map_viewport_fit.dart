import 'package:flutter/material.dart';

/// フロア図の表示領域に **図全体** が収まるよう等比スケールする（[InteractiveViewer] の子に使う）。
///
/// 検索タブのピン付き表示・校舎シートのサムネタップ全画面の双方で共有する。
Widget floorMapViewportFitHost({required Widget child}) {
  return SizedBox.expand(
    child: FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: child,
    ),
  );
}
