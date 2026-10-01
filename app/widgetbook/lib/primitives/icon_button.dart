import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildIconButtonComponent() {
  return WidgetbookComponent(
    name: 'ActionIconButton',
    useCases: [
      WidgetbookUseCase(
        name: 'Variants',
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                ActionIconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Standard Back',
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                ActionIconButton.outlined(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Outlined Filters',
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                ActionIconButton.subtle(
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'Subtle Options',
                  onPressed: () {},
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}
