import 'package:flutter/material.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildHeadersComponent() {
  return WidgetbookComponent(
    name: 'Headers',
    useCases: [
      WidgetbookUseCase(
        name: 'PushHeader',
        builder: (context) {
          return PushHeader(
            title: 'Tournament Details',
            subtitle: 'Champions Trophy 2026',
            action: ActionIconButton(
              icon: Icons.share,
              onPressed: () {},
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'WizardHeader',
        builder: (context) {
          return const WizardHeader(
            title: 'Tournament Rules',
            eyebrow: 'Step 3 of 4',
            description: 'Configure over limits, powerplays, and ball specifications.',
            currentStep: 3,
            totalSteps: 4,
          );
        },
      ),
      WidgetbookUseCase(
        name: 'ComposerHeader',
        builder: (context) {
          return ComposerHeader(
            title: 'New Post',
            actionLabel: 'Publish',
            onAction: () {},
          );
        },
      ),
    ],
  );
}
