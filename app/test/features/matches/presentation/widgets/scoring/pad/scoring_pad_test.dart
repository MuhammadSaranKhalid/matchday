import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/pad/scoring_pad.dart';

void main() {
  Widget buildPad({
    ValueChanged<int>? onRun,
    VoidCallback? onWicket,
    ValueChanged<BallKind>? onExtra,
    bool busy = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ScoringPad(
          onRun: onRun ?? (_) {},
          onWicket: onWicket ?? () {},
          onExtra: onExtra ?? (_) {},
          busy: busy,
        ),
      ),
    );
  }

  group('ScoringPad', () {
    testWidgets('renders all run buttons, wicket button, and extras row',
        (tester) async {
      await tester.pumpWidget(buildPad());

      expect(find.text('•'), findsOneWidget); // Dot
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);

      expect(find.text('WIDE'), findsOneWidget);
      expect(find.text('NO-BALL'), findsOneWidget);
      expect(find.text('BYE'), findsOneWidget);
      expect(find.text('LEG-BYE'), findsOneWidget);
    });

    testWidgets('tapping run buttons fires onRun callback', (tester) async {
      int? recordedRun;
      await tester.pumpWidget(buildPad(
        onRun: (r) => recordedRun = r,
      ));

      await tester.tap(find.text('•'));
      expect(recordedRun, 0);

      await tester.tap(find.text('1'));
      expect(recordedRun, 1);

      await tester.tap(find.text('4'));
      expect(recordedRun, 4);

      await tester.tap(find.text('6'));
      expect(recordedRun, 6);
    });

    testWidgets('tapping W fires onWicket callback', (tester) async {
      var wicketTapped = false;
      await tester.pumpWidget(buildPad(
        onWicket: () => wicketTapped = true,
      ));

      await tester.tap(find.text('W'));
      expect(wicketTapped, isTrue);
    });

    testWidgets('tapping extra buttons fires onExtra callback', (tester) async {
      BallKind? recordedExtra;
      await tester.pumpWidget(buildPad(
        onExtra: (k) => recordedExtra = k,
      ));

      await tester.tap(find.text('WIDE'));
      expect(recordedExtra, BallKind.wide);

      await tester.tap(find.text('NO-BALL'));
      expect(recordedExtra, BallKind.noBall);

      await tester.tap(find.text('BYE'));
      expect(recordedExtra, BallKind.bye);

      await tester.tap(find.text('LEG-BYE'));
      expect(recordedExtra, BallKind.legBye);
    });

    testWidgets('when busy, taps do not fire callbacks', (tester) async {
      var runCalled = false;
      var wicketCalled = false;
      var extraCalled = false;

      await tester.pumpWidget(buildPad(
        busy: true,
        onRun: (_) => runCalled = true,
        onWicket: () => wicketCalled = true,
        onExtra: (_) => extraCalled = true,
      ));

      await tester.tap(find.text('1'));
      expect(runCalled, isFalse);

      await tester.tap(find.text('W'));
      expect(wicketCalled, isFalse);

      await tester.tap(find.text('WIDE'));
      expect(extraCalled, isFalse);
    });
  });
}
