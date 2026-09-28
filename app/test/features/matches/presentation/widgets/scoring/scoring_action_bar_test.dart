// Which control surface the bottom band shows.
//
// This was four nested `if`s inside ScoringScreen's widget tree, so "can this
// scorer press anything right now" could only be answered by rendering the
// screen. The precedence between the four cases was the part most at risk:
// getting it wrong shows a spectator a live run pad, or asks for a bowler for
// an over that will never be bowled.
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/matches/presentation/widgets/scoring/scoring_action_bar.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';

const _matchId = MatchId('m1');

Match _match() => Match(
      id: _matchId,
      teamAId: const TeamId('a'),
      teamBId: const TeamId('b'),
      format: const MatchFormat(
        oversPerInnings: 20,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4,
      ),
      status: MatchStatus.live,
      createdBy: 'u1',
      createdAt: DateTime(2026),
    );

MatchInningsState _innings({
  String? bowler = 'mp9',
  int legalBalls = 0,
  int wickets = 0,
}) =>
    MatchInningsState(
      matchId: _matchId,
      inningsNumber: 1,
      version: 1,
      updatedAt: DateTime(2026),
      strikerId: const MatchPlayerId('mp1'),
      nonStrikerId: const MatchPlayerId('mp2'),
      bowlerId: bowler == null ? null : MatchPlayerId(bowler),
      legalBallCount: legalBalls,
      totalWickets: wickets,
    );

ScoringState _state({
  bool canScore = true,
  String? bowler = 'mp9',
  int legalBalls = 0,
  int wickets = 0,
}) =>
    ScoringState(
      match: _match(),
      inningsNumber: 1,
      innings: _innings(
        bowler: bowler,
        legalBalls: legalBalls,
        wickets: wickets,
      ),
      balls: const [],
      matchPlayers: const [],
      canScore: canScore,
    );

void main() {
  group('ScoringSurface.of', () {
    test('a scorer with a bowler set gets the pad', () {
      expect(ScoringSurface.of(_state()), ScoringSurface.scoring);
    });

    test('no bowler mid-innings asks for one', () {
      expect(
        ScoringSurface.of(_state(bowler: null)),
        ScoringSurface.needsBowler,
      );
    });

    test('a completed innings shows the complete notice', () {
      // 20 overs x 6 = 120 legal balls.
      expect(
        ScoringSurface.of(_state(legalBalls: 120)),
        ScoringSurface.inningsComplete,
      );
    });

    test('all out shows the complete notice', () {
      expect(
        ScoringSurface.of(_state(wickets: 10)),
        ScoringSurface.inningsComplete,
      );
    });

    test('a spectator never gets the pad', () {
      expect(
        ScoringSurface.of(_state(canScore: false)),
        ScoringSurface.readOnly,
      );
    });

    test('read-only outranks a finished innings', () {
      expect(
        ScoringSurface.of(_state(canScore: false, legalBalls: 120)),
        ScoringSurface.readOnly,
      );
    });

    test('read-only outranks a missing bowler', () {
      // A spectator is never asked to pick a bowler, even though the innings
      // genuinely has none set.
      expect(
        ScoringSurface.of(_state(canScore: false, bowler: null)),
        ScoringSurface.readOnly,
      );
    });

    test('a finished innings outranks a missing bowler', () {
      // The server clears the bowler at the end of every over, including the
      // last one — so the final ball of an innings leaves BOTH conditions
      // true. Nobody is owed a bowler for an over that will not be bowled.
      expect(
        ScoringSurface.of(_state(bowler: null, legalBalls: 120)),
        ScoringSurface.inningsComplete,
      );
    });
  });
}
