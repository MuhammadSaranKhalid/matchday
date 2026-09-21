// Live scoring for one innings: the server's confirmed state, the queue of
// writes it has not accepted yet, and the projection of the two.
//
// This is the whole local-first write path (banner exemption 2) in one object.
// It used to be spread between the controller (queue, retries, provisional
// balls, settle/rollback) and the repository (write-ahead log, drain loop),
// which meant the screen's idea of the innings and the log's idea of it were
// maintained by different code and could disagree — and did.
//
// The rules it keeps:
//
//   • Reads of the confirmed base go through the repository, so the offline
//     read cache applies here too.
//   • Writes go through the remote data source, because a replayed op sends a
//     payload this object built, not one a repository method rebuilt.
//   • Nothing outside this file knows the queue exists, or that a ball on
//     screen might be provisional.
//
// Single writer, append-only, deterministic, bounded. No merge, no LWW.
import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/entities/scoring_projection.dart';
import '../../domain/repositories/matches_repository.dart';
import '../../domain/scoring/scoring_adapter.dart';
import '../../domain/scoring/scoring_engine.dart';
import '../../domain/scoring/scoring_replay.dart';
import '../datasources/matches_local_datasource.dart';
import '../datasources/matches_remote_datasource.dart';
import '../models/ball_draft_payload.dart';

class ScoringSession {
  ScoringSession({
    required MatchesRepository repository,
    required MatchesRemoteDataSource remote,
    required this.matchId,
    required this.inningsNumber,
    MatchesLocalDataSource? local,
    Uuid uuid = const Uuid(),
    Duration retryDelay = const Duration(seconds: 8),
  }) : _repository = repository,
       _remote = remote,
       _local = local,
       _uuid = uuid,
       _retryDelay = retryDelay;

  final MatchesRepository _repository;
  final MatchesRemoteDataSource _remote;
  final MatchesLocalDataSource? _local;
  final Uuid _uuid;
  final Duration _retryDelay;

  final String matchId;
  final int inningsNumber;

  // ── Confirmed base: what the server has told us ──────────────────────────
  Match? _match;
  MatchInningsState? _innings;
  List<Ball> _balls = const [];
  List<MatchPlayer> _players = const [];
  bool _canScore = false;

  // ── The queue: what it has not told us back yet ──────────────────────────
  final List<PendingScoringOp> _pending = [];
  final Map<String, Failure> _refusals = {};

  final _changes = StreamController<ScoringProjection>.broadcast();
  ScoringProjection? _current;
  Future<void>? _draining;
  Timer? _retryTimer;
  bool _disposed = false;

  /// The projection, re-emitted whenever either ingredient changes.
  Stream<ScoringProjection> get changes => _changes.stream;

  /// The latest projection, or null before [load].
  ScoringProjection? get current => _current;

  // ── Loading ──────────────────────────────────────────────────────────────

  /// Read the confirmed base and restore the queue from the write-ahead log.
  Future<Either<Failure, ScoringProjection>> load() async {
    final matchResult = await _repository.getMatch(MatchId(matchId));
    final failure = matchResult.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final match = matchResult.getRight().toNullable();
    if (match == null) {
      return const Left(NotFoundFailure('Match not found'));
    }
    _match = match;

    await _readBase();
    await _restoreQueue();

    final projection = _emit();

    // Kick the queue on open rather than waiting for a reconnect or a resume.
    // A device that scored through an outage arrives holding deliveries that
    // were never accepted; without this the scorer has to background the app
    // to get them moving.
    unawaited(drain());

    return Right(projection);
  }

  Future<void> _readBase() async {
    final inningsResult = await _repository.getMatchInningsState(
      matchId: MatchId(matchId),
      inningsNumber: inningsNumber,
    );
    final ballsResult = await _repository.listBalls(
      MatchId(matchId),
      inningsNumber,
    );
    final playersResult = await _repository.listMatchPlayers(MatchId(matchId));
    final canScoreResult = await _repository.canScoreInnings(
      matchId: MatchId(matchId),
      inningsNumber: inningsNumber,
    );

    _innings = inningsResult.fold((_) => _innings, (s) => s);
    _balls = ballsResult.fold((_) => _balls, (b) => b);
    _players = playersResult.fold((_) => _players, (p) => p);
    _canScore = canScoreResult.fold((_) => _canScore, (c) => c);
  }

  /// Re-read only what a write can have changed. Used after a refusal, when
  /// the device's picture is known to be wrong and the server's is the answer.
  Future<void> _refreshBase() async {
    final inningsResult = await _repository.getMatchInningsState(
      matchId: MatchId(matchId),
      inningsNumber: inningsNumber,
    );
    final ballsResult = await _repository.listBalls(
      MatchId(matchId),
      inningsNumber,
    );
    _innings = inningsResult.fold((_) => _innings, (s) => s);
    _balls = ballsResult.fold((_) => _balls, (b) => b);
    _emit();
  }

