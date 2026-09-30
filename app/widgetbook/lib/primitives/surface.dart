import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildSurfaceComponent() {
  return WidgetbookComponent(
    name: 'Surface',
    useCases: [
      WidgetbookUseCase(
        name: 'Variants & Densities',
        builder: (context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 240,
                  child: Surface(
                    variant: SurfaceVariant.outlined,
                    density: SurfaceDensity.standard,
                    onTap: () {},
                    child: const Text('Outlined Standard'),
                  ),
                ),
                const SizedBox(
                  width: 240,
                  child: Surface(
                    variant: SurfaceVariant.plain,
                    density: SurfaceDensity.compact,
                    child: Text('Plain Compact'),
                  ),
                ),
                const SizedBox(
                  width: 240,
                  child: Surface(
                    variant: SurfaceVariant.subtle,
                    density: SurfaceDensity.comfortable,
                    child: Text('Subtle Comfortable'),
                  ),
                ),
                const SizedBox(
                  width: 240,
                  child: Surface(
                    variant: SurfaceVariant.raised,
                    density: SurfaceDensity.standard,
                    child: Text('Raised Card'),
                  ),
                ),
                const SizedBox(
                  width: 240,
                  child: Surface(
                    variant: SurfaceVariant.accent,
                    density: SurfaceDensity.standard,
                    child: Text('Accent Surface'),
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
