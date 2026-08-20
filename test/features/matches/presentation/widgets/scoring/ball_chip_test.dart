// How a delivery is labelled in the ball log and the last-ball card.
//
// Both defects here were spotted by reading the log on a device:
//   * a no-ball bowled *after* the 1.1 wicket was printed "1.0", because the
//     engine stores ball_in_over = 0 for every illegal delivery as a "did not
//     count" sentinel. Printed raw it read as though the no-ball came first,
//     and two wides in one over were indistinguishable.
//   * every dismissal read "WICKET · caught" — it named neither the batter
//     who was out nor the fielder, so the log could not be audited.
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/ball.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/ball_chip.dart';

Ball _ball({
  BallKind kind = BallKind.legal,
  int runs = 0,
  int extras = 0,
  bool wicket = false,
  WicketType? wicketType,
  int over = 1,
  int ballInOver = 1,
}) =>
    Ball(
      id: const BallId('b1'),
      matchId: const MatchId('m1'),
      inningsNumber: 1,
      seq: 1,
      overNumber: over,
      ballInOver: ballInOver,
      isLegalDelivery: kind != BallKind.wide && kind != BallKind.noBall,
      ballKind: kind,
      runsScored: runs,
      extras: extras,
      isWicket: wicket,
      isFreeHit: false,
      wicketType: wicketType,
    );

void main() {
  group('ballNumberLabel', () {
    test('prints the ball number for a legal delivery', () {
      expect(ballNumberLabel(_ball(over: 1, ballInOver: 4)), '1.4');
    });

    test('does not invent a ball number for a wide', () {
      // The engine's sentinel is 0; printing "1.0" implied the wide came
      // before 1.1 when it was actually bowled after it.
      final label = ballNumberLabel(
        _ball(kind: BallKind.wide, over: 1, ballInOver: 0, extras: 1),
      );
      expect(label, isNot('1.0'));
      expect(label, startsWith('1.'));
    });

    test('does not invent a ball number for a no-ball', () {
      final label = ballNumberLabel(
        _ball(kind: BallKind.noBall, over: 1, ballInOver: 0, runs: 4),
      );
      expect(label, isNot('1.0'));
    });
  });

  group('wicketLabel', () {
    test('never leaks the database spelling', () {
      // WicketType.wire is 'run_out' / 'hit_wicket' and used to reach the UI
      // verbatim, underscores and all.
      for (final t in WicketType.values) {
        expect(wicketLabel(t), isNot(contains('_')));
      }
    });

    test('reads as cricket, not as an enum', () {
      expect(wicketLabel(WicketType.runOut), 'run out');
      expect(wicketLabel(WicketType.hitWicket), 'hit wicket');
      expect(wicketLabel(WicketType.lbw), 'LBW');
    });
  });

  group('describeBall — wickets', () {
    test('names the batter who was out', () {
      final desc = describeBall(
        _ball(wicket: true, wicketType: WicketType.bowled),
        batterName: 'Shaheen',
      );
      expect(desc, contains('Shaheen'));
    });

    test('credits the fielder on a catch', () {
      final desc = describeBall(
        _ball(wicket: true, wicketType: WicketType.caught),
        batterName: 'Shaheen',
        fielderName: 'Haris',
      );
      expect(desc, 'Shaheen · c Haris');
    });

    test('uses stumping notation for a stumping', () {
      final desc = describeBall(
        _ball(wicket: true, wicketType: WicketType.stumped),
        batterName: 'Shaheen',
        fielderName: 'Rizwan',
      );
      expect(desc, 'Shaheen · st Rizwan');
    });

    test('falls back cleanly when no name can be resolved', () {
      final desc = describeBall(_ball(wicket: true, wicketType: WicketType.lbw));
      expect(desc, 'WICKET · LBW');
    });
  });

  group('describeBall — non-wickets are unchanged', () {
    test('dot, boundary and extras still read the same', () {
      expect(describeBall(_ball()), 'Dot ball');
      expect(describeBall(_ball(runs: 4)), 'Four!');
      expect(describeBall(_ball(runs: 6)), 'SIX!');
      expect(
        describeBall(_ball(kind: BallKind.noBall, runs: 4)),
        'No-ball · 4 off bat',
      );
    });
  });
}
