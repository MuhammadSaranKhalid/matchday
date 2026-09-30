import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildChipComponent() {
  return WidgetbookComponent(
    name: 'SelectionChip',
    useCases: [
      WidgetbookUseCase(
        name: 'States',
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SelectionChip(
                  label: 'All',
                  selected: true,
                  onPressed: () {},
                ),
                SelectionChip(
                  label: 'Upcoming',
                  selected: false,
                  count: 4,
                  onPressed: () {},
                ),
                SelectionChip(
                  label: 'Completed',
                  selected: false,
                  count: 12,
                  onPressed: () {},
                ),
                SelectionChip(
                  label: 'With Icon',
                  selected: true,
                  icon: const Icon(Icons.star, size: 16),
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
