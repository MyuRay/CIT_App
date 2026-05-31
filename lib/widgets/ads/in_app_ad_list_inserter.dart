import 'package:flutter/material.dart';

/// [items] を [interval] 件ごとに [adBuilder] のウィジェットを差し込む
List<Widget> interleaveWidgetsWithBannerAds<T>({
  required List<T> items,
  required int interval,
  required Widget Function(T item) itemBuilder,
  required Widget Function() adBuilder,
  EdgeInsetsGeometry adPadding = const EdgeInsets.only(bottom: 8),
}) {
  if (items.isEmpty || interval <= 0) {
    return items.map(itemBuilder).toList();
  }

  final result = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    result.add(itemBuilder(items[i]));
    if ((i + 1) % interval == 0) {
      result.add(Padding(padding: adPadding, child: adBuilder()));
    }
  }
  return result;
}

/// 既存のウィジェットリストに広告を差し込む
List<Widget> interleaveWidgetListWithBannerAds({
  required List<Widget> items,
  required int interval,
  required Widget ad,
  EdgeInsetsGeometry adPadding = const EdgeInsets.only(bottom: 8),
}) {
  if (items.isEmpty || interval <= 0) return items;

  final result = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    result.add(items[i]);
    if ((i + 1) % interval == 0) {
      result.add(Padding(padding: adPadding, child: ad));
    }
  }
  return result;
}
