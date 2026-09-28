import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/match_player.dart';
import '../controllers/match_room_controller.dart';
import '../state/match_start_state.dart';
import '../state/match_start_views.dart';

part 'match_start_providers.g.dart';

/// The batting side's XI as a tappable candidate list, derived synchronously
/// from the canonical [MatchRoomSnapshot].
@riverpod
List<MatchStartLineupCandidate> matchStartLineup(
  Ref ref,
  String matchId,
) {
  final room = ref.watch(matchRoomControllerProvider(matchId)).value;
  if (room == null) return const [];

  final match = room.snapshot.match;
  final battingTeam = battingFirstTeam(match);
  if (battingTeam == null) return const [];

  final battingSide =
      battingTeam == match.teamAId ? MatchTeamSide.a : MatchTeamSide.b;

  return [
    for (final p in room.snapshot.participants)
      if (p.teamSide == battingSide)
        MatchStartLineupCandidate(
          refId: p.playerRefId,
          name: p.displayName,
          photoUrl: p.photoUrl,
          jersey: p.jerseyNumber,
          styleTag: p.isKeeper ? 'WK' : '',
          statsSummary: p.isKeeper
              ? 'Wicketkeeper'
              : (p.isCaptain ? 'Captain' : 'Player'),
          category: p.isKeeper ? 'bat' : 'all',
          isCaptain: p.isCaptain,
          isKeeper: p.isKeeper,
        ),
  ];
}

/// The fielding side's XI as a candidate list for the opening bowler slot,
/// derived synchronously from the canonical [MatchRoomSnapshot].
@riverpod
List<MatchStartLineupCandidate> matchStartBowlingLineup(
  Ref ref,
  String matchId,
) {
  final room = ref.watch(matchRoomControllerProvider(matchId)).value;
  if (room == null) return const [];

  final match = room.snapshot.match;
  final battingTeam = battingFirstTeam(match);
  if (battingTeam == null) return const [];

  final bowlingTeam =
      battingTeam == match.teamAId ? match.teamBId : match.teamAId;
  final bowlingSide =
      bowlingTeam == match.teamAId ? MatchTeamSide.a : MatchTeamSide.b;

  return [
    for (final p in room.snapshot.participants)
      if (p.teamSide == bowlingSide)
        MatchStartLineupCandidate(
          refId: p.playerRefId,
          name: p.displayName,
          photoUrl: p.photoUrl,
          jersey: p.jerseyNumber,
          styleTag: p.isKeeper ? 'WK' : '',
          statsSummary: p.isKeeper
              ? 'Wicketkeeper'
              : (p.isCaptain ? 'Captain' : 'Bowler'),
          category: 'bowl',
          isCaptain: p.isCaptain,
          isKeeper: p.isKeeper,
        ),
  ];
}
