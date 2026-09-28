// The bottom band of the scoring screen: every key the scorer can press, plus
// the notices that stand in for the pad when pressing anything is not allowed.
//
// Purely presentational. It decides WHICH surface to show from the state it is
// handed, and reports intent through callbacks — it never reads a controller
// and never awaits anything. Its counterpart is scoring_actions.dart, which
// turns these callbacks into writes.
import 'package:flutter/material.dart';

import '../../../domain/entities/ball.dart';
import '../../state/scoring_state.dart';
import 'pad/scoring_pad.dart';
import 'scoring_notices.dart';

/// Which control surface the bottom band is currently showing.
///
/// The screen used to express this as four nested `if`s inside its widget
/// tree, which meant the rule for "can this scorer press anything right now"
/// was only observable by rendering the screen.
enum ScoringSurface {
  /// Not this device's innings to score — a spectator, or the other side's
  /// scorer.
  readOnly,

  /// The innings has ended; the screen is about to route away.
  inningsComplete,

  /// A bowler is owed before the next delivery (innings start, or the top of
  /// a new over).
  needsBowler,

  /// A wicket left an end empty and a replacement batter is owed.
  needsBatter,

  /// The pad is live.
  scoring;

  /// Picks the surface for [s].
  ///
  /// Order matters: read-only outranks everything (a spectator is never shown
  /// a pad), and a finished innings outranks a missing bowler (nobody is owed
  /// a bowler for an over that will not be bowled).
  static ScoringSurface of(ScoringState s) {
    if (!s.canScore) return ScoringSurface.readOnly;
    if (s.inningsOver) return ScoringSurface.inningsComplete;
    if (!s.bowlerSet) return ScoringSurface.needsBowler;
    // A wicket clears an end. Until it is refilled the pad must not accept a
    // delivery — one was recorded against an empty end in a real match.
    // Ordered after needsBowler so it agrees with the post-delivery prompt,
    // which offers the bowler first.
    if (s.needsBatter) return ScoringSurface.needsBatter;
    return ScoringSurface.scoring;
  }
}

class ScoringActionBar extends StatelessWidget {
  const ScoringActionBar({
    super.key,
    required this.state,
    required this.battingTeamName,
    required this.onRun,
    required this.onWicket,
    required this.onExtra,
    required this.onSelectBowler,
    required this.onSelectBatter,
  });

  final ScoringState state;

  /// Shown in the read-only notice so a spectator knows whose innings this is.
  final String? battingTeamName;

  final ValueChanged<int> onRun;
  final VoidCallback onWicket;
  final ValueChanged<BallKind> onExtra;
  final VoidCallback onSelectBowler;
  final VoidCallback onSelectBatter;

  @override
  Widget build(BuildContext context) {
    // Padded for the gesture bar: the screen's SafeArea deliberately does not
    // cover the bottom, because the band has to sit flush against it.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: switch (ScoringSurface.of(state)) {
          ScoringSurface.readOnly => [
            ReadOnlyScoringNotice(battingTeamName: battingTeamName),
          ],
          ScoringSurface.inningsComplete => [const InningsCompleteNotice()],
          ScoringSurface.needsBowler => [
            SelectBowlerNotice(
              isOpening: state.balls.isEmpty,
              onSelect: onSelectBowler,
            ),
          ],
          ScoringSurface.needsBatter => [
            SelectBatterNotice(
              onSelect: onSelectBatter,
              anyAvailable: state.hasBatterAvailable,
            ),
          ],
          ScoringSurface.scoring => [
            ScoringPad(
              busy: false,
              onRun: onRun,
              onWicket: onWicket,
              onExtra: onExtra,
            ),
          ],
        },
      ),
    );
  }
}
