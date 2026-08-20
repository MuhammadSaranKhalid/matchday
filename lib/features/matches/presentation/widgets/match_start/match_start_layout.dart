import 'package:flutter/material.dart';

import '../../../domain/entities/match.dart';
import '../../state/match_start_state.dart';
import 'match_start_cta_bar.dart';
import 'match_start_header.dart';
import 'match_start_phone_pill.dart';
import 'stage_lineup.dart';
import 'stage_ready.dart';
import 'stage_toss.dart';

/// Chrome + phase routing for the Match Start flow.
///
/// Deliberately inert: it maps a phase to a stage and stacks the header, the
/// phone pill, and the CTA bar around it. Data loading lives in the stages,
/// actions live in the CTA bar, and the `live` redirect lives in the screen.
class MatchStartLayout extends StatelessWidget {
  const MatchStartLayout({
    super.key,
    required this.matchId,
    required this.state,
  });

  final String matchId;
  final MatchStartState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MatchStartHeader(state: state),
        MatchStartPhonePill(state: state),
        Expanded(child: _stage()),
        MatchStartCtaBar(matchId: matchId, state: state),
      ],
    );
  }

  Widget _stage() => switch (state.phase) {
        MatchStartPhase.toss =>
          MatchStartTossStage(matchId: matchId, state: state),
        MatchStartPhase.lineup =>
          MatchStartLineupStage(matchId: matchId, state: state),
        MatchStartPhase.ready =>
          MatchStartReadyStage(matchId: matchId, state: state),
        MatchStartPhase.live => const SizedBox.shrink(),
      };
}
