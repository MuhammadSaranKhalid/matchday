import 'package:flutter/material.dart';

import '../foundation/radii.dart';
import '../theme/app_theme.dart';

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
  final layout = context.layout;
  final scheme = context.colorScheme;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor ?? scheme.surface,
    barrierColor: scheme.shadow.withValues(alpha: 0.45),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(layout.cardRadius + 8),
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
    final layout = context.layout;
    final scheme = context.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * maxHeightFraction;
    final keyboardInset = mediaQuery.viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(layout.cardRadius + 8),
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
                SizedBox(height: layout.inlineGap / 2),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outline,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                  ),
                ),
                SizedBox(height: layout.inlineGap / 2),
              ],
              if (header != null) ...[
                header!,
                Divider(height: 1, color: scheme.outlineVariant),
              ],
              Flexible(
                child: Padding(
                  padding: padding ??
                      EdgeInsets.symmetric(
                        horizontal: layout.screenGutter,
                        vertical: layout.inlineGap,
                      ),
                  child: body,
                ),
              ),
              if (footer != null) ...[
                Divider(height: 1, color: scheme.outlineVariant),
                Padding(
                  padding: EdgeInsets.all(layout.cardPadding),
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
