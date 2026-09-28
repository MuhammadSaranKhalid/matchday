// Did the client engine and the server engine agree about this delivery?
//
// The scoring screen computes each delivery locally so the scoreboard can move
// without waiting for the network, then the server recomputes it and answers
// with the authoritative result. Comparing the two turns every delivery in
// every real match into a parity test — a production oracle no test suite can
// match, and the evidence the S3 soak is gathering.
//
// The server always wins a disagreement. This file only decides whether there
// IS one, and says precisely where, so a divergence is diagnosable from a log
// line rather than reproducible-only.
library;

import '../entities/ball.dart';
import '../entities/match_innings_state.dart';
import 'scoring_types.dart';

/// One field the two engines disagreed about.
class ParityDiff {
  const ParityDiff(this.field, this.predicted, this.actual);

  final String field;
  final Object? predicted;
  final Object? actual;

  @override
  String toString() => '$field: predicted=$predicted actual=$actual';
}

/// The outcome of comparing a local prediction with the server's answer.
class ParityReport {
  const ParityReport(this.diffs);

  final List<ParityDiff> diffs;

  bool get agrees => diffs.isEmpty;

  /// Compact enough for one log line, specific enough to debug from.
  String get summary => diffs.map((d) => d.toString()).join(' · ');
}

/// Compare what the local engine predicted against what the server wrote.
///
/// Only fields BOTH engines compute are compared. Ids assigned by the database
/// (`ball_id`, `seq`), timestamps, and anything else the client could not know
/// are deliberately excluded — flagging those would produce a permanent false
/// alarm and train everyone to ignore the channel.
///
/// [actualInnings] may be null against a deployment of `record-ball` that
/// predates returning the innings row; the innings half is then skipped rather
/// than reported as a mismatch.
ParityReport compareParity({
  required ComputedBall predictedBall,
  required NewInningsState predictedState,
  required Ball actualBall,
  MatchInningsState? actualInnings,
}) {
  final diffs = <ParityDiff>[];

  void check(String field, Object? predicted, Object? actual) {
    if (predicted != actual) diffs.add(ParityDiff(field, predicted, actual));
  }

  // ── The delivery as recorded ──
  check('ball.overNumber', predictedBall.overNumber, actualBall.overNumber);
  check('ball.ballInOver', predictedBall.ballInOver, actualBall.ballInOver);
  check('ball.isFreeHit', predictedBall.isFreeHit, actualBall.isFreeHit);
  check(
    'ball.isLegalDelivery',
    predictedBall.isLegalDelivery,
    actualBall.isLegalDelivery,
  );
  check('ball.ballKind', predictedBall.ballKind, actualBall.ballKind);
  check('ball.runsScored', predictedBall.runsScored, actualBall.runsScored);
  check('ball.extras', predictedBall.extras, actualBall.extras);
  check('ball.isWicket', predictedBall.isWicket, actualBall.isWicket);
  check('ball.wicketType', predictedBall.wicketType, actualBall.wicketType);

  // ── The innings it produced ──
  //
  // This half matters most: `ball.runsScored` being right while the strike
  // rotated the wrong way is exactly the shape of the wide-attribution bug —
  // a right-looking scoreboard over a wrong scorecard.
  if (actualInnings != null) {
    check(
      'state.legalBallCount',
      predictedState.legalBallCount,
      actualInnings.legalBallCount,
    );
    check('state.totalRuns', predictedState.totalRuns, actualInnings.totalRuns);
    check(
      'state.totalWickets',
      predictedState.totalWickets,
      actualInnings.totalWickets,
    );
    check(
      'state.totalExtras',
      predictedState.totalExtras,
      actualInnings.totalExtras,
    );
    check(
      'state.strikerId',
      predictedState.strikerId,
      actualInnings.strikerId?.value,
    );
    check(
      'state.nonStrikerId',
      predictedState.nonStrikerId,
      actualInnings.nonStrikerId?.value,
    );
    check(
      'state.bowlerId',
      predictedState.bowlerId,
      actualInnings.bowlerId?.value,
    );
  }

  return ParityReport(diffs);
}
