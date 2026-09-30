import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/spacing.dart';

/// Standard sticky bottom action footer pinned above navigation or keyboard insets.
class StickyFooter extends StatelessWidget {
  const StickyFooter({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.topBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool topBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? Palette.paper,
        border: topBorder
            ? const Border(top: BorderSide(color: Palette.hairline))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: child,
      ),
    );
  }
}
