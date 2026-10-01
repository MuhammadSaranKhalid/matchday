import 'package:flutter/material.dart';

import '../primitives/action_icon_button.dart';
import '../theme/app_theme.dart';

/// Standardized multi-step wizard header pattern.
///
/// Encapsulates back navigation, eyebrow step counter, progress indicator,
/// prominent screen title, and optional description.
class WizardHeader extends StatelessWidget {
  const WizardHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.onBack,
    this.currentStep,
    this.totalSteps,
    this.actions,
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final VoidCallback? onBack;
  final int? currentStep;
  final int? totalSteps;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTokens = context.textTokens;
    final textTheme = context.textTheme;

    final hasProgress = currentStep != null && totalSteps != null && totalSteps! > 0;
    final progressFraction = hasProgress
        ? (currentStep! / totalSteps!).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasProgress)
          Container(
            height: 3,
            width: double.infinity,
            color: scheme.outlineVariant,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progressFraction,
              child: Container(color: scheme.primary),
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: layout.screenGutter,
            vertical: layout.itemGap,
          ),
          child: Row(
            children: [
              ActionIconButton.fromIconData(
                Icons.arrow_back,
                variant: ActionIconButtonVariant.subtle,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
              ),
              const Spacer(),
              if (actions != null) ...actions!,
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.screenGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: textTokens.eyebrow.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.02,
                    ) ??
                    TextStyle(
                      fontFamily: 'Inter Tight',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.02,
                    ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                SizedBox(height: layout.inlineGap),
                Text(
                  description!,
                  style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      ) ??
                      TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
              SizedBox(height: layout.cardPadding),
            ],
          ),
        ),
      ],
    );
  }
}
