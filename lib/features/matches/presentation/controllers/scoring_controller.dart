import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/connectivity/connectivity_provider.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/lifecycle/app_lifecycle_provider.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/repositories/matches_repository.dart';
import '../../domain/scoring/scoring_adapter.dart';
import '../../domain/scoring/scoring_engine.dart';
import '../../domain/scoring/scoring_rules.dart';
import '../../domain/scoring/scoring_types.dart';
import '../providers/matches_providers.dart';
import '../state/scoring_state.dart';

part 'scoring_controller.g.dart';

/// Owns live scoring: what the screen sees, and every write it can make.
///
/// Refactored strictly following Clean Architecture:
/// - Presentation Layer knows only the Domain Repository contract (`MatchesRepository`).
/// - All SQLite persistence, write-ahead logging (WAL), and outbox queuing live
///   exclusively inside the Data Layer (`MatchesLocalDataSource` + `MatchesRepositoryImpl`).
@riverpod
class ScoringController extends _$ScoringController {
  /// What the local engine predicted for each unsent delivery, kept so the
  /// server's answer can be compared against it when the write settles.
  final Map<
    String,
    ({BallResult predicted, EngineBallInput input, EngineFormat format})
  >
  _predictions = {};

  Future<void>? _syncInFlight;
  Future<void>? _writeQueue;
  MatchesRepository? _cachedRepo;

  MatchesRepository get _repo {
    if (_cachedRepo != null) return _cachedRepo!;
    return ref.read(matchesRepositoryProvider);
  }

  static const _uuid = Uuid();

