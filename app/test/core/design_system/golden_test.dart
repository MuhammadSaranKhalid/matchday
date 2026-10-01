import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/design_system/design_system.dart';

Widget _wrap(Widget child, {Size size = const Size(400, 600)}) {
  return MaterialApp(
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Palette.paper,
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('Design System Golden Tests', () {
    testWidgets('ActionButton variants and sizes', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ActionButton(
                  label: 'Primary Large',
                  variant: ActionButtonVariant.primary,
                  size: ControlSize.large,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                ActionButton(
                  label: 'Primary Standard',
                  variant: ActionButtonVariant.primary,
                  size: ControlSize.standard,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                ActionButton(
                  label: 'Primary Compact',
                  variant: ActionButtonVariant.primary,
                  size: ControlSize.compact,
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                ActionButton(
                  label: 'Secondary Button',
                  variant: ActionButtonVariant.secondary,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                ActionButton(
                  label: 'Ghost Button',
                  variant: ActionButtonVariant.ghost,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                ActionButton(
                  label: 'Destructive Button',
                  variant: ActionButtonVariant.destructive,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                const ActionButton(
                  label: 'Disabled Button',
                  variant: ActionButtonVariant.primary,
                  onPressed: null,
                ),
              ],
            ),
          ),
          size: const Size(400, 800),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/action_button_variants.png'),
      );
    });

    testWidgets('SegmentedControl', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SegmentedControl<String>(
                options: const [
                  SegmentOption(value: 'confirmed', label: 'Confirmed (4)'),
                  SegmentOption(value: 'past', label: 'Past Matches'),
                ],
                value: 'confirmed',
                onChanged: (_) {},
              ),
            ),
          ),
          size: const Size(400, 300),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/segmented_control.png'),
      );
    });

    testWidgets('EmptyState variants', (tester) async {
      tester.view.physicalSize = const Size(500, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: EmptyState.fromIconData(
              iconData: Icons.sports_cricket_outlined,
              title: 'No Matches Scheduled',
              description:
                  'Create your first match or explore tournaments in your area to get started.',
              primaryAction: StateAction(
                label: 'Create Match',
                onPressed: () {},
              ),
              secondaryAction: StateAction(
                label: 'Find Tournaments',
                onPressed: () {},
              ),
            ),
          ),
          size: const Size(400, 600),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/empty_state.png'),
      );
    });

    testWidgets('StatusBadge tones', (tester) async {
      tester.view.physicalSize = const Size(500, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StatusBadge(label: 'LIVE', tone: StatusTone.live),
                StatusBadge(label: 'COMPLETED', tone: StatusTone.success),
                StatusBadge(label: 'DELAYED', tone: StatusTone.warning),
                StatusBadge(label: 'UPCOMING', tone: StatusTone.neutral),
                StatusBadge(label: 'FORFEIT', tone: StatusTone.destructive),
                StatusBadge(label: 'CAPTAIN', tone: StatusTone.ink, pill: true),
              ],
            ),
          ),
          size: const Size(400, 400),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/status_badge_tones.png'),
      );
    });

    testWidgets('SearchField variants', (tester) async {
      tester.view.physicalSize = const Size(500, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SearchField(
                  hintText: 'Standard search...',
                  variant: SearchFieldVariant.standard,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                SearchField(
                  hintText: 'Pill search...',
                  variant: SearchFieldVariant.pill,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                SearchField(
                  hintText: 'Prominent search...',
                  variant: SearchFieldVariant.prominent,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          size: const Size(400, 400),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/search_field_variants.png'),
      );
    });

    testWidgets('ConfirmationDialog', (tester) async {
      tester.view.physicalSize = const Size(500, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const ConfirmationDialog(
            icon: Icons.delete_outline_rounded,
            title: 'Delete Tournament?',
            body:
                'This will permanently remove the tournament schedule and all recorded match data. This action cannot be undone.',
            confirmLabel: 'Delete Tournament',
            cancelLabel: 'Keep Tournament',
            destructive: true,
          ),
          size: const Size(400, 500),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/confirmation_dialog.png'),
      );
    });

    testWidgets('PushHeader', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              PushHeader(
                title: 'Match Details',
                subtitle: 'Lahore Stadium • Final Round',
              ),
            ],
          ),
          size: const Size(400, 200),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/push_header.png'),
      );
    });
  });
}
