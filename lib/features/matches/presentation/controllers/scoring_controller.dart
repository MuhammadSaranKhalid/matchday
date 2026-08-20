import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/log/ck_log.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/scoring/scoring_adapter.dart';
import '../../domain/scoring/scoring_categories.dart';
import '../../domain/scoring/scoring_engine.dart';
import '../../domain/scoring/scoring_parity.dart';
import '../../domain/scoring/scoring_types.dart';
import '../providers/matches_providers.dart';
import '../state/scoring_state.dart';

part 'scoring_controller.g.dart';

/// Owns live scoring: what the screen sees, and every write it can make.
///
/// Extracted from `ScoringScreen`, which had grown to hold the on-field state,
/// the cricket rules, and the RPC dispatch inside one 3,400-line widget. None
/// of that was reachable from a unit test — which is how a wide-attribution
/// bug that corrupted scorecards survived in it.
@riverpod
class ScoringController extends _$ScoringController {
  // ── Write-reply overlay ───────────────────────────────────────────────────
  //
  // `record-ball` answers with the ball it wrote AND the innings row that
  // resulted. Both used to be discarded, so the scoreboard only moved when the
  // realtime broadcast made a second trip back from the server — the tap felt
  // slow even when the write was quick.
  //
  // These hold the server's answer until the streams catch up with it. They
  // are NOT a prediction: every value here was computed by the same engine
  // that owns the scorecard. The merge below prefers whichever source is
  // further ahead, so the overlay can never roll the screen backwards, and
  // clears itself the moment the stream carries the same data.
  Ball? _appliedBall;
  MatchInningsState? _appliedInnings;

  /// Provisional balls on screen that the server has not confirmed yet. Drives
  /// the "unconfirmed" indicator; empty is the normal steady state.
  final Set<BallId> _pending = <BallId>{};

  /// Serialises the network writes behind the instant local paint.
  Future<void> _writes = Future<void>.value();

  /// How many deliveries are shown but not yet confirmed by the server.
  int get pendingCount => _pending.length;

  /// Drop the overlay. Used by undo, which removes the very ball the overlay
  /// may still be holding — re-merging it would resurrect a deleted delivery.
  void _clearApplied() {
    _appliedBall = null;
    _appliedInnings = null;
  }

  /// Rebuild the live half of the state straight from the streams, discarding
  /// anything the overlay had painted.
  ///
  /// Undo needs this because the overlay writes into `state` directly: clearing
  /// the fields alone leaves the already-painted score on screen. [removed] is
  /// dropped as well — the deletion broadcast has usually not arrived yet, so
  /// the balls stream can still be carrying the delivery that was just undone.
  void _syncFromStreams({BallId? removed}) {
    final streamInnings =
        ref.read(liveInningsStateProvider(matchId, inningsNumber)).value;
    final streamBalls =
        ref.read(liveBallsProvider(matchId, inningsNumber)).value ??
            const <Ball>[];
    final balls = removed == null
        ? streamBalls
        : streamBalls.where((b) => b.id != removed).toList();

    final current = state.value;
    if (current == null) return;
    state = AsyncData(ScoringState(
      match: current.match,
      inningsNumber: current.inningsNumber,
      innings: streamInnings,
      balls: balls,
      matchPlayers: current.matchPlayers,
      canScore: current.canScore,
      isBusy: current.isBusy,
    ));
  }

