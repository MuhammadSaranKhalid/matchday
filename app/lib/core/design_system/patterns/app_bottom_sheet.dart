import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/radii.dart';
import '../foundation/spacing.dart';

/// Launches a standardized Matchday bottom sheet modal.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor ?? Palette.paper,
    barrierColor: Palette.ink.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Radii.modal),
      ),
    ),
    builder: builder,
  );
}

/// Standardized bottom sheet shell container.
///
/// Owns top corner radius, drag handle affordance, safe area handling, keyboard
/// insets, and sticky header/footer composition.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    this.header,
    required this.body,
    this.footer,
    this.showDragHandle = true,
    this.padding,
    this.maxHeightFraction = 0.88,
  });

  final Widget? header;
  final Widget body;
  final Widget? footer;
  final bool showDragHandle;
  final EdgeInsetsGeometry? padding;
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * maxHeightFraction;
    final keyboardInset = mediaQuery.viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Palette.paper,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Radii.modal),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDragHandle) ...[
                const SizedBox(height: Spacing.xs),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Palette.line,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
              ],
              if (header != null) ...[
                header!,
                const Divider(height: 1, color: Palette.line),
              ],
              Flexible(
                child: Padding(
                  padding: padding ??
                      const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.sm,
                      ),
                  child: body,
                ),
              ),
              if (footer != null) ...[
                const Divider(height: 1, color: Palette.line),
                Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: footer!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
