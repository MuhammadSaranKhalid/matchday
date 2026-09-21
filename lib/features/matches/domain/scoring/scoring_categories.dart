// Which parts of the scoring rules a delivery actually exercised.
//
// This exists to make the S3 soak measurable rather than estimated. The exit
// criterion for trusting the Dart engine is not "we scored a lot of matches" —
// 2,000 dot balls prove almost nothing — it is "every category in the golden
// vectors was observed in production, with no parity alarm".
//
// The names returned here are the SAME strings used as `category` in
// `vectors.json`, deliberately: coverage is measured by subtracting the set
// observed in the field from the set present in the spec. If the two
// vocabularies drift apart that subtraction quietly becomes meaningless, so
// [vectorCategories] below is asserted against the file in tests.
library;

import '../entities/ball.dart';
import 'scoring_types.dart';

/// Every category the vector suite defines. Kept here so the coverage report
/// can name what has NOT been seen yet, not just what has.
const vectorCategories = <String>{
  'legal',
  'wide',
  'no_ball',
  'bye',
  'leg_bye',
  'wicket',
  'validation',
  'over_end',
  'termination',
  'bowler_cap',
  'free_hit',
  'hundred',
};

/// Rejection codes that represent input validation rather than a rule about a
/// specific delivery kind.
const _validationCodes = <String>{
  'wicket_type_required',
  'wicket_type_unexpected',
  'negative_runs',
  'wide_runs_to_batter',
  'wide_missing_penalty',
};

/// The categories one delivery exercised.
///
/// A delivery routinely hits several: a wicket that completes an over and ends
/// the innings is `wicket` + `over_end` + `termination` + its ball kind. All of
/// them count toward coverage, because all of them were genuinely executed.
Set<String> scoringCategories({
  required EngineBallInput input,
  required EngineFormat format,
  required BallResult result,
}) {
  final out = <String>{};

  out.add(switch (input.ballKind) {
    BallKind.legal => 'legal',
    BallKind.wide => 'wide',
    BallKind.noBall => 'no_ball',
    BallKind.bye => 'bye',
    BallKind.legBye => 'leg_bye',
  });

  if (input.isWicket) out.add('wicket');

  // A format whose ends change on a different cadence to its sets is The
  // Hundred's shape, whatever it is called. That distinction is the only
  // reason the category exists, so detect it structurally rather than by name.
  final ballsPerOver = format.ballsPerOver > 0 ? format.ballsPerOver : 6;
  final endChange =
      (format.endChangeBalls != null && format.endChangeBalls! > 0)
          ? format.endChangeBalls!
          : ballsPerOver;
  if (endChange != ballsPerOver) out.add('hundred');

  if (!result.ok) {
    final code = result.error?.code;
    if (code == 'bowler_over_cap') out.add('bowler_cap');
    if (code == 'free_hit_dismissal') out.add('free_hit');
    if (code != null && _validationCodes.contains(code)) out.add('validation');
    return out;
  }

  if (result.ball?.isFreeHit == true) out.add('free_hit');
  if (result.events?.overEnded == true) out.add('over_end');
  if (result.events?.inningsEnded == true) out.add('termination');

  return out;
}
