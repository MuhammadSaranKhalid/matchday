import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/design_system/design_system.dart';

void main() {
  group('EmptyState & StateRegion', () {
    testWidgets('renders firstRun empty state with primary and secondary action',
        (tester) async {
      var primaryPressed = false;
      var secondaryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StateRegion(
              child: EmptyState.fromIconData(
                kind: EmptyStateKind.firstRun,
                icon: Icons.sports_cricket,
                title: 'No matches yet',
                description: 'Start a new match or challenge a squad.',
                primaryAction: StateAction(
                  label: 'Start match',
                  onPressed: () => primaryPressed = true,
                ),
                secondaryAction: StateAction(
                  label: 'Browse teams',
                  onPressed: () => secondaryPressed = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No matches yet'), findsOneWidget);
      expect(find.text('Start a new match or challenge a squad.'), findsOneWidget);
      expect(find.text('Start match'), findsOneWidget);
      expect(find.text('Browse teams'), findsOneWidget);

      await tester.tap(find.text('Start match'));
      expect(primaryPressed, isTrue);

      await tester.tap(find.text('Browse teams'));
      expect(secondaryPressed, isTrue);
    });
  });

  group('ErrorState', () {
    testWidgets('renders title, description and triggers retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ErrorState(
              kind: ErrorStateKind.offline,
              title: 'No connection',
              description: 'Please check your internet settings.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Please check your internet settings.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });
  });

  group('ConfirmationDialog', () {
    testWidgets('confirm returns true and cancel returns false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ActionButton(
                  label: 'Open Dialog',
                  onPressed: () async {
                    result = await showConfirmationDialog(
                      context,
                      icon: Icons.delete_outline,
                      title: 'Delete fixture?',
                      body: 'This will remove the scheduled fixture.',
                      confirmLabel: 'Delete',
                      cancelLabel: 'Keep fixture',
                      destructive: true,
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete fixture?'), findsOneWidget);
      expect(find.text('Keep fixture'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('AppBottomSheet', () {
    testWidgets('renders sheet shell with header, body, and footer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ActionButton(
                  label: 'Open Sheet',
                  onPressed: () {
                    showAppBottomSheet<void>(
                      context,
                      builder: (ctx) => const AppBottomSheet(
                        header: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Sheet Title'),
                        ),
                        body: Text('Sheet Body Content'),
                        footer: Text('Sheet Footer'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Title'), findsOneWidget);
      expect(find.text('Sheet Body Content'), findsOneWidget);
      expect(find.text('Sheet Footer'), findsOneWidget);
    });
  });

  group('Navigation Headers', () {
    testWidgets('PushHeader renders title, subtitle, and triggers back',
        (tester) async {
      var backPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            appBar: PushHeader(
              title: 'Tournament Details',
              subtitle: 'Lahore Cup 2026',
              onBack: () => backPressed = true,
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Tournament Details'), findsOneWidget);
      expect(find.text('Lahore Cup 2026'), findsOneWidget);

      await tester.tap(find.byType(ActionIconButton));
      expect(backPressed, isTrue);
    });

    testWidgets('WizardHeader computes progress fraction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: WizardHeader(
              title: 'Select Teams',
              eyebrow: 'Step 2 of 4',
              currentStep: 2,
              totalSteps: 4,
            ),
          ),
        ),
      );

      expect(find.text('Select Teams'), findsOneWidget);
      expect(find.text('STEP 2 OF 4'), findsOneWidget);
    });

    testWidgets('ComposerHeader renders title and action button', (tester) async {
      var submitted = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            appBar: ComposerHeader(
              title: 'Create Post',
              actionLabel: 'Publish',
              onAction: () => submitted = true,
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Create Post'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);

      await tester.tap(find.text('Publish'));
      expect(submitted, isTrue);
    });
  });

  group('Layout Components', () {
    testWidgets('ScrollScreenLayout and Section layout rhythm', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const ScrollScreenLayout(
            children: [
              Section(
                title: 'Upcoming',
                eyebrow: 'Fixtures',
                child: Text('Match 1'),
              ),
              Section(
                title: 'Past Results',
                child: Text('Match 2'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('FIXTURES'), findsOneWidget);
      expect(find.text('Match 1'), findsOneWidget);
      expect(find.text('Past Results'), findsOneWidget);
      expect(find.text('Match 2'), findsOneWidget);
    });
  });
}
