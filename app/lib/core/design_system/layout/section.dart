import 'package:flutter/material.dart';

import '../foundation/spacing.dart';
import '../patterns/section_header.dart';

/// Standard structural section layout pattern.
///
/// Owns the vertical rhythm between the section header, content, and the next
/// section (`context.layout.sectionGap`).
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.child,
    this.title,
    this.eyebrow,
    this.header,
    this.actionLabel,
    this.onAction,
    this.spacing = Spacing.xs,
    this.bottomGap = Spacing.xl,
  });

  final Widget child;
  final String? title;
  final String? eyebrow;
  final Widget? header;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double spacing;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    final effectiveHeader = header ??
        (title != null
            ? SectionHeader(
                title: title!,
                eyebrow: eyebrow,
                actionLabel: actionLabel,
                onAction: onAction,
              )
            : null);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (effectiveHeader != null) ...[
            effectiveHeader,
            SizedBox(height: spacing),
          ],
          child,
        ],
      ),
    );
  }
}
