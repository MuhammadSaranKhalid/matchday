import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_player.dart';
import '../state/match_start_state.dart';
import '../state/match_start_views.dart';
import 'matches_providers.dart';

part 'match_start_providers.g.dart';

/// The batting side's XI as a tappable candidate list, in batting order as
/// materialised in `match_players`.
///
/// Every player in the XI is included, whether or not they appear on the
/// team's permanent roster. Guests and one-off ringers are materialised into
/// `match_players` without a `team_members` row, and an inner join here would
/// make them silently unpickable — a player who is physically opening the
/// batting but cannot be selected in the app.
@riverpod
Future<List<MatchStartLineupCandidate>> matchStartLineup(
  Ref ref,
  String matchId,
) async {
  final match = await ref.watch(liveMatchProvider(matchId).future);
  if (match == null) {
    throw const FailureWrapper(NotFoundFailure('Match not found'));
  }

  final battingTeam = battingFirstTeam(match);
  if (battingTeam == null) {
    throw const FailureWrapper(NotFoundFailure('Toss not yet recorded'));
  }

  final matchPlayers = await ref.watch(matchPlayersProvider(matchId).future);
  final battingSide =
      battingTeam == match.teamAId ? MatchTeamSide.a : MatchTeamSide.b;

  final roster = await ref.watch(rosterProvider(battingTeam.value).future);
  final byRefId = <String, RosterMember>{
    for (final r in roster) r.member.playerId: r,
  };

  return [
    for (final p in matchPlayers)
      if (p.teamSide == battingSide)
        MatchStartLineupCandidate(
          refId: p.playerRefId,
          // Name and avatar come off the lineup row, which resolves them at
          // the data boundary. Reading them from the roster used to render
          // guests and substitutes as "Player 3f2a" — they are in the XI but
          // have no roster entry to be named by.
          name: p.displayName,
          photoUrl: p.photoUrl,
          // Per-match jersey wins — a guest wears whatever was free — and
          // falls back to their permanent roster number. This is the only
          // thing the roster is still consulted for.
          jersey: p.jerseyNumber ?? byRefId[p.playerRefId]?.member.jerseyNumber,
        ),
  ];
}

/// The Ready stage's screen-ready summary: team names, the toss line, the
/// locked openers resolved to names, and the format line.
@riverpod
Future<MatchStartReadyView> matchStartReady(Ref ref, String matchId) async {
  final match = await ref.watch(liveMatchProvider(matchId).future);
  if (match == null) {
    throw const FailureWrapper(NotFoundFailure('Match not found'));
  }

  final teamA = await ref.watch(teamProvider(match.teamAId.value).future);
  final teamB = await ref.watch(teamProvider(match.teamBId.value).future);
  String? teamNameOf(TeamId? id) {
    if (id == null) return null;
    if (id == match.teamAId) return teamA?.name;
    if (id == match.teamBId) return teamB?.name;
    return null;
  }

  final batting = battingFirstTeam(match);
  final bowling = batting == null
      ? null
      : (batting == match.teamAId ? match.teamBId : match.teamAId);

  // Openers are persisted on match_innings_state for innings 1 as
  // match_player_ids; resolve them back through the lineup, which already
  // carries each player's name — including guests, who have no roster row.
  final matchPlayers = await ref.watch(matchPlayersProvider(matchId).future);
  final innings = await ref.watch(liveInningsStateProvider(matchId, 1).future);

  String? openerName(String? matchPlayerId) =>
      matchPlayers.byMatchPlayerId(matchPlayerId)?.displayName;

  return MatchStartReadyView(
    battingTeamName: teamNameOf(batting) ?? 'Batting',
    bowlingTeamName: teamNameOf(bowling) ?? 'Bowling',
    tossLine: _tossLine(match, teamNameOf(match.tossWonBy)),
    formatLine: _formatLine(match.format),
    strikerName: openerName(innings?.strikerId?.value),
    nonStrikerName: openerName(innings?.nonStrikerId?.value),
  );
}

String _tossLine(Match m, String? winnerName) {
  final decision = m.tossDecision;
  if (decision == null || m.tossWonBy == null) return '';
  final winner = winnerName ??
      (m.tossWonBy == m.teamAId ? 'Team A' : 'Team B');
  return '$winner · chose to ${decision == TossDecision.bat ? 'bat' : 'bowl'}';
}

String _formatLine(MatchFormat f) =>
    'T${f.oversPerInnings} · ${f.playersPerTeam}-a-side · ${f.ballType.name} ball';
