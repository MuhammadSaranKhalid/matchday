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

/// Watches the match row in real time and owns every Match Start decision:
/// who the viewer is, which openers are selected, and the three writes
/// (toss → openers → start).
///
/// Widgets read [MatchStartState] and call these methods; they never merge
/// pending-vs-locked selections or translate between id spaces themselves.
@riverpod
class MatchStartController extends _$MatchStartController {
  @override
  Future<MatchStartState> build(String matchId) async {
    final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    final match = ref.watch(liveMatchProvider(matchId)).value;
    if (match == null) {
      throw const FailureWrapper(NotFoundFailure('Match not found'));
    }

    // Openers already locked server-side, translated from match_player_ids
    // back to the ref ids the picker speaks.
    final lineup = ref.watch(matchPlayersProvider(matchId)).value ?? const [];
    final innings = ref.watch(liveInningsStateProvider(matchId, 1)).value;

    final previous = state.value;
    final batting = battingFirstTeam(match);
    final role = viewerRoleOnMatch(match, userId);

    return MatchStartState(
      match: match,
      viewerRole: role,
      captainOf: captainSideOf(match, userId),
      isCreator: userId != null && userId == match.createdBy,
      battingTeamId: batting,
      bowlingTeamId: batting == null
          ? null
          : (batting == match.teamAId ? match.teamBId : match.teamAId),
      lockedStriker: lineup.playerRefIdOf(innings?.strikerId?.value),
      lockedNonStriker: lineup.playerRefIdOf(innings?.nonStrikerId?.value),
      pendingTossWinner: previous?.pendingTossWinner,
      pendingDecision: previous?.pendingDecision,
      pendingStriker: previous?.pendingStriker,
      pendingNonStriker: previous?.pendingNonStriker,
      isBusy: previous?.isBusy ?? false,
    );
  }

  // ── Toss ─────────────────────────────────────────────────────────────────

  void pickTossWinner(TeamId winner) =>
      _update((s) => s.copyWith(pendingTossWinner: () => winner));

  void pickTossDecision(TossDecision decision) =>
      _update((s) => s.copyWith(pendingDecision: () => decision));

  /// Act one — the creator records who won. Only the winner is written; the
  /// call belongs to the winning captain's phone.
  Future<Either<Failure, Unit>> submitTossWinner() {
    final current = state.value;
    final winner = current?.pendingTossWinner;
    if (current == null || winner == null) {
      return Future.value(
        const Left(ValidationFailure('Please select who won the toss')),
      );
    }

    return _busy(
      () => _repo.recordTossWinner(id: MatchId(matchId), wonBy: winner),
      label: 'submitTossWinner',
      // Optimistically advance to the decision step so this phone flips to
      // "waiting on their call" without a Realtime roundtrip.
      reset: (s) => s.copyWith(
        match: s.match.copyWith(
          tossWonBy: winner,
          startPhase: MatchStartPhase.toss,
          status: MatchStatus.toss,
        ),
        pendingTossWinner: () => null,
        pendingDecision: () => null,
      ),
    );
  }

  /// Act two — the winning captain calls it. This is what settles which side
  /// bats, so it is also what fixes every downstream role.
  Future<Either<Failure, Unit>> submitTossDecision() {
    final current = state.value;
    final decision = current?.pendingDecision;
    if (current == null || decision == null) {
      return Future.value(
        const Left(ValidationFailure('Please choose to bat or bowl')),
      );
    }

    return _busy(
      () => _repo.recordTossDecision(id: MatchId(matchId), decision: decision),
      label: 'submitTossDecision',
      // Optimistically update the state so the screen transitions to Lineup
      // immediately without waiting for the Realtime stream roundtrip.
      reset: (s) {
        final winner = s.match.tossWonBy;
        if (winner == null) return s;
        final batting = decision == TossDecision.bat
            ? winner
            : (winner == s.match.teamAId ? s.match.teamBId : s.match.teamAId);
        final bowling =
            batting == s.match.teamAId ? s.match.teamBId : s.match.teamAId;
        final updatedMatch = s.match.copyWith(
          tossDecision: decision,
          startPhase: MatchStartPhase.lineup,
          status: MatchStatus.toss,
        );
        return s.copyWith(
          match: updatedMatch,
          viewerRole: viewerRoleOnMatch(updatedMatch, _viewerId),
          battingTeamId: batting,
          bowlingTeamId: bowling,
          pendingDecision: () => null,
        );
      },
    );
  }

  String? get _viewerId => ref.read(supabaseClientProvider).auth.currentUser?.id;

  // ── Openers ──────────────────────────────────────────────────────────────

  /// Tap-to-assign: fills the striker slot first, then the non-striker, then
  /// replaces the striker. Tapping a player already holding the other slot
  /// swaps the two.
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
        const Left(ValidationFailure(
          "Selected player is not in this match's lineup. "
          'Reopen the screen and try again.',
        )),
      );
    }

    return _busy(
      () => _repo.submitMatchOpeners(
            id: MatchId(matchId),
            strikerId: strikerId,
            nonStrikerId: nonStrikerId,
          ),
      label: 'submitOpeners',
      // Once persisted the openers come back as `locked*` on the next build.
      reset: (s) => s.copyWith(
        pendingStriker: () => null,
        pendingNonStriker: () => null,
      ),
    );
  }

  /// Submits the chosen openers and immediately commences the match.
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
        const Left(ValidationFailure(
          "Selected player is not in this match's lineup. "
          'Reopen the screen and try again.',
        )),
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
      reset: (s) => s.copyWith(
        pendingStriker: () => null,
        pendingNonStriker: () => null,
      ),
    );
  }

  MatchesRepository? _cachedRepo;

  MatchesRepository get _repo =>
      _cachedRepo ?? ref.read(matchesRepositoryProvider);

  // ── Start ────────────────────────────────────────────────────────────────

  Future<Either<Failure, Unit>> startMatchNow() => _busy(
        () => _repo.startMatchNow(MatchId(matchId)),
        label: 'startMatch',
      );

  // ── Plumbing ─────────────────────────────────────────────────────────────

  /// Apply a synchronous edit to the loaded state. No-op while loading.
  void _update(MatchStartState Function(MatchStartState) edit) {
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncData(edit(current));
  }

  /// Run a write with the busy flag raised, then lower it and apply [reset].
  ///
  /// Re-reads `state` after the await because the live row may have arrived
  /// mid-flight — resetting onto the stale snapshot would discard it.
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
