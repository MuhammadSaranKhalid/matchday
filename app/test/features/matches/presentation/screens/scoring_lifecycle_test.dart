import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/presentation/state/scoring_state.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';

const _matchId = MatchId('match-1');

Match _match(MatchStatus status) => Match(
  id: _matchId,
  teamAId: const TeamId('team-a'),
  teamBId: const TeamId('team-b'),
  format: const MatchFormat(
    oversPerInnings: 20,
    playersPerTeam: 11,
    ballType: MatchBallType.tape,
    maxOversPerBowler: 4,
  ),
  status: status,
  createdBy: 'scorer',
  createdAt: DateTime(2026),
);

ScoringState _state({
  required MatchStatus status,
  MatchInningsState? innings,
}) => ScoringState(
  match: _match(status),
  inningsNumber: 1,
  innings: innings,
  balls: const [],
  matchPlayers: const [],
  canScore: true,
);

void main() {
  group('scoring lifecycle', () {
    test('innings break stays in the scoring surface', () {
      final state = _state(status: MatchStatus.inningsBreak);

      expect(state.isInningsBreak, isTrue);
      expect(state.isTerminal, isFalse);
    });

    test('only final match states route away from scoring', () {
      for (final status in [
        MatchStatus.completed,
        MatchStatus.cancelled,
        MatchStatus.abandoned,
        MatchStatus.tied,
        MatchStatus.noResult,
        MatchStatus.walkover,
      ]) {
        expect(_state(status: status).isTerminal, isTrue, reason: status.wire);
      }
      expect(_state(status: MatchStatus.live).isTerminal, isFalse);
    });

    test('trio readiness comes from the authoritative innings row', () {
      final incomplete = _state(
        status: MatchStatus.live,
        innings: MatchInningsState(
          matchId: _matchId,
          inningsNumber: 2,
          version: 1,
          updatedAt: DateTime(2026),
          strikerId: const MatchPlayerId('striker'),
          nonStrikerId: const MatchPlayerId('non-striker'),
        ),
      );
      final complete = _state(
        status: MatchStatus.live,
        innings: MatchInningsState(
          matchId: _matchId,
          inningsNumber: 2,
          version: 2,
          updatedAt: DateTime(2026),
          strikerId: const MatchPlayerId('striker'),
          nonStrikerId: const MatchPlayerId('non-striker'),
          bowlerId: const MatchPlayerId('bowler'),
        ),
      );

      expect(incomplete.activeInnings, 2);
      expect(incomplete.needsTrio, isTrue);
      expect(complete.needsTrio, isFalse);
    });
  });
}
