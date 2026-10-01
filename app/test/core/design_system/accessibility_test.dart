import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/design_system/design_system.dart';

void main() {
  group('Accessibility Guideline Verification', () {
    testWidgets('ActionButton meets tap target guidelines across sizes',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: ActionButton(
                label: 'Save',
                size: ControlSize.compact,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('ActionIconButton meets tap target guidelines',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: ActionIconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Go back',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('SelectionChip meets tap target guidelines', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SelectionChip(
                label: 'Upcoming',
                selected: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('SectionHeader action meets minimum tap target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SectionHeader(
              title: 'Fixtures',
              actionLabel: 'See all',
              onAction: () {},
            ),
          ),
        ),
      );

      final inkWellBox = tester.renderObject<RenderBox>(find.byType(InkWell));
      expect(inkWellBox.size.height, greaterThanOrEqualTo(48.0));
      expect(inkWellBox.size.width, greaterThanOrEqualTo(48.0));
    });

    testWidgets('SelectionTile meets tap target and carries selection semantics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SelectionTile(
                title: 'Lahore Stadium',
                selected: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(SelectionTile));
      expect(box.size.height, greaterThanOrEqualTo(48.0));
      expect(
        find.descendant(
          of: find.byType(SelectionTile),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.selected == true,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('ChoiceCard meets tap target and carries selection semantics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: ChoiceCard(
                title: 'T20 Match',
                description: '20 overs per side',
                selected: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(ChoiceCard));
      expect(box.size.height, greaterThanOrEqualTo(48.0));
      expect(
        find.descendant(
          of: find.byType(ChoiceCard),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.selected == true,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('SegmentedControl meets tap target and exposes item semantics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SegmentedControl<String>(
                options: const [
                  SegmentOption(value: 'confirmed', label: 'Confirmed'),
                  SegmentOption(value: 'past', label: 'Past'),
                ],
                value: 'confirmed',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final inkWells = tester.renderObjectList<RenderBox>(find.byType(InkWell));
      for (final box in inkWells) {
        expect(box.size.height, greaterThanOrEqualTo(48.0));
      }
    });
  });
}
