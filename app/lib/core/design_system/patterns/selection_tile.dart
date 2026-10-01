import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Standardized list selection tile with leading icon/avatar, title, subtitle,
/// and trailing check/radio/chevron affordance.
class SelectionTile extends StatelessWidget {
  const SelectionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Semantics(
      selected: selected,
      button: true,
      label: '$title${subtitle != null ? ', $subtitle' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(layout.controlRadius),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: layout.minimumTapTarget,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: layout.compactCardPadding,
                vertical: layout.inlineGap,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: layout.compactCardPadding),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: textTheme.bodyLarge?.copyWith(
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: scheme.onSurface,
                              ) ??
                              TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: scheme.onSurface,
                              ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ) ??
                                TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: layout.compactCardPadding),
                    trailing!,
                  ] else if (selected) ...[
                    SizedBox(width: layout.compactCardPadding),
                    Icon(
                      Icons.check,
                      size: 20,
                      color: scheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
