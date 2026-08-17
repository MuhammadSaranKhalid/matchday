import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match_player.dart';
import '../state/match_start_state.dart';
import 'matches_providers.dart';

part 'match_start_lineup_provider.g.dart';

class MatchStartLineupState {
  const MatchStartLineupState({
    required this.players,
    this.lockedStriker,
    this.lockedNonStriker,
  });

  final List<RosterMember> players;
  final String? lockedStriker;
  final String? lockedNonStriker;
}

@riverpod
Future<MatchStartLineupState> matchStartLineup(
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

  final allMatchPlayers = await ref.watch(matchPlayersProvider(matchId).future);
  final battingSide = battingTeam == match.teamAId ? MatchTeamSide.a : MatchTeamSide.b;
  final battingMatchPlayers =
      allMatchPlayers.where((p) => p.teamSide == battingSide).toList();
  final xi = battingMatchPlayers.map((p) => p.playerRefId).toList(growable: false);

  final rosterMembers = await ref.watch(rosterProvider(battingTeam.value).future);
  final byId = <String, RosterMember>{};
  for (final r in rosterMembers) {
    byId[r.member.playerId] = r;
  }
  final players = xi.map((id) => byId[id]).whereType<RosterMember>().toList();

  final inningsState = await ref.watch(liveInningsStateProvider(matchId, 1).future);

  String? refIdOf(String? matchPlayerId) {
    if (matchPlayerId == null) return null;
    for (final mp in allMatchPlayers) {
      if (mp.id.value == matchPlayerId) return mp.playerRefId;
    }
    return null;
  }

  return MatchStartLineupState(
    players: players,
    lockedStriker: refIdOf(inningsState?.strikerId?.value),
    lockedNonStriker: refIdOf(inningsState?.nonStrikerId?.value),
  );
}
