import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/spacing.dart';
import '../primitives/action_icon_button.dart';

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
            color: Palette.hairline,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progressFraction,
              child: Container(color: Palette.ink),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              ActionIconButton.subtle(
                icon: Icons.arrow_back,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
              ),
              const Spacer(),
              if (actions != null) ...actions!,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Palette.muted,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter Tight',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                  letterSpacing: -0.02,
                ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  description!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.45,
                    color: Palette.muted,
                  ),
                ),
              ],
              const SizedBox(height: Spacing.md),
            ],
          ),
        ),
      ],
    );
  }
}
