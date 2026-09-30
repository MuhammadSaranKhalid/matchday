import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/design_system/design_system.dart';
import 'package:matchday/core/widgets/ck_button.dart';
import 'package:matchday/core/widgets/ck_text_field.dart';

void main() {
  group('ActionButton', () {
    testWidgets('renders primary button and handles tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ActionButton(
              label: 'Submit',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.text('Submit'));
      expect(tapped, isTrue);
    });

    testWidgets('shows spinner when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: ActionButton(
              label: 'Submit',
              loading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('compact button maintains accessible touch target',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ActionButton(
              label: 'Follow',
              size: ControlSize.compact,
              expand: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      final renderBox = tester.renderObject<RenderBox>(find.byType(ActionButton));
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
      expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
    });

    testWidgets('CkButton compatibility wrapper delegates to ActionButton',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CkButton(
              label: 'Legacy',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Legacy'), findsOneWidget);
      await tester.tap(find.text('Legacy'));
      expect(tapped, isTrue);
    });
  });

  group('ActionIconButton', () {
    testWidgets('maintains minimum 48x48 tap target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ActionIconButton(
              icon: Icons.arrow_back,
              onPressed: () {},
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(ActionIconButton));
      expect(box.size.width, greaterThanOrEqualTo(48.0));
      expect(box.size.height, greaterThanOrEqualTo(48.0));
    });
  });

  group('Surface', () {
    testWidgets('renders child and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Surface(
              onTap: () => tapped = true,
              density: SurfaceDensity.compact,
              variant: SurfaceVariant.outlined,
              child: const Text('Surface Content'),
            ),
          ),
        ),
      );

      expect(find.text('Surface Content'), findsOneWidget);
      await tester.tap(find.text('Surface Content'));
      expect(tapped, isTrue);
    });
  });

  group('StatusBadge', () {
    testWidgets('renders label and tone correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: StatusBadge(
              label: 'LIVE',
              tone: StatusTone.live,
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
    });
  });

  group('SelectionChip', () {
    testWidgets('renders selected and unselected chip with counter',
        (tester) async {
      var selected = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: SelectionChip(
                  label: 'Upcoming',
                  selected: selected,
                  count: 5,
                  onPressed: () => setState(() => selected = !selected),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.text('Upcoming'));
      expect(selected, isTrue);
    });
  });

  group('TextInput', () {
    testWidgets('renders label, input, and handles input', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TextInput(
              label: 'Team Name',
              hint: 'Enter team name',
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Team Name'), findsOneWidget);
      expect(find.text('Enter team name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Lahore Lions');
      expect(controller.text, 'Lahore Lions');
    });

    testWidgets('CkTextField compatibility wrapper delegates to TextInput',
        (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CkTextField(
              label: 'Legacy Field',
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Legacy Field'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Test Text');
      expect(controller.text, 'Test Text');
    });
  });

  group('SearchField', () {
    testWidgets('handles typing and clear button', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SearchField(
              controller: controller,
              variant: SearchFieldVariant.pill,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Cricket');
      await tester.pump();
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(controller.text, '');
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('Avatar', () {
    testWidgets('renders fallback initials monogram when no image provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Avatar(
              mono: 'MK',
              size: 40,
              tone: AvatarTone.ink,
            ),
          ),
        ),
      );

      expect(find.text('MK'), findsOneWidget);
    });
  });
}
