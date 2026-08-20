// The striker card's name budget.
//
// Real accounts have long display names — the one that exposed this renders
// as "muhammadsarankhalid". On the striker card it was truncated to
// "muhammadsa..." because the card spent horizontal space on an avatar, the
// name, AND a "·STRIKE" text label — while a red strike dot was already
// painted in the card's corner saying the same thing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/scoring_board.dart';

const _longName = 'muhammadsarankhalid';

Widget _host({required bool onStrike, double width = 190}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: BatterCard(
              name: _longName,
              stats: const BatterStats(runs: 17, balls: 4, fours: 1, sixes: 2),
              onStrike: onStrike,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('the strike label no longer competes with the name',
      (tester) async {
    await tester.pumpWidget(_host(onStrike: true));

    // The dot in the corner is the strike indicator; the text was redundant.
    expect(find.text('·STRIKE'), findsNothing);
    expect(find.text(_longName), findsOneWidget);
  });

  testWidgets('lays out a long name without overflowing, on strike or off',
      (tester) async {
    for (final onStrike in [true, false]) {
      await tester.pumpWidget(_host(onStrike: onStrike));
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflowed with onStrike=$onStrike',
      );
    }
  });

  testWidgets('survives a narrow half-width card', (tester) async {
    // Two of these sit side by side; on a small phone each gets ~160px.
    await tester.pumpWidget(_host(onStrike: true, width: 150));
    expect(tester.takeException(), isNull);
  });

  testWidgets('still shows the runs figure, which is what is read most',
      (tester) async {
    await tester.pumpWidget(_host(onStrike: true));
    expect(find.text('17'), findsOneWidget);
    expect(find.text('(4)'), findsOneWidget);
    expect(find.text('1×4 2×6'), findsOneWidget);
  });
}
