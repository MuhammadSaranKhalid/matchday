import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildBottomSheetComponent() {
  return WidgetbookComponent(
    name: 'AppBottomSheet',
    useCases: [
      WidgetbookUseCase(
        name: 'Standard Modal Shell',
        builder: (context) {
          return Center(
            child: ActionButton(
              label: 'Launch Bottom Sheet',
              expand: false,
              onPressed: () {
                showAppBottomSheet<void>(
                  context,
                  builder: (ctx) => AppBottomSheet(
                    header: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Filter Matches',
                        style: context.theme.textTheme.titleMedium,
                      ),
                    ),
                    body: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select format, pitch type, and status.'),
                        SizedBox(height: 16),
                        SelectionChip(label: 'T20', selected: true),
                      ],
                    ),
                    footer: ActionButton(
                      label: 'Apply Filters',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    ],
  );
}
