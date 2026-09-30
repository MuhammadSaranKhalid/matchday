import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildSearchFieldComponent() {
  return WidgetbookComponent(
    name: 'SearchField',
    useCases: [
      WidgetbookUseCase(
        name: 'Variants',
        builder: (context) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                SearchField(
                  variant: SearchFieldVariant.standard,
                  hintText: 'Standard search field...',
                ),
                SizedBox(height: 16),
                SearchField(
                  variant: SearchFieldVariant.pill,
                  hintText: 'Pill search (Inbox)...',
                ),
                SizedBox(height: 16),
                SearchField(
                  variant: SearchFieldVariant.prominent,
                  hintText: 'Prominent search (Explore)...',
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}
