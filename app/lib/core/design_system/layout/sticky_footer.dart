import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
    final layout = context.layout;
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(layout.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.surface,
        border: topBorder
            ? Border(top: BorderSide(color: scheme.outlineVariant))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: child,
      ),
    );
  }
}
