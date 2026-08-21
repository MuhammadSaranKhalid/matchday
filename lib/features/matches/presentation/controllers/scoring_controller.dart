import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/connectivity/connectivity_provider.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/lifecycle/app_lifecycle_provider.dart';
import '../../../../core/log/ck_log.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
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
  final Map<String, ({BallResult predicted, EngineBallInput input, EngineFormat format})>
      _predictions = {};

  Future<void>? _syncInFlight;
  Future<void>? _writeQueue;

  static const _uuid = Uuid();

  Future<T> _enqueueWrite<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final prev = _writeQueue ?? Future.value();
    _writeQueue = prev.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }).catchError((Object _) {
      // If previous failed, still execute subsequent actions in queue
    });
    return completer.future;
  }

  @override
  Future<ScoringState> build(String matchId, int inningsNumber) async {
    final repo = ref.watch(matchesRepositoryProvider);

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

    final pendingCount = await repo.pendingOpsCount();

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
        build: (s) => BallDraft(
          matchId: s.match.id,
          inningsNumber: inningsNumber,
          isLegalDelivery: true,
          ballKind: BallKind.legal,
          runsScored: runs,
          batsmanId: s.innings?.strikerId?.value,
          nonStrikerId: s.innings?.nonStrikerId?.value,
          bowlerId: s.innings?.bowlerId?.value,
          expectedVersion: s.innings?.version,
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
      build: (s) => BallDraft(
        matchId: s.match.id,
        inningsNumber: inningsNumber,
        isLegalDelivery: kind != BallKind.wide && kind != BallKind.noBall,
        ballKind: kind,
        runsScored: split.runsScored,
        extras: split.extras,
        batsmanId: s.innings?.strikerId?.value,
        nonStrikerId: s.innings?.nonStrikerId?.value,
        bowlerId: s.innings?.bowlerId?.value,
        expectedVersion: s.innings?.version,
      ),
    );
  }

  Future<Either<Failure, Unit>> recordWicket({
    required WicketType type,
    int runsBefore = 0,
    String? dismissedMatchPlayerId,
    String? fielderMatchPlayerId,
  }) =>
      _record(
        label: 'wicket·${type.wire}',
        build: (s) => BallDraft(
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
          expectedVersion: s.innings?.version,
        ),
      );

  /// Undo the last delivery.
  Future<Either<Failure, Unit>> undoLastBall() async {
    final current = state.value;
    if (current == null || current.balls.isEmpty) {
      return const Left(ValidationFailure('Nothing to undo'));
    }

    return _busy(
      'undo',
      () => _enqueueWrite(
        () async {
          final result = await ref.read(matchesRepositoryProvider).undoLastBall(
                matchId: current.match.id,
                inningsNumber: inningsNumber,
              );
          return result.fold(
            (failure) => Left(failure),
            (_) async {
              final repo = ref.read(matchesRepositoryProvider);
              final inningsResult = await repo.getMatchInningsState(
                matchId: current.match.id,
                inningsNumber: inningsNumber,
              );
              final ballsResult = await repo.listBalls(
                current.match.id,
                inningsNumber,
              );
              _update((st) => st.copyWith(
                    innings: inningsResult.fold((_) => st.innings, (s) => s),
                    balls: ballsResult.fold((_) => st.balls, (b) => b),
                  ));
              return const Right(unit);
            },
          );
        },
      ),
    );
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
      return Future.value(const Left(ValidationFailure(
        'Both openers must be set before choosing a bowler.',
      )));
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
    final striker = forNonStriker
        ? (s.innings?.strikerId?.value ?? '')
        : batterMatchPlayerId;
    final nonStriker = forNonStriker
        ? batterMatchPlayerId
        : (s.innings?.nonStrikerId?.value ?? '');
    final bowler = s.innings?.bowlerId?.value ?? '';
    if (striker.isEmpty || nonStriker.isEmpty || bowler.isEmpty) {
      return Future.value(const Left(ValidationFailure(
        'Set the bowler and both batters before resuming.',
      )));
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
    _update((st) => st.copyWith(
          innings: st.innings?.copyWith(
            strikerId: striker.isEmpty ? null : MatchPlayerId(striker),
            clearStriker: striker.isEmpty,
            nonStrikerId: nonStriker.isEmpty ? null : MatchPlayerId(nonStriker),
            clearNonStriker: nonStriker.isEmpty,
            bowlerId: bowler.isEmpty ? null : MatchPlayerId(bowler),
            clearBowler: bowler.isEmpty,
          ),
        ));

    return _busy(
      label,
      () => _enqueueWrite(
        () => ref.read(matchesRepositoryProvider).startInnings(
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

    final rawDraft = build(s);
    final opId = _uuid.v4();
    final draft = rawDraft.copyWith(opId: opId);

    final input = engineInputFrom(draft);
    final format = engineFormatFrom(s.match.format);

    // Predict state synchronously for instant 60fps UI
    final predicted = applyBall(
      engineStateFrom(s.innings),
      format,
      input,
      engineContextFrom(
        balls: s.balls,
        bowlerId: s.innings?.bowlerId?.value,
      ),
    );

    if (!predicted.ok) {
      CkLog.warn(CkLogChannel.matchStart, 'scoring·$label·refused', data: {
        'code': predicted.error?.code,
      });
      return Left(ValidationFailure(
        predicted.error?.message ?? 'That delivery is not legal.',
      ));
    }

    // Paint immediately on screen
    final provisional = _provisionalBall(s, predicted.ball!, opId);
    _predictions[opId] = (predicted: predicted, input: input, format: format);
    _update((st) => st.copyWith(
          innings: _projectInnings(st.innings, predicted.newState!),
          balls: [...st.balls, provisional],
          pendingCount: st.pendingCount + 1,
        ));

    // Asynchronously dispatch to repository in FIFO write queue
    unawaited(_dispatchToRepo(draft, opId));
    return const Right(unit);
  }

  Future<void> _dispatchToRepo(BallDraft draft, String opId) =>
      _enqueueWrite(() async {
        final result =
            await ref.read(matchesRepositoryProvider).recordBall(draft);
        result.fold(
          (failure) => _onSendFailed(opId, failure),
          (outcome) => _settle(opId: opId, outcome: outcome),
        );
      });

  Future<void> drainOutbox() =>
      _syncInFlight ??= ref
          .read(matchesRepositoryProvider)
          .syncPendingOps(matchId: matchId, inningsNumber: inningsNumber)
          .whenComplete(() => _syncInFlight = null);

  void _onSendFailed(String opId, Failure f) async {
    switch (f) {
      case ValidationFailure():
      case NotFoundFailure():
        _removeProvisional(opId);
        final repo = ref.read(matchesRepositoryProvider);
        final inningsResult = await repo.getMatchInningsState(
          matchId: MatchId(matchId),
          inningsNumber: inningsNumber,
        );
        final ballsResult = await repo.listBalls(
          MatchId(matchId),
          inningsNumber,
        );
        _update((st) => st.copyWith(
              innings: inningsResult.fold((_) => st.innings, (s) => s),
              balls: ballsResult.fold((_) => st.balls, (b) => b),
            ));
        break;
      case ConflictFailure():
        CkLog.warn(CkLogChannel.matchStart, 'scoring·conflict', data: {
          'msg': f.message,
        });
        break;
      default:
        // Offline / deferred: remains queued in Data Layer WAL
        break;
    }
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
  ) =>
      current?.copyWith(
        legalBallCount: next.legalBallCount,
        totalRuns: next.totalRuns,
        totalWickets: next.totalWickets,
        totalExtras: next.totalExtras,
        strikerId: next.strikerId == null
            ? null
            : MatchPlayerId(next.strikerId!),
        clearStriker: next.strikerId == null,
        nonStrikerId: next.nonStrikerId == null
            ? null
            : MatchPlayerId(next.nonStrikerId!),
        clearNonStriker: next.nonStrikerId == null,
        bowlerId:
            next.bowlerId == null ? null : MatchPlayerId(next.bowlerId!),
        clearBowler: next.bowlerId == null,
        version: current.version + 1,
      );

  void _settle({required String opId, required BallOutcome outcome}) {
    _predictions.remove(opId);
    final localId = BallId('local:$opId');

    _update((st) => st.copyWith(
          innings: outcome.innings,
          pendingCount: (st.pendingCount - 1).clamp(0, 1 << 30),
          balls: [
            for (final b in st.balls)
              if (b.id != localId && b.seq != outcome.ball.seq) b,
            outcome.ball,
          ]..sort((a, b) => a.seq.compareTo(b.seq)),
        ));
  }

  void _removeProvisional(String opId) {
    _predictions.remove(opId);
    final localId = BallId('local:$opId');
    _update((st) => st.copyWith(
          pendingCount: (st.pendingCount - 1).clamp(0, 1 << 30),
          balls: [
            for (final b in st.balls)
              if (b.id != localId) b,
          ],
        ));
  }

  void _update(ScoringState Function(ScoringState) edit) {
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
