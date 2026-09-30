import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildColorsComponent() {
  return WidgetbookComponent(
    name: 'Colors',
    useCases: [
      WidgetbookUseCase(
        name: 'Brand & Surface Ramp',
        builder: (context) {
          final colors = [
            ('Ink', Palette.ink),
            ('Ink 2', Palette.ink2),
            ('Muted', Palette.muted),
            ('Soft', Palette.soft),
            ('Paper', Palette.paper),
            ('Paper 2', Palette.paper2),
            ('Surface', Palette.surface),
            ('Canvas', Palette.canvas),
            ('Line', Palette.line),
            ('Hairline', Palette.hairline),
            ('Red', Palette.red),
            ('Red Surface', Palette.redSurface),
            ('Green', Palette.green),
            ('Green Surface', Palette.greenSurface),
            ('Amber', Palette.amber),
            ('Cream', Palette.cream),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: colors.map((c) {
                return SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: c.$2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Palette.line),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.$1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Palette.ink,
                        ),
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
