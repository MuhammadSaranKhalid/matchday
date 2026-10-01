import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

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
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    final borderColor = selected ? scheme.primary : scheme.outline;
    final borderWidth = selected ? 1.5 : 1.0;
    final bgColor = selected ? scheme.surface : scheme.surface;

    return Semantics(
      selected: selected,
      button: true,
      label: '$title${description != null ? ', $description' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(layout.cardRadius),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: layout.minimumTapTarget,
            ),
            child: Container(
              padding: EdgeInsets.all(layout.cardPadding),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(layout.cardRadius),
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
                    SizedBox(width: layout.compactCardPadding),
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
                                style: textTheme.titleSmall?.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface,
                                    ) ??
                                    TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface,
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
                            style: textTheme.bodySmall?.copyWith(
                                  height: 1.4,
                                  color: scheme.onSurfaceVariant,
                                ) ??
                                TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  height: 1.4,
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: layout.compactCardPadding),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? scheme.primary : scheme.outline,
                          width: selected ? 6 : 1.5,
                        ),
                        color: scheme.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
