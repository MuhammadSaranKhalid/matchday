import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/features/matches/presentation/widgets/challenge/step_review.dart';
import 'package:matchday/features/matches/presentation/widgets/challenge/step_when_where.dart';
import 'package:matchday/features/matches/presentation/widgets/wizard/wizard_kit.dart';

/// The app-wide InputDecorationTheme fills every field white and gives it a
/// 1.5px rule. That is right for a standalone field and wrong for one nested
/// inside a container that already draws a border — you get a box inside a
/// box. Setting only `border: InputBorder.none` does not help, because
/// `enabledBorder`, `focusedBorder` and `filled` resolve from the theme
/// independently. These lock the fix in.
void main() {
  /// Pumped under the real theme, or the trap cannot reproduce.
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          theme: buildCirckTheme(),
          home: Scaffold(body: child),
        ),
      );

  InputDecoration decorationOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).decoration!;

  test('bareInput answers every border the theme would supply', () {
    final d = bareInput();
    expect(d.filled, isFalse);
    expect(d.border, InputBorder.none);
    expect(d.enabledBorder, InputBorder.none);
    expect(d.focusedBorder, InputBorder.none);
    expect(d.disabledBorder, InputBorder.none);
    expect(d.errorBorder, InputBorder.none);
    expect(d.focusedErrorBorder, InputBorder.none);
  });

  testWidgets('the venue field draws no box of its own', (tester) async {
    final venue = TextEditingController();
    addTearDown(venue.dispose);

    await pump(
      tester,
      StepWhenWhere(
        day: DateTime.now(),
        time: 16 * 60 + 30,
        flexible: false,
        venueController: venue,
        onDay: (_) {},
        onTime: (_) {},
        onFlexible: (_) {},
      ),
    );

    final d = decorationOf(tester);
    expect(d.filled, isFalse, reason: 'a white fill inside the container');
    expect(d.enabledBorder, InputBorder.none);
    expect(d.focusedBorder, InputBorder.none);
  });

  testWidgets('the review note field draws no box of its own', (tester) async {
    final note = TextEditingController();
    addTearDown(note.dispose);

    await pump(
      tester,
      StepReview(
        team: null,
        formatLine: '20 overs · Tape-ball · 11-a-side',
        whenLine: 'Tomorrow · 4:30 PM',
        whereLine: 'To be agreed',
        noteController: note,
        onEditFormat: () {},
        onEditWhen: () {},
        onEditWhere: () {},
      ),
    );

    final d = decorationOf(tester);
    expect(d.filled, isFalse);
    expect(d.enabledBorder, InputBorder.none);
    expect(d.focusedBorder, InputBorder.none);
  });

  testWidgets('a scheduling-only review shows no XI row', (tester) async {
    final note = TextEditingController();
    addTearDown(note.dispose);

    await pump(
      tester,
      StepReview(
        team: null,
        formatLine: '20 overs · Tape-ball · 11-a-side',
        whenLine: 'Tomorrow · 4:30 PM',
        whereLine: 'To be agreed',
        noteController: note,
        onEditFormat: () {},
        onEditWhen: () {},
        onEditWhere: () {},
      ),
    );

    expect(find.text('FORMAT'), findsOneWidget);
    expect(find.text('WHEN'), findsOneWidget);
    expect(find.text('WHERE'), findsOneWidget);
    expect(find.text('YOUR XI'), findsNothing);
    expect(find.text('EDIT'), findsNWidgets(3));
  });

  group('WizardFooter', () {
    /// The button is the r14 box inside the footer shell.
    BoxDecoration buttonOf(WidgetTester tester) {
      final box = tester.widgetList<Container>(find.byType(Container)).firstWhere(
        (c) {
          final d = c.decoration;
          return d is BoxDecoration &&
              d.borderRadius == BorderRadius.circular(14);
        },
      );
      return box.decoration! as BoxDecoration;
    }

    testWidgets('a blocked step reads as unfinished, not broken',
        (tester) async {
      await pump(
        tester,
        WizardFooter(label: 'Continue', enabled: false, onPressed: () {}),
      );

      final d = buttonOf(tester);
      expect(
        d.color,
        CkColors.paper2,
        reason: 'a dimmed ink block looks like a broken button',
      );
      expect(d.border, isNotNull);
    });

    testWidgets('a live step is ink', (tester) async {
      await pump(tester, WizardFooter(label: 'Continue', onPressed: () {}));
      expect(buttonOf(tester).color, CkColors.ink);
    });
  });
}