  @override
  Future<ScoringState> build(String matchId, int inningsNumber) async {
    final match = ref.watch(liveMatchProvider(matchId)).value;
    if (match == null) {
      throw const FailureWrapper(NotFoundFailure('Match not found'));
    }

    final streamInnings =
        ref.watch(liveInningsStateProvider(matchId, inningsNumber)).value;
    final streamBalls =
        ref.watch(liveBallsProvider(matchId, inningsNumber)).value ??
            const <Ball>[];

    // Innings: version is monotonic per write, so "further ahead" is a
    // straight comparison. Once the broadcast reaches the version we already
    // applied, the overlay has nothing left to add.
    var innings = streamInnings;
    final applied = _appliedInnings;
    if (applied != null) {
      if (streamInnings == null || applied.version > streamInnings.version) {
        innings = applied;
      } else {
        _appliedInnings = null;
      }
    }

    // Balls: union by id. The stream appends the same row the reply gave us,
    // so presence there is the signal the overlay is spent.
    var balls = streamBalls;
    final appliedBall = _appliedBall;
    if (appliedBall != null) {
      if (streamBalls.any((b) => b.id == appliedBall.id)) {
        _appliedBall = null;
      } else {
        balls = [...streamBalls, appliedBall]
          ..sort((a, b) => a.seq.compareTo(b.seq));
      }
    }
    final matchPlayers =
        ref.watch(matchPlayersProvider(matchId)).value ?? const <MatchPlayer>[];

    // Answered by the server, never derived here — the UI gate and the write
    // check have to be the same rule or the app locks out people it shouldn't.
    final canScore =
        ref.watch(canScoreInningsProvider(matchId, inningsNumber)).value ??
            false;

    final previous = state.value;

    final next = ScoringState(
      match: match,
      inningsNumber: inningsNumber,
      innings: innings,
      balls: balls,
      matchPlayers: matchPlayers,
      canScore: canScore,
      isBusy: previous?.isBusy ?? false,
    );

    CkLog.write(CkLogChannel.matchStart, 'scoring·derive', data: {
      'match': matchId,
      'inns': inningsNumber,
      'score': '${next.totalRuns}/${next.totalWickets}',
      'overs': next.overText,
      'bowler': next.bowlerSet,
      'freeHit': next.freeHitActive,
      'over': next.inningsOver,
      'canScore': canScore,
    });

    return next;
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

  /// A wide, no-ball, bye or leg-bye. [runs] is whatever the sheet collected:
  /// runs run for a wide, runs off the bat for a no-ball, runs taken for a
  /// bye or leg-bye. [splitExtraRuns] decides where they land.
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
          batsmanId: s.innings?.strikerId?.value,
          nonStrikerId: s.innings?.nonStrikerId?.value,
          bowlerId: s.innings?.bowlerId?.value,
          fielderId: fielderMatchPlayerId,
          expectedVersion: s.innings?.version,
        ),
      );

  Future<Either<Failure, Unit>> undoLastBall() {
    final current = state.value;
    if (current == null || current.balls.isEmpty) {
      return Future.value(const Left(ValidationFailure('Nothing to undo')));
    }
    return _busy(
      'undo',
      // undoLastBall reports whether a ball was actually removed; the screen
      // only needs success/failure.
      () async =>
          (await ref.read(matchesRepositoryProvider).undoLastBall(
                matchId: current.match.id,
                inningsNumber: inningsNumber,
              ))
              .map((_) {
        // The overlay may still be holding the very delivery that was just
        // deleted — and the score it produced. Re-merging either would
        // resurrect it, so drop the overlay and fall back to the streams.
        _clearApplied();
        _syncFromStreams(removed: current.balls.last.id);
        return unit;
      }),
    );
  }

  // ── On-field changes ─────────────────────────────────────────────────────

  /// Set (or replace) the bowler. Used for the opening bowler and at the top
  /// of every over.
  Future<Either<Failure, Unit>> setBowler(String bowlerMatchPlayerId) {
    final s = state.value;
    if (s == null) {
      return Future.value(const Left(ValidationFailure('Not ready')));
    }
    final striker = s.innings?.strikerId?.value ?? '';
    final nonStriker = s.innings?.nonStrikerId?.value ?? '';
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

  /// Bring the next batter in on strike after a wicket. The non-striker and
  /// bowler are unchanged, so they are reused from the freshest state that
  /// has them — never forwarding an empty id, which `start_innings` rejects
  /// with a confusing "all three are required".
  Future<Either<Failure, Unit>> bringInBatter(String batterMatchPlayerId) {
    final s = state.value;
    if (s == null) {
      return Future.value(const Left(ValidationFailure('Not ready')));
    }
    final nonStriker = s.innings?.nonStrikerId?.value ?? '';
    final bowler = s.innings?.bowlerId?.value ?? '';
    if (nonStriker.isEmpty || bowler.isEmpty) {
      return Future.value(const Left(ValidationFailure(
        'Set the bowler for this over before bringing in the next batter.',
      )));
    }
    return _setTrio(
      label: 'bringInBatter',
      striker: batterMatchPlayerId,
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
    final s = state.value!;
    return _busy(
      label,
      () => ref.read(matchesRepositoryProvider).startInnings(
            matchId: s.match.id,
            inningsNumber: inningsNumber,
            strikerId: striker,
            nonStrikerId: nonStriker,
            bowlerId: bowler,
          ),
    );
  }

  // ── Plumbing ─────────────────────────────────────────────────────────────

  /// Record a delivery.
  ///
  /// The tap no longer waits for the network. The local engine computes the
  /// delivery, the screen shows it immediately, and the write goes out behind
  /// it. That is the whole point of Stage 1: a scorer taps once a ball and a
  /// 400–800ms freeze per tap reads as a broken app.
  ///
  /// The local engine is the SAME rules as the server's, held to the same
  /// golden vectors — so this is not a guess about what the score will be, it
  /// is the same computation run a round trip earlier. The server still owns
  /// the scorecard, and [_settle] reconciles when its answer lands.
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

    final draft = build(s);
    final input = engineInputFrom(draft);
    final format = engineFormatFrom(s.match.format);

    // Predict. A rejection here is the same rejection the server would return,
    // so surfacing it now saves a round trip AND tells the scorer immediately
    // rather than after a pause — an illegal entry is worth refusing fast.
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

    // Paint it. `seq` is provisional — the database assigns the real one — but
    // it only has to order this ball after the ones already shown.
    final provisional = _provisionalBall(s, predicted.ball!);
    _pending.add(provisional.id);
    _update((st) => st.copyWith(
          innings: _projectInnings(st.innings, predicted.newState!),
          balls: [...st.balls, provisional],
          pendingCount: _pending.length,
        ));

    CkLog.write(CkLogChannel.matchStart, 'scoring·$label·local', data: {
      'match': matchId,
      'inns': inningsNumber,
      'pending': _pending.length,
    });

    // Write behind the paint, strictly in order. Two deliveries entered inside
    // one round trip would otherwise race, and the second would lose the
    // optimistic-version check against a row the first had not committed yet.
    return _enqueue(() async {
      final result = await ref.read(matchesRepositoryProvider).recordBall(draft);
      return result.fold(
        (f) {
          _rollback(provisional.id);
          CkLog.warn(CkLogChannel.matchStart, 'scoring·$label·fail', data: {
            'failure': f.runtimeType,
            'msg': f.message,
          });
          return Left(f);
        },
        (outcome) {
          _settle(
            provisional: provisional,
            predicted: predicted,
            input: input,
            format: format,
            outcome: outcome,
          );
          return const Right(unit);
        },
      );
    });
  }

  /// The predicted ball, as a [Ball] the screen can render now.
  ///
  /// Carries a provisional id so it can be found again to reconcile or remove.
  /// The `seq` is one past whatever is on screen: enough to sort correctly,
  /// and replaced by the server's when the write lands.
  Ball _provisionalBall(ScoringState s, ComputedBall c) => Ball(
        id: BallId('local:${DateTime.now().microsecondsSinceEpoch}'),
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
        batsmanId: c.batsmanId,
        nonStrikerId: c.nonStrikerId,
        bowlerId: c.bowlerId,
        fielderId: c.fielderId,
        commentary: c.commentary,
      );

  /// The innings row as the engine says it now stands.
  ///
  /// Version is bumped so the projection wins the merge in [build] against the
  /// row the streams are still carrying — the same monotonic rule the server's
  /// answer uses.
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

  /// The server has answered. Swap the provisional ball for the real one and
  /// check whether the two engines agreed.
  void _settle({
    required Ball provisional,
    required BallResult predicted,
    required EngineBallInput input,
    required EngineFormat format,
    required BallOutcome outcome,
  }) {
    _pending.remove(provisional.id);

    final report = compareParity(
      predictedBall: predicted.ball!,
      predictedState: predicted.newState!,
      actualBall: outcome.ball,
      actualInnings: outcome.innings,
    );

    final categories = scoringCategories(
      input: input,
      format: format,
      result: predicted,
    );

    if (report.agrees) {
      // Coverage. Which rules a real delivery exercised is what makes the soak
      // measurable rather than estimated — see the design doc, §19.2.
      CkLog.write(CkLogChannel.parity, 'ok', data: {
        'match': matchId,
        'inns': inningsNumber,
        'cats': categories.join(','),
      });
    } else {
      // The one line on this channel that must never be ignored: the two
      // engines computed different cricket. Server wins; the divergence is
      // recorded with both sides so it is diagnosable from the log alone.
      CkLog.warn(CkLogChannel.parity, 'MISMATCH', data: {
        'match': matchId,
        'inns': inningsNumber,
        'cats': categories.join(','),
        'diff': report.summary,
      });
    }

    // The server's answer replaces the prediction either way — it is the
    // authority, and on disagreement it is also the correction.
    _appliedBall = outcome.ball;
    _appliedInnings = outcome.innings;
    _update((st) => st.copyWith(
          innings: outcome.innings,
          pendingCount: _pending.length,
          balls: [
            for (final b in st.balls)
              if (b.id != provisional.id) b,
            if (!st.balls.any((b) => b.id == outcome.ball.id)) outcome.ball,
          ]..sort((a, b) => a.seq.compareTo(b.seq)),
        ));
  }

  /// The write failed. Take the delivery back off the screen.
  ///
  /// Stage 1 has no local durability, so a failed write genuinely loses the
  /// delivery — the same as before this change. What must not happen is the
  /// screen keeping a ball the scorecard never received.
  void _rollback(BallId id) {
    _pending.remove(id);
    _update((st) => st.copyWith(
          pendingCount: _pending.length,
          balls: [
            for (final b in st.balls)
              if (b.id != id) b,
          ],
        ));
    _syncFromStreams();
  }

  /// Run [action] after every write already queued.
  ///
  /// Deliveries are sequential and the server holds an optimistic version
  /// lock, so they must reach it in the order they were entered. This is an
  /// in-memory chain, not the durable outbox — that is Stage 2.
  Future<Either<Failure, Unit>> _enqueue(
    Future<Either<Failure, Unit>> Function() action,
  ) {
    final next = _writes.then((_) => action());
    _writes = next.then((_) {}, onError: (_) {});
    return next;
  }

  void _update(ScoringState Function(ScoringState) edit) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(edit(current));
  }

  /// Raise the busy flag, run the write, lower it. Re-reads state after the
  /// await because a broadcast may have landed mid-flight.
  Future<Either<Failure, Unit>> _busy(
    String label,
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    _update((s) => s.copyWith(isBusy: true));
    CkLog.write(CkLogChannel.matchStart, 'scoring·$label', data: {
      'match': matchId,
      'inns': inningsNumber,
    });

    final result = await action();

    result.fold(
      (f) => CkLog.warn(CkLogChannel.matchStart, 'scoring·$label·fail',
          data: {'failure': f.runtimeType, 'msg': f.message}),
      (_) => CkLog.write(CkLogChannel.matchStart, 'scoring·$label·ok'),
    );

    _update((s) => s.copyWith(isBusy: false));
    return result;
  }
}
