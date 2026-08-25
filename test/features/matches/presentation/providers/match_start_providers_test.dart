import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchday/features/matches/domain/entities/match.dart';
import 'package:matchday/features/matches/domain/entities/match_innings_state.dart';
import 'package:matchday/features/matches/domain/entities/match_player.dart';
import 'package:matchday/features/matches/presentation/providers/match_start_providers.dart';
import 'package:matchday/features/matches/presentation/providers/matches_providers.dart';
import 'package:matchday/features/teams/domain/entities/roster_member.dart';
import 'package:matchday/features/teams/domain/entities/team.dart';
import 'package:matchday/features/teams/domain/entities/team_member.dart';
import 'package:matchday/features/teams/presentation/providers/teams_providers.dart';

const _matchId = 'm1';
const _teamA = TeamId('a');
const _teamB = TeamId('b');

/// Team A won the toss and chose to bat, so team A bats first.
Match _match() => Match(
      id: const MatchId(_matchId),
      teamAId: _teamA,
      teamBId: _teamB,
      format: const MatchFormat(
        oversPerInnings: 20,
        playersPerTeam: 11,
        ballType: MatchBallType.tape,
        maxOversPerBowler: 4,
      ),
      status: MatchStatus.toss,
      createdBy: 'capA',
      createdAt: DateTime(2026),
      teamACaptain: 'capA',
      teamBCaptain: 'capB',
      tossWonBy: _teamA,
      tossDecision: TossDecision.bat,
      startPhase: MatchStartPhase.lineup,
    );

Team _team(TeamId id, String name) => Team(
      id: id,
      ownerId: 'capA',
      name: name,
      type: TeamType.club,
      privacy: TeamPrivacy.public,
      managers: const [],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

MatchPlayer _player(
  String mpId,
  String refId, {
  int? jersey,
  String? name,
  String? photoUrl,
}) =>
    MatchPlayer(
      id: MatchPlayerId(mpId),
      matchId: const MatchId(_matchId),
      teamSide: MatchTeamSide.a,
      profileId: refId,
      displayName: name ?? 'Player $refId',
      photoUrl: photoUrl,
      jerseyNumber: jersey,
    );

RosterMember _roster(String refId, String name, {int? jersey}) => RosterMember(
      member: TeamMember(
        id: MembershipId('mem-$refId'),
        teamId: _teamA,
        playerId: refId,
        playerType: PlayerType.claimed,
        role: MemberRole.player,
        addedBy: 'capA',
        joinedAt: DateTime(2026),
        updatedAt: DateTime(2026),
        jerseyNumber: jersey,
      ),
      displayName: name,
    );

void main() {
  ProviderContainer makeContainer({
    required List<MatchPlayer> lineup,
    required List<RosterMember> roster,
    MatchInningsState? innings,
  }) {
    final container = ProviderContainer.test(
      overrides: [
        liveMatchProvider(_matchId).overrideWith((ref) => Stream.value(_match())),
        matchPlayersProvider(_matchId).overrideWith((ref) async => lineup),
        rosterProvider(_teamA.value).overrideWith((ref) => Stream.value(roster)),
        rosterProvider(_teamB.value)
            .overrideWith((ref) => Stream.value(const [])),
        teamProvider(_teamA.value)
            .overrideWith((ref) => Stream.value(_team(_teamA, 'Kings XI'))),
        teamProvider(_teamB.value)
            .overrideWith((ref) => Stream.value(_team(_teamB, 'Eagles'))),
        liveInningsStateProvider(_matchId, 1)
            .overrideWith((ref) => Stream.value(innings)),
      ],
    );
    addTearDown(container.dispose);
    // Hold the provider open. Without a listener the autodispose chain tears
    // down between `read` calls and the underlying streams never resolve.
    container.listen(matchStartLineupProvider(_matchId), (_, __) {});
    return container;
  }

  group('matchStartLineup', () {
    test('lists the batting side in match_players order', () async {
      final container = makeContainer(
        lineup: [
          _player('mp1', 'p1', name: 'Imran'),
          _player('mp2', 'p2', name: 'Wasim'),
        ],
        roster: [_roster('p1', 'Imran'), _roster('p2', 'Wasim')],
      );

      final candidates =
          await container.read(matchStartLineupProvider(_matchId).future);

      expect(candidates.map((c) => c.name), ['Imran', 'Wasim']);
      expect(candidates.map((c) => c.refId), ['p1', 'p2']);
    });

    test('keeps a guest who is in the XI but not on the roster', () async {
      // The regression this guards: an inner join dropped guests entirely,
      // so a player physically opening the batting could not be selected.
      final container = makeContainer(
        lineup: [
          _player('mp1', 'p1'),
          _player('mp2', 'guest-9'),
        ],
        roster: [_roster('p1', 'Imran')],
      );

      final candidates =
          await container.read(matchStartLineupProvider(_matchId).future);

      expect(candidates, hasLength(2));
      expect(candidates.last.refId, 'guest-9');
      expect(candidates.last.name, isNotEmpty);
    });

    test('prefers the per-match jersey over the roster number', () async {
      final container = makeContainer(
        lineup: [_player('mp1', 'p1', jersey: 7)],
        roster: [_roster('p1', 'Imran', jersey: 44)],
      );

      final candidates =
          await container.read(matchStartLineupProvider(_matchId).future);

      expect(candidates.single.jersey, 7);
    });

    test('falls back to the roster jersey when the match has none', () async {
      final container = makeContainer(
        lineup: [_player('mp1', 'p1')],
        roster: [_roster('p1', 'Imran', jersey: 44)],
      );

      final candidates =
          await container.read(matchStartLineupProvider(_matchId).future);

      expect(candidates.single.jersey, 44);
    });

    test('excludes the bowling side', () async {
      final container = makeContainer(
        lineup: [
          _player('mp1', 'p1'),
          const MatchPlayer(
            id: MatchPlayerId('mp9'),
            matchId: MatchId(_matchId),
            teamSide: MatchTeamSide.b,
            profileId: 'opp-1',
            displayName: 'Opponent',
          ),
        ],
        roster: [_roster('p1', 'Imran')],
      );

      final candidates =
          await container.read(matchStartLineupProvider(_matchId).future);

      expect(candidates.single.refId, 'p1');
    });
  });
}
