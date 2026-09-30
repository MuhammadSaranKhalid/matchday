import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildBadgeComponent() {
  return WidgetbookComponent(
    name: 'StatusBadge',
    useCases: [
      WidgetbookUseCase(
        name: 'Tones',
        builder: (context) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StatusBadge(label: 'LIVE', tone: StatusTone.live),
                StatusBadge(label: 'FINAL', tone: StatusTone.neutral),
                StatusBadge(label: 'CAPTAIN', tone: StatusTone.ink),
                StatusBadge(label: 'SUCCESS', tone: StatusTone.success),
                StatusBadge(label: 'WARNING', tone: StatusTone.warning),
                StatusBadge(label: 'CANCELLED', tone: StatusTone.destructive),
                StatusBadge(label: 'PILL TONE', tone: StatusTone.live, pill: true),
              ],
            ),
          );
        },
      ),
    ],
  );
}
