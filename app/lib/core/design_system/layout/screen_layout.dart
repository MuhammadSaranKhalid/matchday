import 'package:flutter/material.dart';

import '../foundation/palette.dart';

/// Standard non-scrolling screen scaffold layout.
///
/// Encapsulates page background, top navigation header slot, safe area handling,
/// bottom navigation bar, and optional pinned sticky footer.
class ScreenLayout extends StatelessWidget {
  const ScreenLayout({
    super.key,
    required this.body,
    this.header,
    this.bottomNavigationBar,
    this.stickyFooter,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final PreferredSizeWidget? header;
  final Widget? bottomNavigationBar;
  final Widget? stickyFooter;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Palette.paper,
      appBar: header,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        top: header == null,
        bottom: stickyFooter == null,
        child: Column(
          children: [
            Expanded(child: body),
            if (stickyFooter != null) stickyFooter!,
          ],
        ),
      ),
    );
  }
}
