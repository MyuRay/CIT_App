import 'package:flutter/widgets.dart';

class AdSlotPosition extends InheritedWidget {
  const AdSlotPosition({super.key, required this.index, required super.child});
  final int index;
  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdSlotPosition>()?.index ?? 0;
  @override
  bool updateShouldNotify(AdSlotPosition oldWidget) => index != oldWidget.index;
}
