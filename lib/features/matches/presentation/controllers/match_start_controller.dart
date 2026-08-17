import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../providers/matches_providers.dart';
import '../state/match_start_state.dart';

part 'match_start_controller.g.dart';

/// Watches the match row in real time and exposes the Match Start
/// state and actions.
@riverpod
class MatchStartController extends _$MatchStartController {
  @override
  Future<MatchStartState> build(String matchId) async {
    final user = ref.watch(currentUserStreamProvider).value;
    final userId = user?.id.value;

    final liveAsync = ref.watch(liveMatchProvider(matchId));
    final match = liveAsync.value;
    if (match == null) {
      throw const FailureWrapper(NotFoundFailure('Match not found'));
    }

    final previous = state.value;

    return _deriveState(
      match,
      userId,
      previous: previous,
    );
  }

  MatchStartState _deriveState(
    Match m,
    String? userId, {
    MatchStartState? previous,
  }) {
    final batting = battingFirstTeam(m);
    final bowling = batting == null
        ? null
        : (batting == m.teamAId ? m.teamBId : m.teamAId);

    return MatchStartState(
      match: m,
      viewerRole: viewerRoleOnMatch(m, userId),
      battingTeamId: batting,
      bowlingTeamId: bowling,
      pendingTossWinner: previous?.pendingTossWinner,
      pendingDecision: previous?.pendingDecision,
      pendingStriker: previous?.pendingStriker,
      pendingNonStriker: previous?.pendingNonStriker,
      isBusy: previous?.isBusy ?? false,
    );
  }

  void pickTossWinner(TeamId winner) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      pendingTossWinner: () => winner,
    ));
  }

  void pickTossDecision(TossDecision decision) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      pendingDecision: () => decision,
    ));
  }

  void pickStriker(String refId) {
    final current = state.value;
    if (current == null) return;
    // Tapping the existing non-striker into striker swaps them.
    String? newNonStriker = current.pendingNonStriker;
    if (current.pendingNonStriker == refId) {
      newNonStriker = current.pendingStriker;
    }
    state = AsyncData(current.copyWith(
      pendingStriker: () => refId,
      pendingNonStriker: () => newNonStriker,
    ));
  }

  void pickNonStriker(String refId) {
    final current = state.value;
    if (current == null) return;
    // Tapping the existing striker into non-striker swaps them.
    String? newStriker = current.pendingStriker;
    if (current.pendingStriker == refId) {
      newStriker = current.pendingNonStriker;
    }
    state = AsyncData(current.copyWith(
      pendingStriker: () => newStriker,
      pendingNonStriker: () => refId,
    ));
  }

  Future<Either<Failure, Unit>> submitToss() async {
    final current = state.value;
    if (current == null || !current.isTossReady) {
      return const Left(ValidationFailure('Please select toss winner and decision'));
    }

    state = AsyncData(current.copyWith(isBusy: true));

    final result = await ref.read(matchesRepositoryProvider).recordMatchToss(
          id: MatchId(matchId),
          wonBy: current.pendingTossWinner!,
          decision: current.pendingDecision!,
        );

    final updated = state.value ?? current;
    state = AsyncData(updated.copyWith(
      isBusy: false,
      pendingTossWinner: () => null,
      pendingDecision: () => null,
    ));

    return result;
  }

  Future<Either<Failure, Unit>> submitOpeners() async {
    final current = state.value;
    if (current == null || !current.isLineupReady) {
      return const Left(ValidationFailure('Please select both openers'));
    }

    final allMatchPlayers =
        ref.read(matchPlayersProvider(matchId)).value ?? const [];

    String? matchPlayerIdFor(String refId) {
      for (final mp in allMatchPlayers) {
        if (mp.playerRefId == refId) return mp.id.value;
      }
      return null;
    }

    final strikerMpId = matchPlayerIdFor(current.pendingStriker!);
    final nonStrikerMpId = matchPlayerIdFor(current.pendingNonStriker!);

    if (strikerMpId == null || nonStrikerMpId == null) {
      return const Left(ValidationFailure(
        'Selected player is not in this match\'s lineup. Reopen the screen and try again.',
      ));
    }

    state = AsyncData(current.copyWith(isBusy: true));

    final result = await ref.read(matchesRepositoryProvider).submitMatchOpeners(
          id: MatchId(matchId),
          strikerId: strikerMpId,
          nonStrikerId: nonStrikerMpId,
        );

    final updated = state.value ?? current;
    state = AsyncData(updated.copyWith(
      isBusy: false,
      pendingStriker: () => null,
      pendingNonStriker: () => null,
    ));

    return result;
  }

  Future<Either<Failure, Unit>> startMatchNow() async {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(isBusy: true));
    }

    final result = await ref
        .read(matchesRepositoryProvider)
        .startMatchNow(MatchId(matchId));

    final updated = state.value ?? current;
    if (updated != null) {
      state = AsyncData(updated.copyWith(isBusy: false));
    }

    return result;
  }
}
