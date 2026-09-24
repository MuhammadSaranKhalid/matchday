import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
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
    for (int i = 0; i < matchPlayers.length; i++)
      if (matchPlayers[i].teamSide == battingSide)
        MatchStartLineupCandidate(
          refId: matchPlayers[i].playerRefId,
          name: matchPlayers[i].displayName,
          photoUrl: matchPlayers[i].photoUrl,
          jersey:
              matchPlayers[i].jerseyNumber ??
              byRefId[matchPlayers[i].playerRefId]?.member.jerseyNumber,
          styleTag:
              matchPlayers[i].isKeeper
                  ? 'WK'
                  : (i % 3 == 1 ? 'LHB' : 'RHB'),
          statsSummary:
              matchPlayers[i].isKeeper
                  ? 'Wicketkeeper · Top order'
                  : (i < 2
                      ? 'Opener · Batting specialist'
                      : (i < 5
                          ? 'Top order · Batter'
                          : (i < 8
                              ? 'All-rounder'
                              : 'Bowler'))),
          category:
              matchPlayers[i].isKeeper
                  ? 'bat'
                  : (i < 5
                      ? 'bat'
                      : (i < 8
                          ? 'ar'
                          : 'bowl')),
          isCaptain: matchPlayers[i].isCaptain,
          isKeeper: matchPlayers[i].isKeeper,
        ),
  ];
}

/// The fielding side's XI as a candidate list for the opening bowler slot.
@riverpod
Future<List<MatchStartLineupCandidate>> matchStartBowlingLineup(
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

  final bowlingTeam =
      battingTeam == match.teamAId ? match.teamBId : match.teamAId;
  final bowlingSide =
      bowlingTeam == match.teamAId ? MatchTeamSide.a : MatchTeamSide.b;

  final matchPlayers = await ref.watch(matchPlayersProvider(matchId).future);
  final roster = await ref.watch(rosterProvider(bowlingTeam.value).future);
  final byRefId = <String, RosterMember>{
    for (final r in roster) r.member.playerId: r,
  };

  return [
    for (int i = 0; i < matchPlayers.length; i++)
      if (matchPlayers[i].teamSide == bowlingSide)
        MatchStartLineupCandidate(
          refId: matchPlayers[i].playerRefId,
          name: matchPlayers[i].displayName,
          photoUrl: matchPlayers[i].photoUrl,
          jersey:
              matchPlayers[i].jerseyNumber ??
              byRefId[matchPlayers[i].playerRefId]?.member.jerseyNumber,
          styleTag:
              matchPlayers[i].isKeeper
                  ? 'WK'
                  : (i % 2 == 0 ? 'RF' : 'OB'),
          statsSummary:
              matchPlayers[i].isKeeper
                  ? 'Wicketkeeper · Gloves'
                  : (i % 2 == 0
                      ? 'Right-arm Fast · Opening spell'
                      : 'Off Break · Spin attack'),
          category:
              matchPlayers[i].isKeeper
                  ? 'bat'
                  : (i < 4
                      ? 'bowl'
                      : (i < 7
                          ? 'ar'
                          : 'bat')),
          isCaptain: matchPlayers[i].isCaptain,
          isKeeper: matchPlayers[i].isKeeper,
        ),
  ];
}
