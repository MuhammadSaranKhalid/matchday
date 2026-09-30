import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/spacing.dart';

/// Standard scrolling screen layout.
///
/// Encapsulates consistent screen gutters, top/bottom insets, scroll physics,
/// pull-to-refresh coordination, and optional sticky action footers.
class ScrollScreenLayout extends StatelessWidget {
  const ScrollScreenLayout({
    super.key,
    required this.children,
    this.header,
    this.padding,
    this.stickyFooter,
    this.onRefresh,
    this.controller,
    this.physics,
    this.backgroundColor,
  });

  final List<Widget> children;
  final PreferredSizeWidget? header;
  final EdgeInsetsGeometry? padding;
  final Widget? stickyFooter;
  final RefreshCallback? onRefresh;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    Widget list = ListView(
      controller: controller,
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      padding: padding ??
          const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.md,
            Spacing.md,
            Spacing.xl,
          ),
      children: children,
    );

    if (onRefresh != null) {
      list = RefreshIndicator(
        onRefresh: onRefresh!,
        color: Palette.ink,
        backgroundColor: Palette.surface,
        child: list,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? Palette.paper,
      appBar: header,
      body: SafeArea(
        top: header == null,
        bottom: stickyFooter == null,
        child: Column(
          children: [
            Expanded(child: list),
            if (stickyFooter != null) stickyFooter!,
          ],
        ),
      ),
    );
  }
}
