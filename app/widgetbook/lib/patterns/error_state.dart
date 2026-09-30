import 'package:matchday/core/design_system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildErrorStateComponent() {
  return WidgetbookComponent(
    name: 'ErrorState',
    useCases: [
      WidgetbookUseCase(
        name: 'Generic Error',
        builder: (context) {
          return ErrorState(
            title: 'Couldn’t load tournament details',
            description: 'A transient network error occurred. Please try again.',
            onRetry: () {},
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Offline State',
        builder: (context) {
          return ErrorState(
            kind: ErrorStateKind.offline,
            title: 'No connection',
            description: 'You are currently offline. Check your internet connection.',
            onRetry: () {},
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Permission State',
        builder: (context) {
          return ErrorState(
            kind: ErrorStateKind.permission,
            title: 'Access Restricted',
            description: 'You do not have organizer permissions to view this screen.',
            retryLabel: 'Request access',
            onRetry: () {},
          );
        },
      ),
    ],
  );
}
