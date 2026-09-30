import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildTypographyComponent() {
  return WidgetbookComponent(
    name: 'Typography',
    useCases: [
      WidgetbookUseCase(
        name: 'TextTheme Roles',
        builder: (context) {
          final t = context.theme.textTheme;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display Small', style: t.displaySmall),
                const SizedBox(height: 12),
                Text('Headline Small', style: t.headlineSmall),
                const SizedBox(height: 12),
                Text('Title Large', style: t.titleLarge),
                const SizedBox(height: 12),
                Text('Title Medium', style: t.titleMedium),
                const SizedBox(height: 12),
                Text('Title Small', style: t.titleSmall),
                const SizedBox(height: 12),
                Text('Body Large - Standard paragraph body copy', style: t.bodyLarge),
                const SizedBox(height: 12),
                Text('Body Medium - Secondary body copy', style: t.bodyMedium),
                const SizedBox(height: 12),
                Text('Label Large', style: t.labelLarge),
                const SizedBox(height: 12),
                Text('Label Medium', style: t.labelMedium),
              ],
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Cricket Mono Tokens',
        builder: (context) {
          final mono = context.textTokens;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EYEBROW METRIC', style: mono.eyebrow),
                const SizedBox(height: 8),
                Text('Score: 194/4 (18.2 ov)', style: mono.score),
                const SizedBox(height: 8),
                Text('Run Rate: 10.58 rpo', style: mono.metric),
                const SizedBox(height: 8),
                Text('TIME: 14:32 PST', style: mono.metadata),
              ],
            ),
          );
        },
      ),
    ],
  );
}
