// The free-hit dismissal restriction.
//
// The bug this guards, caught by driving the app on a device: after a
// no-ball the scoring screen shows a banner reading "only a run-out can
// dismiss", and the no-ball sheet says the same — but the wicket sheet went
// on offering bowled / caught / LBW / stumped / hit-wicket. The UI
// contradicted itself, and taking any of those choices would have written an
// impossible dismissal into the scorecard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/sheet_kit.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/wicket_sheet.dart';

const _fielders = [
  SheetPerson(id: 'f1', name: 'Haris'),
  SheetPerson(id: 'f2', name: 'Amir'),
];
const _bench = [SheetPerson(id: 'b1', name: 'Rizwan')];

Widget _host({required bool freeHit}) => MaterialApp(
      home: Scaffold(
        body: WicketSheet(
          overs: '1.1',
          totalRuns: 24,
          totalWickets: 1,
          strikerName: 'Rizwan',
          nonStrikerName: 'Shaheen',
          bowlerName: 'Shadab',
          fielders: _fielders,
          bench: _bench,
          freeHit: freeHit,
        ),
      ),
    );

void main() {
  group('a normal delivery', () {
    testWidgets('offers every dismissal type', (tester) async {
      await tester.pumpWidget(_host(freeHit: false));

      for (final label in [
        'Bowled',
        'Caught',
        'LBW',
        'Run out',
        'Stumped',
        'Hit wkt',
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label should show');
      }
    });
  });

  group('a free hit', () {
    testWidgets('offers exactly what the write path accepts', (tester) async {
      // The allowed set is the server's: run_out, hit_wicket, obstructing,
      // handled_ball. Of those, this sheet offers run-out and hit wicket.
      // Narrower than the server would block a legal dismissal; wider would
      // produce a save the engine rejects.
      await tester.pumpWidget(_host(freeHit: true));

      expect(find.text('Run out'), findsOneWidget);
      expect(find.text('Hit wkt'), findsOneWidget);

      for (final label in ['Bowled', 'Caught', 'LBW', 'Stumped']) {
        expect(
          find.text(label),
          findsNothing,
          reason: '$label is impossible on a free hit',
        );
      }
    });

    testWidgets('says why the choice is narrowed', (tester) async {
      // Showing a single lonely tile with no explanation reads as a bug to
      // the scorer. The header has to account for itself.
      await tester.pumpWidget(_host(freeHit: true));

      expect(find.textContaining('FREE HIT'), findsOneWidget);
      expect(
        find.textContaining('only a run-out or hit wicket can dismiss'),
        findsOneWidget,
      );
    });
  });
}
