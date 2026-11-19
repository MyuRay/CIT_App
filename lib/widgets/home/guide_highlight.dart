import 'dart:math' as math;
import 'package:flutter/material.dart';

class GuideHighlight {
  const GuideHighlight(this.rect, this.shape);
  final Rect rect;
  final ShapeBorder shape;
}

GuideHighlight? resolveGuideHighlight(BuildContext context, GlobalKey key) {
  final anchor = key.currentContext;
  final overlay =
      Navigator.of(
        context,
        rootNavigator: true,
      ).overlay?.context.findRenderObject();
  if (anchor is! Element || overlay is! RenderBox) return null;
  Rect? bounds(Element element) {
    final box = element.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize || box.size.isEmpty)
      return null;
    return box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  }

  Element? find(Element root, bool Function(Widget) matches) {
    if (matches(root.widget)) return root;
    Element? result;
    root.visitChildElements((child) {
      result ??= find(child, matches);
    });
    return result;
  }

  final avatar = find(anchor, (widget) => widget is CircleAvatar);
  if (avatar != null) {
    final rect = bounds(avatar);
    return rect == null ? null : GuideHighlight(rect, const CircleBorder());
  }
  Element control = anchor;
  anchor.visitAncestorElements((ancestor) {
    if (ancestor.widget is NavigationDestination ||
        ancestor.widget is IconButton ||
        ancestor.widget is ButtonStyleButton ||
        ancestor.widget is Tab) {
      control = ancestor;
      return false;
    }
    // Never turn the whole app bar into a button highlight.
    return ancestor.widget is! AppBar && ancestor.widget is! NavigationBar;
  });
  if (control.widget is NavigationDestination) {
    final indicator = find(control, (widget) => widget is NavigationIndicator);
    if (indicator != null) {
      final widget = indicator.widget as NavigationIndicator;
      final rect = bounds(indicator);
      if (rect != null)
        return GuideHighlight(
          rect,
          widget.shape ??
              RoundedRectangleBorder(borderRadius: widget.borderRadius),
        );
    }
  }
  final material = find(
    control,
    (widget) => widget is Material && widget.shape != null,
  );
  final rect = material == null ? bounds(control) : bounds(material);
  if (rect == null) return null;
  final shape = material == null ? null : (material.widget as Material).shape;
  return GuideHighlight(
    rect,
    shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            math.min(12, rect.shortestSide / 2),
          ),
        ),
  );
}