  Future<void> _restoreQueue() async {
    final local = _local;
    if (local == null) return;

    final rows = await local.pendingOps(
      matchId: matchId,
      inningsNumber: inningsNumber,
    );

    _pending.clear();
    for (final row in rows) {
      switch (row.kind) {
        case 'ball':
          final draft = ballDraftFromWal(row.payload);
          if (draft == null) {
            // Unreadable payload. It can never be sent and can never be
            // replayed, so leaving it queued would hold the unsaved count
            // above zero for the rest of the match.
            await local.discardOp(row.opId);
            continue;
          }
          _pending.add(PendingBall(opId: row.opId, draft: draft));
        case 'set_trio':
          final trio = trioFromWal(row.payload);
          if (trio == null) {
            await local.discardOp(row.opId);
            continue;
          }
          _pending.add(
            PendingTrio(
              opId: row.opId,
              strikerId: trio.strikerId,
              nonStrikerId: trio.nonStrikerId,
              bowlerId: trio.bowlerId,
              target: trio.target,
            ),
          );
        default:
          await local.discardOp(row.opId);
      }
    }
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  /// Queue one delivery.
  ///
  /// Returns as soon as the delivery is durable and on screen. Whether the
  /// server has it is a separate question, answered by the queue.
  Future<Either<Failure, Unit>> record(BallDraft draft) async {
    final projection = _current;
    if (projection == null || _match == null) {
      return const Left(ValidationFailure('Not ready'));
    }
    if (!projection.canScore) {
      return const Left(AuthFailure('You are not scoring this innings.'));
    }
    if ((draft.ballKind == BallKind.bye || draft.ballKind == BallKind.legBye) &&
        draft.runsScored != 0) {
      return const Left(
        ValidationFailure('Bye / leg-bye runs belong in extras'),
      );
    }

    // Ask the engine before accepting it. The replay will ask again — this one
    // exists so an illegal delivery is refused to the scorer's face instead of
    // being queued and silently dropped during the fold.
    final verdict = applyBall(
      engineStateFrom(projection.innings),
      engineFormatFrom(_match!.format),
      engineInputFrom(draft),
      engineContextFrom(
        balls: projection.balls,
        bowlerId: projection.innings?.bowlerId?.value,
      ),
    );
    if (!verdict.ok) {
      return Left(
        ValidationFailure(
          verdict.error?.message ?? 'That delivery is not legal.',
        ),
      );
    }

    final opId = _uuid.v4();
    await _append(opId: opId, kind: 'ball', payload: ballDraftToWal(draft));
    _pending.add(PendingBall(opId: opId, draft: draft));
    _emit();

    unawaited(drain());
    return const Right(unit);
  }

  /// Set the on-field trio, queued like a delivery.
  ///
  /// Unlike [record] this waits for the queue to reach it, so a rule the
  /// server enforces (and this device does not) is reported to the scorer
  /// rather than swallowed.
  Future<Either<Failure, Unit>> setTrio({
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
    int? target,
  }) async {
    if (strikerId.isEmpty || nonStrikerId.isEmpty || bowlerId.isEmpty) {
      return const Left(
        ValidationFailure('Striker, non-striker, and bowler are all required'),
      );
    }
    if (strikerId == nonStrikerId) {
      return const Left(
        ValidationFailure('Striker and non-striker must be different'),
      );
    }

    final opId = _uuid.v4();
    await _append(
      opId: opId,
      kind: 'set_trio',
      payload: trioToWal(
        matchId: matchId,
        inningsNumber: inningsNumber,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        bowlerId: bowlerId,
        target: target,
      ),
    );
    _pending.add(
      PendingTrio(
        opId: opId,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        bowlerId: bowlerId,
        target: target,
      ),
    );
    _emit();

    await drain();

    final refusal = _refusals.remove(opId);
    return refusal == null ? const Right(unit) : Left(refusal);
  }

  /// Undo the last delivery — one step back, never further.
  ///
  /// A delivery still in the queue never left the device, so removing it is
  /// purely local: re-reading from the server here would erase every OTHER
  /// unsent delivery, none of which the server has seen.
  Future<Either<Failure, Unit>> undo() async {
    final projection = _current;
    if (projection == null) return const Left(ValidationFailure('Not ready'));

    PendingBall? queued;
    for (final op in _pending.reversed) {
      if (op is PendingBall) {
        queued = op;
        break;
      }
    }
    if (queued != null) {
      _pending.remove(queued);
      await _discard(queued.opId);
      _emit();
      return const Right(unit);
    }

    if (projection.balls.isEmpty) {
      return const Left(ValidationFailure('Nothing to undo'));
    }

    try {
      final removed = await _remote.undoLastBall(
        matchId: matchId,
        inningsNumber: inningsNumber,
      );
      if (removed) await _refreshBase();
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ── The queue ────────────────────────────────────────────────────────────

  /// Send everything owed to the server, oldest first.
  ///
  /// Re-entrant by design: concurrent callers (a tap, a reconnect, a resume)
  /// join the drain already running rather than starting a second one, which
  /// is what keeps the queue FIFO without a separate write lock.
  Future<void> drain() {
    _retryTimer?.cancel();
    if (_disposed) return Future.value();
    return _draining ??= _runDrain().whenComplete(() {
      _draining = null;
      if (_pending.isNotEmpty && !_disposed) {
        _retryTimer = Timer(_retryDelay, () {
          if (!_disposed) unawaited(drain());
        });
      }
    });
  }

  Future<void> _runDrain() async {
    var refused = false;

    while (_pending.isNotEmpty && !_disposed) {
      final op = _pending.first;
      try {
        switch (op) {
          case PendingBall(:final draft):
            final computed = _current?.computedByOpId[op.opId];
            if (computed == null) {
              // The replay could not place this delivery, so there is no
              // answer to send. Dropping it is the only option that unblocks
              // everything queued behind it.
              _pending.remove(op);
              await _discard(op.opId);
              refused = true;
              continue;
            }
            final result = await _remote.recordBall(
              recordBallParams(draft, opId: op.opId, computed: computed),
            );
            _pending.remove(op);
            await _markSynced(op.opId);
            _adopt(result);

          case PendingTrio(
            :final strikerId,
            :final nonStrikerId,
            :final bowlerId,
            :final target,
          ):
            await _remote.startInnings(
              matchId: matchId,
              inningsNumber: inningsNumber,
              strikerId: strikerId,
              nonStrikerId: nonStrikerId,
              bowlerId: bowlerId,
              target: target,
            );
            _pending.remove(op);
            await _markSynced(op.opId);
            _innings = _innings?.copyWith(
              strikerId: MatchPlayerId(strikerId),
              nonStrikerId: MatchPlayerId(nonStrikerId),
              bowlerId: MatchPlayerId(bowlerId),
              target: target,
            );
        }
        _emit();
      } on NetworkException catch (e) {
        // Never reached the server. Stop draining — the ops behind this one
        // must not overtake it — and try again on the next trigger.
        await _markFailed(op.opId, e.message);
        break;
      } on ConflictException catch (e) {
        refused = _refuse(op, ConflictFailure(e.message), e.message);
      } on UnauthorizedException catch (e) {
        refused = _refuse(op, AuthFailure(e.message), e.message);
      } on ServerException catch (e) {
        refused = _refuse(op, ServerFailure(e.message), e.message);
      } catch (e) {
        refused = _refuse(op, UnknownFailure(e.toString()), e.toString());
      }
    }

    if (refused) {
      // The device's picture is wrong in a way it cannot work out for itself.
      await _refreshBase();
    } else if (_pending.isEmpty) {
      await _prune();
    }
  }

  /// A refusal is terminal: the server answered, and retrying a no produces
  /// another no. The op leaves the queue but stays in the log, readable.
  bool _refuse(PendingScoringOp op, Failure failure, String reason) {
    _pending.remove(op);
    _refusals[op.opId] = failure;
    unawaited(_markRefused(op.opId, reason));
    _emit();
    return true;
  }

  /// Take the server's row for a delivery it has just accepted.
  ///
  /// Safe to do mid-queue: the remaining ops replay on top of the new base, so
  /// their over positions are recomputed against it rather than against a
  /// stale count. This is what the old `caughtUp` guard was working around.
  void _adopt(RecordBallResult result) {
    final confirmed = result.ball.toEntity();
    _balls = [
      for (final b in _balls)
        if (b.id != confirmed.id) b,
      confirmed,
    ]..sort((a, b) => a.seq.compareTo(b.seq));
    _innings = result.innings?.toEntity() ?? _innings;
  }

  // ── Projection ───────────────────────────────────────────────────────────

  ScoringProjection _emit() {
    final projection = replayScoring(
      match: _match!,
      innings: _innings,
      balls: _balls,
      matchPlayers: _players,
      canScore: _canScore,
      pending: List.of(_pending),
    );
    _current = projection;
    if (!_changes.isClosed) _changes.add(projection);
    return projection;
  }

  // ── Write-ahead log (all no-ops when there is no local database) ─────────

  Future<void> _append({
    required String opId,
    required String kind,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _local?.appendOp(
        opId: opId,
        matchId: matchId,
        inningsNumber: inningsNumber,
        kind: kind,
        payload: payload,
      );
    } catch (_) {
      // A delivery that cannot be logged is still a delivery. Keep it in
      // memory and send it; durability across a kill is what is lost, not
      // the ball.
    }
  }

  Future<void> _markSynced(String opId) async => _local?.markOpSynced(opId);

  Future<void> _markFailed(String opId, String error) async =>
      _local?.markOpFailed(opId, error);

  Future<void> _markRefused(String opId, String reason) async =>
      _local?.markOpRefused(opId, reason);

  Future<void> _discard(String opId) async => _local?.discardOp(opId);

  Future<void> _prune() async =>
      _local?.pruneOps(matchId: matchId, inningsNumber: inningsNumber);

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _changes.close();
  }
}
