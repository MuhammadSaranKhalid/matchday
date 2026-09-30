import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildButtonComponent() {
  return WidgetbookComponent(
    name: 'ActionButton',
    useCases: [
      WidgetbookUseCase(
        name: 'All Variants & States',
        builder: (context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 260,
                  child: ActionButton(
                    label: 'Primary Standard',
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: ActionButton.secondary(
                    label: 'Secondary Standard',
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: ActionButton.ghost(
                    label: 'Ghost Standard',
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: ActionButton.destructive(
                    label: 'Destructive Standard',
                    onPressed: () {},
                  ),
                ),
                const SizedBox(
                  width: 260,
                  child: ActionButton(
                    label: 'Disabled',
                    onPressed: null,
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: ActionButton(
                    label: 'Loading',
                    loading: true,
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: ActionButton(
                    label: 'Compact Button',
                    size: ControlSize.compact,
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: ActionButton(
                    label: 'Large CTA Button',
                    size: ControlSize.large,
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: ActionButton(
                    label: 'With Icon',
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: ActionButton(
                    label: 'Very Long Action Button Label That Truncates Nicely',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}
