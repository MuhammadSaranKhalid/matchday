import 'package:flutter/material.dart';

import '../actions/action_button.dart';
import '../../theme/app_theme.dart';

/// Semantic classification of error states.
enum ErrorStateKind {
  generic,
  offline,
  permission,
}

/// Standardized error state pattern.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    this.description,
    this.kind = ErrorStateKind.generic,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.icon,
  });

  /// Convenience factory to construct [ErrorState] directly from an [IconData].
  factory ErrorState.fromIconData({
    Key? key,
    required String title,
    IconData? icon,
    IconData? iconData,
    String? description,
    ErrorStateKind kind = ErrorStateKind.generic,
    VoidCallback? onRetry,
    String retryLabel = 'Try again',
  }) {
    assert(icon != null || iconData != null, 'Either icon or iconData must be provided');
    return ErrorState(
      key: key,
      title: title,
      icon: Icon(icon ?? iconData!),
      description: description,
      kind: kind,
      onRetry: onRetry,
      retryLabel: retryLabel,
    );
  }

  final String title;
  final String? description;
  final ErrorStateKind kind;
  final VoidCallback? onRetry;
  final String retryLabel;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final status = context.statusColors;
    final textTheme = context.textTheme;

    final defaultIcon = switch (kind) {
      ErrorStateKind.generic => Icons.error_outline,
      ErrorStateKind.offline => Icons.wifi_off_outlined,
      ErrorStateKind.permission => Icons.lock_outline,
    };

    final iconWidget = icon ?? Icon(defaultIcon, size: 28, color: status.live);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: status.liveSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: status.liveBorder),
                ),
                alignment: Alignment.center,
                child: IconTheme.merge(
                  data: IconThemeData(size: 28, color: status.live),
                  child: iconWidget,
                ),
              ),
              SizedBox(height: layout.cardPadding),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.01,
                    ) ??
                    TextStyle(
                      fontFamily: 'Inter Tight',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.01,
                    ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                SizedBox(height: layout.inlineGap),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                        fontSize: 13.5,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      ) ??
                      TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
              if (onRetry != null) ...[
                SizedBox(height: layout.sectionGap),
                ActionButton(
                  label: retryLabel,
                  onPressed: onRetry,
                  size: ControlSize.compact,
                  expand: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
