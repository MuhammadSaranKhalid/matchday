import 'package:flutter/material.dart';

import '../foundation/palette.dart';
import '../foundation/radii.dart';
import '../foundation/spacing.dart';

/// Selectable choice card pattern used in setup wizards and configuration sheets.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String? description;
  final Widget? icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? Palette.ink : Palette.line;
    final borderWidth = selected ? 1.5 : 1.0;
    final bgColor = selected ? Palette.paper : Palette.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: icon!,
                ),
                const SizedBox(width: Spacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Palette.ink,
                            ),
                          ),
                        ),
                        if (badge != null) badge!,
                      ],
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.4,
                          color: Palette.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Palette.ink : Palette.soft,
                      width: selected ? 6 : 1.5,
                    ),
                    color: Palette.surface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