  Future<T> _enqueueWrite<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final prev = _writeQueue ?? Future.value();
    _writeQueue = prev
        .then((_) async {
          try {
            final result = await action();
            completer.complete(result);
          } catch (e, st) {
            completer.completeError(e, st);
          }
        })
        .catchError((Object _) {
          // If previous failed, still execute subsequent actions in queue
        });
    return completer.future;
  }

  @override
  Future<ScoringState> build(String matchId, int inningsNumber) async {
    _cachedRepo = ref.watch(matchesRepositoryProvider);
    final repo = _repo;

    final matchResult = await repo.getMatch(MatchId(matchId));
    final match = matchResult.fold((f) => throw FailureWrapper(f), (m) => m);
    if (match == null) {
      throw const FailureWrapper(NotFoundFailure('Match not found'));
    }

    final inningsResult = await repo.getMatchInningsState(
      matchId: MatchId(matchId),
      inningsNumber: inningsNumber,
    );
    final innings = inningsResult.fold((f) => null, (s) => s);

    final ballsResult = await repo.listBalls(MatchId(matchId), inningsNumber);
    final balls = ballsResult.fold((f) => <Ball>[], (b) => b);

    final playersResult = await repo.listMatchPlayers(MatchId(matchId));
    final matchPlayers = playersResult.fold((f) => <MatchPlayer>[], (p) => p);

    final canScoreResult = await repo.canScoreInnings(
      matchId: MatchId(matchId),
      inningsNumber: inningsNumber,
    );
    final canScore = canScoreResult.fold((f) => false, (c) => c);

    final pendingCount = await repo.pendingOpsCount(
      matchId: MatchId(matchId),
      inningsNumber: inningsNumber,
    );

    // Trigger background sync on reconnect or app resume
    ref.listen<AsyncValue<bool>>(isOnlineProvider, (prev, next) {
      if (next.value == true && prev?.value != true) {
        unawaited(drainOutbox());
      }
    });

    ref.listen<int>(appResumeCountProvider, (prev, next) {
      if (next > (prev ?? 0)) {
        unawaited(drainOutbox());
      }
    });

    // Real-time broadcast listeners:
    // Only subscribe to live score & delivery streams if this device is NOT the active scorer.
    // The active scorer (canScore == true) is the local-first authority and manages state directly
    // through optimistic prediction and _settle().
    if (!canScore) {
      // 1. Live Innings State (total runs, wickets, overs, current striker/bowler)
      ref.listen<AsyncValue<MatchInningsState?>>(
        liveInningsStateProvider(matchId, inningsNumber),
        (prev, next) {
          final newInnings = next.value;
          if (newInnings == null) return;
          _update((s) => s.copyWith(innings: newInnings));
        },
      );

      // 2. Live Ball-by-ball deliveries
      ref.listen<AsyncValue<List<Ball>>>(
        liveBallsProvider(matchId, inningsNumber),
        (prev, next) {
          final serverBalls = next.value;
          if (serverBalls == null) return;
          _update((s) => s.copyWith(balls: serverBalls));
        },
      );
    }

    // 3. Live Match Status and Phase updates
    ref.listen<AsyncValue<Match?>>(liveMatchProvider(matchId), (prev, next) {
      final updatedMatch = next.value;
      if (updatedMatch == null) return;
      _update((s) => s.copyWith(match: updatedMatch));
    });

    // 4. Live Match Players (squad changes / keeper / subs)
    ref.listen<AsyncValue<List<MatchPlayer>>>(matchPlayersProvider(matchId), (
      prev,
      next,
    ) {
      final updatedPlayers = next.value;
      if (updatedPlayers == null) return;
      _update((s) => s.copyWith(matchPlayers: updatedPlayers));
    });

    // Kick the queue once on open, rather than waiting for a reconnect or a
    // resume. A device that scored through an outage arrives here holding
    // deliveries that were never accepted; without this the scorer has to
    // background the app to get them moving, and any that can never be
    // accepted sit in the log forever, inflating the unsaved count.
    unawaited(drainOutbox());

    return ScoringState(
      match: match,
      inningsNumber: inningsNumber,
      innings: innings,
      balls: balls,
      matchPlayers: matchPlayers,
      canScore: canScore,
      pendingCount: pendingCount,
      isBusy: false,
    );
  }

  // ── Deliveries ───────────────────────────────────────────────────────────

  /// A normal delivery off the bat (0/1/2/3/4/6).
  Future<Either<Failure, Unit>> recordRun(int runs) => _record(
    label: 'run',
    build:
        (s) => BallDraft(
          matchId: s.match.id,
          inningsNumber: inningsNumber,
          isLegalDelivery: true,
          ballKind: BallKind.legal,
          runsScored: runs,
          batsmanId: s.innings?.strikerId?.value,
          nonStrikerId: s.innings?.nonStrikerId?.value,
          bowlerId: s.innings?.bowlerId?.value,
        ),
  );

  /// A wide, no-ball, bye or leg-bye.
  Future<Either<Failure, Unit>> recordExtra({
    required BallKind kind,
    required int runs,
  }) {
    final split = splitExtraRuns(kind, runs);
    return _record(
      label: 'extra·${kind.wire}',
      build:
          (s) => BallDraft(
            matchId: s.match.id,
            inningsNumber: inningsNumber,
            isLegalDelivery: kind != BallKind.wide && kind != BallKind.noBall,
            ballKind: kind,
            runsScored: split.runsScored,
            extras: split.extras,
            batsmanId: s.innings?.strikerId?.value,
            nonStrikerId: s.innings?.nonStrikerId?.value,
            bowlerId: s.innings?.bowlerId?.value,
          ),
    );
  }

  Future<Either<Failure, Unit>> recordWicket({
    required WicketType type,
    int runsBefore = 0,
    String? dismissedMatchPlayerId,
    String? fielderMatchPlayerId,
  }) => _record(
    label: 'wicket·${type.wire}',
    build:
        (s) => BallDraft(
          matchId: s.match.id,
          inningsNumber: inningsNumber,
          isLegalDelivery: true,
          ballKind: BallKind.legal,
          runsScored: runsBefore,
          isWicket: true,
          wicketType: type,
          dismissedPlayerId:
              dismissedMatchPlayerId ?? s.innings?.strikerId?.value,
          batsmanId: s.innings?.strikerId?.value,
          nonStrikerId: s.innings?.nonStrikerId?.value,
          bowlerId: s.innings?.bowlerId?.value,
          fielderId: fielderMatchPlayerId,
        ),
  );

  /// Undo the last delivery — one step back, never further.
  Future<Either<Failure, Unit>> undoLastBall() async {
    final current = state.value;
    if (current == null || current.balls.isEmpty) {
      return const Left(ValidationFailure('Nothing to undo'));
    }

    return _busy(
      'undo',
      () => _enqueueWrite(() async {
        // The last painted delivery is either still provisional — in which
        // case its op id is embedded in the local ball id — or a row the
        // server already holds. Only this side knows which.
        final lastId = current.balls.last.id.value;
        const localPrefix = 'local:';
        final pendingOpId =
            lastId.startsWith(localPrefix)
                ? lastId.substring(localPrefix.length)
                : null;

        final result = await _repo.undoLastBall(
          matchId: current.match.id,
          inningsNumber: inningsNumber,
          pendingOpId: pendingOpId,
        );

        final failure = result.getLeft().toNullable();
        if (failure != null) return Left(failure);

        final outcome = result.getRight().toNullable()!;
        switch (outcome.kind) {
          case UndoKind.discardedPending:
            // The delivery never left the device, so this is purely local.
            // Re-reading the ball list from the server here would erase every
            // OTHER unsent delivery — the server has not seen any of them.
            _undoPending(outcome.opId!);
          case UndoKind.removedStored:
            await _resyncFromServer();
          case UndoKind.nothing:
            break;
        }
        return const Right(unit);
      }),
    );
  }

  /// Roll one queued delivery back out of the local projection.
  ///
  /// The trio is restored from the delivery being removed — every ball records
  /// who was on strike and who was bowling when it was bowled, so undoing ball
  /// N means putting back exactly what ball N stored. The totals are recounted
  /// from what remains rather than subtracted, for the same reason the server
  /// does it that way: there is no reversal arithmetic to get wrong.
  void _undoPending(String opId) {
    final localId = BallId('local:$opId');
    _update((st) {
      final removed = st.balls.where((b) => b.id == localId).firstOrNull;
      final remaining = [
        for (final b in st.balls)
          if (b.id != localId) b,
      ];
      return st.copyWith(
        balls: remaining,
        pendingCount: (st.pendingCount - 1).clamp(0, 1 << 30),
        innings:
            removed == null
                ? st.innings
                : st.innings?.copyWith(
                  legalBallCount:
                      remaining.where((b) => b.isLegalDelivery).length,
                  totalRuns: remaining.fold<int>(
                    0,
                    (sum, b) => sum + b.totalRuns,
                  ),
                  totalWickets: remaining.where((b) => b.isWicket).length,
                  strikerId:
                      removed.batsmanId == null
                          ? null
                          : MatchPlayerId(removed.batsmanId!),
                  clearStriker: removed.batsmanId == null,
                  nonStrikerId:
                      removed.nonStrikerId == null
                          ? null
                          : MatchPlayerId(removed.nonStrikerId!),
                  clearNonStriker: removed.nonStrikerId == null,
                  bowlerId:
                      removed.bowlerId == null
                          ? null
                          : MatchPlayerId(removed.bowlerId!),
                  clearBowler: removed.bowlerId == null,
                ),
      );
    });
    _predictions.remove(opId);
  }

  // ── On-field changes ─────────────────────────────────────────────────────

  Future<Either<Failure, Unit>> setBowler(String bowlerMatchPlayerId) {
    final s = state.value;
    if (s == null) {
      return Future.value(const Left(ValidationFailure('Not ready')));
    }
    var striker = s.innings?.strikerId?.value ?? '';
    var nonStriker = s.innings?.nonStrikerId?.value ?? '';
    if (striker.isEmpty || nonStriker.isEmpty) {
      final squad = s.availableBatters;
      if (striker.isEmpty && squad.isNotEmpty) {
        striker = squad.first.matchPlayerId;
      }
      if (nonStriker.isEmpty) {
        final remaining =
            squad.where((p) => p.matchPlayerId != striker).toList();
        if (remaining.isNotEmpty) {
          nonStriker = remaining.first.matchPlayerId;
        }
      }
    }
    if (striker.isEmpty || nonStriker.isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Both openers must be set before choosing a bowler.',
          ),
        ),
      );
    }
    if (s.lastOverBowlerId != null &&
        bowlerMatchPlayerId == s.lastOverBowlerId &&
        s.legalBalls % s.ballsPerOver == 0) {
      return Future.value(
        const Left(
          ValidationFailure('A bowler cannot bowl two consecutive overs.'),
        ),
      );
    }
    return _setTrio(
      label: 'setBowler',
      striker: striker,
      nonStriker: nonStriker,
      bowler: bowlerMatchPlayerId,
    );
  }

  Future<Either<Failure, Unit>> bringInBatter(
    String batterMatchPlayerId, {
    bool forNonStriker = false,
  }) {
    final s = state.value;
    if (s == null) {
      return Future.value(const Left(ValidationFailure('Not ready')));
    }
    final striker =
        forNonStriker
            ? (s.innings?.strikerId?.value ?? '')
            : batterMatchPlayerId;
    final nonStriker =
        forNonStriker
            ? batterMatchPlayerId
            : (s.innings?.nonStrikerId?.value ?? '');
    final bowler = s.innings?.bowlerId?.value ?? '';
    if (striker.isEmpty || nonStriker.isEmpty || bowler.isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('Set the bowler and both batters before resuming.'),
        ),
      );
    }
    return _setTrio(
      label: 'bringInBatter',
      striker: striker,
      nonStriker: nonStriker,
      bowler: bowler,
    );
  }

  Future<Either<Failure, Unit>> _setTrio({
    required String label,
    required String striker,
    required String nonStriker,
    required String bowler,
  }) {
    final s = state.value;
    if (s == null) {
      return Future.value(const Left(ValidationFailure('Not ready')));
    }

    // Update trio locally immediately
    _update(
      (st) => st.copyWith(
        innings: st.innings?.copyWith(
          strikerId: striker.isEmpty ? null : MatchPlayerId(striker),
          clearStriker: striker.isEmpty,
          nonStrikerId: nonStriker.isEmpty ? null : MatchPlayerId(nonStriker),
          clearNonStriker: nonStriker.isEmpty,
          bowlerId: bowler.isEmpty ? null : MatchPlayerId(bowler),
          clearBowler: bowler.isEmpty,
        ),
      ),
    );

    return _busy(
      label,
      () => _enqueueWrite(
        () => _repo.startInnings(
          matchId: s.match.id,
          inningsNumber: inningsNumber,
          strikerId: striker,
          nonStrikerId: nonStriker,
          bowlerId: bowler,
        ),
      ),
    );
  }

  // ── Plumbing ─────────────────────────────────────────────────────────────

  Future<Either<Failure, Unit>> _record({
    required String label,
    required BallDraft Function(ScoringState) build,
  }) async {
    final s = state.value;
    if (s == null) {
      return const Left(ValidationFailure('Not ready'));
    }
    if (!s.canScore) {
      return const Left(AuthFailure('You are not scoring this innings.'));
    }
    if (!s.bowlerSet) {
      return const Left(
        ValidationFailure('Choose a bowler before recording a delivery.'),
      );
    }
    // A wicket clears whichever end the dismissed batter was at. Recording a
    // delivery before it is refilled credits it to nobody: a real innings
    // reached 182/5 through four consecutive wickets and then logged a single
    // with the non-striker's end empty. The pad now gates on this too; this is
    // the backstop for every other route into a write.
    if (!s.battersSet) {
      return const Left(
        ValidationFailure(
          'Choose the next batter before recording a delivery.',
        ),
      );
    }

    final rawDraft = build(s);
    final opId = _uuid.v4();

    final input = engineInputFrom(rawDraft);
    final format = engineFormatFrom(s.match.format);

    // The engine runs HERE and only here. This is not a prediction the server
    // will check — the server has no engine (design doc D10). It is the answer,
    // computed on the one device that can compute it during a signal gap, and
    // the server stores it.
    final predicted = applyBall(
      engineStateFrom(s.innings),
      format,
      input,
      engineContextFrom(balls: s.balls, bowlerId: s.innings?.bowlerId?.value),
    );

    if (!predicted.ok) {
      return Left(
        ValidationFailure(
          predicted.error?.message ?? 'That delivery is not legal.',
        ),
      );
    }

    final ball = predicted.ball!;
    final next = predicted.newState!;
    final events = predicted.events!;

    // Everything the server needs and cannot work out for itself: where the
    // delivery sat in the over, who is on strike now, and whether the innings
    // is over. `opId` travels as the idempotency key so a retry after a
    // dropped connection cannot record the delivery twice.
    final draft = rawDraft.copyWith(
      opId: opId,
      computed: ComputedDelivery(
        overNumber: ball.overNumber,
        ballInOver: ball.ballInOver,
        isFreeHit: ball.isFreeHit,
        inningsEnded: events.inningsEnded,
        isAllOut: events.allOut,
        ballsPerOver: format.ballsPerOver,
        strikerAfter: next.strikerId,
        nonStrikerAfter: next.nonStrikerId,
        bowlerAfter: next.bowlerId,
        isBowlerCredited: creditedToBowler(ball.wicketType),
      ),
    );

    // Paint immediately on screen
    final provisional = _provisionalBall(s, ball, opId);
    _predictions[opId] = (predicted: predicted, input: input, format: format);
    _update(
      (st) => st.copyWith(
        innings: _projectInnings(st.innings, next),
        balls: [...st.balls, provisional],
        pendingCount: st.pendingCount + 1,
      ),
    );

    // Asynchronously dispatch to repository in FIFO write queue
    unawaited(_dispatchToRepo(draft, opId));
    return const Right(unit);
  }

  Future<void> _dispatchToRepo(BallDraft draft, String opId) =>
      _enqueueWrite(() async {
        final result = await _repo.recordBall(draft);
        result.fold(
          (failure) => _onSendFailed(opId, failure),
          (outcome) => _settle(opId: opId, outcome: outcome),
        );
      });

  Future<void> drainOutbox() =>
      _syncInFlight ??= _repo
          .syncPendingOps(matchId: matchId, inningsNumber: inningsNumber)
          .whenComplete(() => _syncInFlight = null);

  void _onSendFailed(String opId, Failure f) async {
    switch (f) {
      case ValidationFailure():
      case NotFoundFailure():
        _removeProvisional(opId);
        await _resyncFromServer();
        break;
      case ConflictFailure():
        _removeProvisional(opId);
        await _resyncFromServer();
        break;
      default:
        // Offline / deferred: remains queued in Data Layer WAL
        break;
    }
  }

  /// Replace the local innings and ball log with the server's, after a write
  /// was refused. The delivery is gone; showing the scorer anything other than
  /// what was actually recorded is worse than showing them less.
  Future<void> _resyncFromServer() async {
    final inningsResult = await _repo.getMatchInningsState(
      matchId: MatchId(matchId),
      inningsNumber: inningsNumber,
    );
    final ballsResult = await _repo.listBalls(MatchId(matchId), inningsNumber);
    _update(
      (st) => st.copyWith(
        innings: inningsResult.fold((_) => st.innings, (s) => s),
        balls: ballsResult.fold((_) => st.balls, (b) => b),
      ),
    );
  }

  Ball _provisionalBall(ScoringState s, ComputedBall c, String opId) => Ball(
    id: BallId('local:$opId'),
    matchId: s.match.id,
    inningsNumber: inningsNumber,
    seq: (s.balls.isEmpty ? 0 : s.balls.last.seq) + 1,
    overNumber: c.overNumber,
    ballInOver: c.ballInOver,
    isLegalDelivery: c.isLegalDelivery,
    ballKind: c.ballKind,
    runsScored: c.runsScored,
    extras: c.extras,
    isWicket: c.isWicket,
    isFreeHit: c.isFreeHit,
    wicketType: c.wicketType,
    dismissedPlayerId: c.dismissedPlayerId,
    batsmanId: c.batsmanId,
    nonStrikerId: c.nonStrikerId,
    bowlerId: c.bowlerId,
    fielderId: c.fielderId,
    commentary: c.commentary,
  );

  MatchInningsState? _projectInnings(
    MatchInningsState? current,
    NewInningsState next,
  ) => current?.copyWith(
    legalBallCount: next.legalBallCount,
    totalRuns: next.totalRuns,
    totalWickets: next.totalWickets,
    totalExtras: next.totalExtras,
    strikerId: next.strikerId == null ? null : MatchPlayerId(next.strikerId!),
    clearStriker: next.strikerId == null,
    nonStrikerId:
        next.nonStrikerId == null ? null : MatchPlayerId(next.nonStrikerId!),
    clearNonStriker: next.nonStrikerId == null,
    bowlerId: next.bowlerId == null ? null : MatchPlayerId(next.bowlerId!),
    clearBowler: next.bowlerId == null,
    version: current.version + 1,
  );

  void _settle({required String opId, required BallOutcome outcome}) {
    _predictions.remove(opId);
    final localId = BallId('local:$opId');

    _update((st) {
      final remaining = (st.pendingCount - 1).clamp(0, 1 << 30);

      // ── Do NOT rewind the innings while deliveries are still owed ────────
      //
      // `outcome.innings` is the server's row as of THIS delivery. When the
      // scorer has already tapped further balls, the local count has moved
      // past it, and adopting it wholesale drags the innings backwards.
      //
      // That produced duplicate ball numbers in a single over — 8.1, 8.2,
      // 8.3, 8.4, 8.2, 8.3, 8.4 — because `over_number` and `ball_in_over`
      // are derived from `legalBallCount` at tap time. Rewinding the count
      // made the next tap recompute a position that had already been used.
      // The delivery COUNT stayed correct throughout, which is why the score
      // looked right while the over fell apart.
      //
      // The device owns the arithmetic (design doc D10), so the server's row
      // is a confirmation, never a correction. Adopt it only once the queue
      // has drained — at that point it reflects every delivery the device has
      // and the two agree, so taking it costs nothing and refreshes `version`.
      final caughtUp = remaining == 0;

      return st.copyWith(
        innings: caughtUp ? (outcome.innings ?? st.innings) : st.innings,
        pendingCount: remaining,
        balls: [
          // Match on the provisional's own id ONLY. Matching on `seq` too
          // used to discard a DIFFERENT delivery that was still pending:
          // provisional seqs are local guesses, so they collide with the
          // real ones the server hands back.
          for (final b in st.balls)
            if (b.id != localId) b,
          outcome.ball,
        ]..sort((a, b) => a.seq.compareTo(b.seq)),
      );
    });
  }

  void _removeProvisional(String opId) {
    _predictions.remove(opId);
    final localId = BallId('local:$opId');
    _update(
      (st) => st.copyWith(
        pendingCount: (st.pendingCount - 1).clamp(0, 1 << 30),
        balls: [
          for (final b in st.balls)
            if (b.id != localId) b,
        ],
      ),
    );
  }

  void _update(ScoringState Function(ScoringState) edit) {
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncData(edit(current));
  }

  Future<Either<Failure, Unit>> _busy(
    String label,
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    _update((s) => s.copyWith(isBusy: true));
    final result = await action();
    _update((s) => s.copyWith(isBusy: false));
    return result;
  }
}
