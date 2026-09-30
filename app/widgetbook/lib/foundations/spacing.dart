import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildSpacingComponent() {
  return WidgetbookComponent(
    name: 'Spacing',
    useCases: [
      WidgetbookUseCase(
        name: 'Scale & Rhythms',
        builder: (context) {
          final scale = [
            ('xxs', Spacing.xxs),
            ('xs', Spacing.xs),
            ('sm', Spacing.sm),
            ('md', Spacing.md),
            ('lg', Spacing.lg),
            ('xl', Spacing.xl),
            ('xxl', Spacing.xxl),
            ('xxxl', Spacing.xxxl),
            ('huge', Spacing.huge),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: scale.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text('${s.$1} (${s.$2}pt)'),
                      ),
                      Container(
                        width: s.$2,
                        height: 24,
                        color: Palette.ink,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    ],
  );
}
