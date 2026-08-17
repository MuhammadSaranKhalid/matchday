import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../providers/matches_providers.dart';
import '../state/match_start_state.dart';

part 'match_start_controller.g.dart';

/// Watches the match row in real time and exposes the three Match Start
/// action methods. The `build()` stream-aware shape means widgets get an
/// [AsyncValue] that updates without manual refresh as the other captain
/// progresses through stages.
@riverpod
class MatchStartController extends _$MatchStartController {
  @override
  Future<MatchStartState> build(String matchId) async {
    final user = ref.watch(currentUserStreamProvider).value;
    final userId = user?.id.value;

    // Listen to the broadcast channel for this match. liveMatch is an
    // autodispose Stream provider — keep our subscription alive for as long
    // as build() lives.
    final liveAsync = ref.watch(liveMatchProvider(matchId));
    final match = liveAsync.value;
    if (match == null) {
      throw const FailureWrapper(NotFoundFailure('Match not found'));
    }
    return _deriveState(match, userId);
  }

  MatchStartState _deriveState(Match m, String? userId) {
    final batting = battingFirstTeam(m);
    final bowling = batting == null
        ? null
        : (batting == m.teamAId ? m.teamBId : m.teamAId);
    return MatchStartState(
      match: m,
      viewerRole: viewerRoleOnMatch(m, userId),
      battingTeamId: batting,
      bowlingTeamId: bowling,
    );
  }

  Future<Either<Failure, Unit>> recordToss({
    required TeamId wonBy,
    required TossDecision decision,
    String? face,
  }) =>
      ref.read(recordMatchTossUseCaseProvider)(
        id: MatchId(matchId),
        wonBy: wonBy,
        decision: decision,
        face: face,
      );

  Future<Either<Failure, Unit>> submitOpeners({
    required String strikerId,
    required String nonStrikerId,
  }) =>
      ref.read(submitMatchOpenersUseCaseProvider)(
        id: MatchId(matchId),
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
      );

  Future<Either<Failure, Unit>> startMatchNow() =>
      ref.read(startMatchNowUseCaseProvider)(MatchId(matchId));

  Future<Either<Failure, Unit>> startMatch() => startMatchNow();
}
