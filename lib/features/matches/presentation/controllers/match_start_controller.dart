import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/repositories/matches_repository.dart';
import '../providers/matches_providers.dart';
import '../state/match_start_state.dart';

part 'match_start_controller.g.dart';

const _cricketSetupPermission = 'cricket.match.setup';

/// Match Start controller.
///
/// Roles are display-only. Every active control is derived from the same
/// capability system the Edge Function enforces:
///
///   toss:
///     Cricket setup team cricket.match.setup
///     OR match-scoped cricket.match.setup
///
///   lineup/start:
///     batting team cricket.match.setup
///     OR match-scoped cricket.match.setup
@riverpod
class MatchStartController extends _$MatchStartController {
  @override
  Future<MatchStartState> build(String matchId) async {
    final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    final match = ref.watch(liveMatchProvider(matchId)).value;

    if (match == null) {
      throw const FailureWrapper(NotFoundFailure('Match not found'));
    }

    final lineup =
        ref.watch(matchPlayersProvider(matchId)).value ?? const <MatchPlayer>[];

    final innings = ref.watch(liveInningsStateProvider(matchId, 1)).value;

    final previous = state.value;

    final batting = battingFirstTeam(match);

    final matchScopedSetup = await _canMatchSetup(match.id);

    final canRecordToss =
        matchScopedSetup || await _canTeamSetup(match.setupTeamId);

    final canManageBattingSetup =
        matchScopedSetup || await _canTeamSetup(batting);

    return MatchStartState(
      match: match,

      // Display only.
      viewerRole: viewerRoleOnMatch(match, userId),
      captainOf: captainSideOf(match, userId),

      canRecordToss: canRecordToss,
      canManageBattingSetup: canManageBattingSetup,

      battingTeamId: batting,
      bowlingTeamId:
          batting == null
              ? null
              : (batting == match.teamAId ? match.teamBId : match.teamAId),

      lockedStriker: lineup.playerRefIdOf(innings?.strikerId?.value),
      lockedNonStriker: lineup.playerRefIdOf(innings?.nonStrikerId?.value),
      lockedBowler: lineup.playerRefIdOf(innings?.bowlerId?.value),

      pendingTossWinner: previous?.pendingTossWinner,
      pendingDecision: previous?.pendingDecision,
      pendingStriker: previous?.pendingStriker,
      pendingNonStriker: previous?.pendingNonStriker,
      pendingBowler: previous?.pendingBowler,

      isBusy: previous?.isBusy ?? false,
    );
  }

  // ── Capability reads ──────────────────────────────────────────────────────

  Future<bool> _canTeamSetup(TeamId? teamId) async {
    if (teamId == null) {
      return false;
    }

    final result = await _repo.canTeamPermission(
      teamId: teamId,
      permission: _cricketSetupPermission,
    );

    return result.fold((_) => false, (allowed) => allowed);
  }

  Future<bool> _canMatchSetup(MatchId id) async {
    final result = await _repo.canMatchPermission(
      matchId: id,
      permission: _cricketSetupPermission,
    );

    return result.fold((_) => false, (allowed) => allowed);
  }

  // ── Atomic toss form ──────────────────────────────────────────────────────

  void pickTossWinner(TeamId winner) {
    _update((s) => s.copyWith(pendingTossWinner: () => winner));
  }

  void pickTossDecision(TossDecision decision) {
    _update((s) => s.copyWith(pendingDecision: () => decision));
  }

  Future<Either<Failure, Unit>> submitToss() {
    final current = state.value;

    final winner = current?.pendingTossWinner;

    final decision = current?.pendingDecision;

    if (current == null || winner == null || decision == null) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Select the toss winner and whether they chose to bat or bowl',
          ),
        ),
      );
    }

    return _busy(
      () => _repo.recordToss(
        id: MatchId(matchId),
        wonBy: winner,
        decision: decision,
      ),
      label: 'recordToss',
      reset: (s) {
        final batting =
            decision == TossDecision.bat
                ? winner
                : (winner == s.match.teamAId
                    ? s.match.teamBId
                    : s.match.teamAId);

        final bowling =
            batting == s.match.teamAId ? s.match.teamBId : s.match.teamAId;

        final updatedMatch = s.match.copyWith(
          tossWonBy: winner,
          tossDecision: decision,
          startPhase: MatchStartPhase.lineup,
          status: MatchStatus.toss,
        );

        return s.copyWith(
          match: updatedMatch,
          battingTeamId: batting,
          bowlingTeamId: bowling,

          // The live provider rebuild immediately following the committed
          // snapshot recalculates effective RBAC for the batting side.
          canRecordToss: false,

          pendingTossWinner: () => null,
          pendingDecision: () => null,
        );
      },
    );
  }

  // ── Openers & Strategic Lineup ───────────────────────────────────────────

  void pickStriker(String refId) {
    _update((s) {
      final nonStriker = s.nonStriker == refId ? null : s.nonStriker;
      return s.copyWith(
        pendingStriker: () => refId,
        pendingNonStriker: () => nonStriker,
      );
    });
  }

  void pickNonStriker(String refId) {
    _update((s) {
      final striker = s.striker == refId ? null : s.striker;
      return s.copyWith(
        pendingStriker: () => striker,
        pendingNonStriker: () => refId,
      );
    });
  }

  void pickBowler(String refId) {
    _update((s) => s.copyWith(pendingBowler: () => refId));
  }

  void swapBatters() {
    _update((s) {
      final str = s.striker;
      final nonStr = s.nonStriker;
      return s.copyWith(
        pendingStriker: () => nonStr,
        pendingNonStriker: () => str,
      );
    });
  }

  void tapOpener(String refId) {
    _update((s) {
      final striker = s.striker;
      final nonStriker = s.nonStriker;

      final (String? nextStriker, String? nextNonStriker) = switch ((
        striker,
        nonStriker,
      )) {
        (null, _) => (refId, nonStriker == refId ? null : nonStriker),
        (_, null) => (striker == refId ? null : striker, refId),
        _ => (refId, nonStriker == refId ? striker : nonStriker),
      };

      return s.copyWith(
        pendingStriker: () => nextStriker,
        pendingNonStriker: () => nextNonStriker,
      );
    });
  }

  Future<Either<Failure, Unit>> submitOpeners() {
    final current = state.value;

    if (current == null || !current.isLineupReady) {
      return Future.value(
        const Left(ValidationFailure('Please select both openers')),
      );
    }

    final lineup =
        ref.read(matchPlayersProvider(matchId)).value ?? const <MatchPlayer>[];

    final strikerId = lineup.matchPlayerIdOf(current.striker);

    final nonStrikerId = lineup.matchPlayerIdOf(current.nonStriker);

    if (strikerId == null || nonStrikerId == null) {
      return Future.value(
        const Left(
          ValidationFailure(
            "Selected player is not in this match's lineup. "
            'Reopen the screen and try again.',
          ),
        ),
      );
    }

    return _busy(
      () => _repo.submitMatchOpeners(
        id: MatchId(matchId),
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
      ),
      label: 'submitOpeners',
      reset:
          (s) => s.copyWith(
            pendingStriker: () => null,
            pendingNonStriker: () => null,
          ),
    );
  }

  Future<Either<Failure, Unit>> submitOpenersAndStart() async {
    final current = state.value;

    if (current == null || !current.isLineupReady) {
      return Future.value(
        const Left(ValidationFailure('Please select both openers')),
      );
    }

    final lineup =
        ref.read(matchPlayersProvider(matchId)).value ?? const <MatchPlayer>[];

    final strikerId = lineup.matchPlayerIdOf(current.striker);

    final nonStrikerId = lineup.matchPlayerIdOf(current.nonStriker);

    if (strikerId == null || nonStrikerId == null) {
      return Future.value(
        const Left(
          ValidationFailure(
            "Selected player is not in this match's lineup. "
            'Reopen the screen and try again.',
          ),
        ),
      );
    }

    return _busy(
      () async {
        final openerResult = await _repo.submitMatchOpeners(
          id: MatchId(matchId),
          strikerId: strikerId,
          nonStrikerId: nonStrikerId,
        );

        return openerResult.fold(
          Left.new,
          (_) => _repo.startMatchNow(MatchId(matchId)),
        );
      },
      label: 'submitOpenersAndStart',
      reset:
          (s) => s.copyWith(
            pendingStriker: () => null,
            pendingNonStriker: () => null,
          ),
    );
  }

  MatchesRepository? _cachedRepo;

  MatchesRepository get _repo =>
      (_cachedRepo ??= ref.read(matchesRepositoryProvider))!;

  Future<Either<Failure, Unit>> startMatchNow() =>
      _busy(() => _repo.startMatchNow(MatchId(matchId)), label: 'startMatch');

  // ── Plumbing ─────────────────────────────────────────────────────────────

  void _update(MatchStartState Function(MatchStartState) edit) {
    if (!ref.mounted) {
      return;
    }

    final current = state.value;

    if (current == null) {
      return;
    }

    state = AsyncData(edit(current));
  }

  Future<Either<Failure, Unit>> _busy(
    Future<Either<Failure, Unit>> Function() action, {
    String label = 'action',
    MatchStartState Function(MatchStartState)? reset,
  }) async {
    _update((s) => s.copyWith(isBusy: true));

    final result = await action();

    _update((s) {
      final settled = s.copyWith(isBusy: false);

      return reset == null ? settled : reset(settled);
    });

    return result;
  }
}
