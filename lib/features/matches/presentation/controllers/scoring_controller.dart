import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_provider.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/lifecycle/app_lifecycle_provider.dart';
import '../../data/scoring/scoring_session.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/scoring_projection.dart';
import '../../domain/scoring/scoring_rules.dart';
import '../providers/matches_providers.dart';
import '../state/scoring_state.dart';

part 'scoring_controller.g.dart';

/// What the scoring screen sees, and every write it can make.
///
/// Deliberately thin. Everything about HOW a delivery reaches the server — the
/// queue, the write-ahead log, retries, what is provisional and what is
/// confirmed — belongs to [ScoringSession] in the data layer. This class turns
/// taps into drafts, applies the guards whose failure the scorer needs to read
/// as a sentence, and republishes the session's projection as screen state.
@riverpod
class ScoringController extends _$ScoringController {
  bool _isBusy = false;

  ScoringSession get _session =>
      ref.read(scoringSessionProvider(matchId, inningsNumber));

  @override
  Future<ScoringState> build(String matchId, int inningsNumber) async {
    final session = ref.watch(scoringSessionProvider(matchId, inningsNumber));

    // Held until the first projection has been returned from build. A stream
    // event arriving before then would be an attempt to set state during
    // build; the value it carries is the one build is about to return anyway.
    var live = false;

    final subscription = session.changes.listen((projection) {
      if (live && ref.mounted) state = AsyncData(_toState(projection));
    });
    ref.onDispose(subscription.cancel);

    ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
      if (next.value == true && previous?.value != true) {
        unawaited(session.drain());
      }
    });

    ref.listen<int>(appResumeCountProvider, (previous, next) {
      if (next > (previous ?? 0)) unawaited(session.drain());
    });

    var projection = session.current;
    if (projection == null) {
      final loaded = await session.load();
      projection = loaded.fold<ScoringProjection>(
        (failure) => throw FailureWrapper(failure),
        (value) => value,
      );
    }

    live = true;
    return _toState(projection);
  }

  ScoringState _toState(ScoringProjection p) => ScoringState(
    match: p.match,
    inningsNumber: inningsNumber,
    innings: p.innings,
    balls: p.balls,
    matchPlayers: p.matchPlayers,
    canScore: p.canScore,
    pendingCount: p.pendingCount,
    isBusy: _isBusy,
  );

  // ── Deliveries ───────────────────────────────────────────────────────────

  /// A normal delivery off the bat (0/1/2/3/4/6).
  Future<Either<Failure, Unit>> recordRun(int runs) => _record(
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
    (s) => BallDraft(
      matchId: s.match.id,
      inningsNumber: inningsNumber,
      isLegalDelivery: true,
      ballKind: BallKind.legal,
      runsScored: runsBefore,
      isWicket: true,
      wicketType: type,
      dismissedPlayerId: dismissedMatchPlayerId ?? s.innings?.strikerId?.value,
      batsmanId: s.innings?.strikerId?.value,
      nonStrikerId: s.innings?.nonStrikerId?.value,
      bowlerId: s.innings?.bowlerId?.value,
      fielderId: fielderMatchPlayerId,
    ),
  );

  /// Undo the last delivery — one step back, never further.
  Future<Either<Failure, Unit>> undoLastBall() => _busy(_session.undo);

  // ── On-field changes ─────────────────────────────────────────────────────

  Future<Either<Failure, Unit>> setBowler(String bowlerMatchPlayerId) {
    final s = state.value;
    if (s == null) return _notReady();

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
      return _refuse('Both openers must be set before choosing a bowler.');
    }
    if (s.lastOverBowlerId != null &&
        bowlerMatchPlayerId == s.lastOverBowlerId &&
        s.legalBalls % s.ballsPerOver == 0) {
      return _refuse('A bowler cannot bowl two consecutive overs.');
    }

    return _setTrio(
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
    if (s == null) return _notReady();

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
      return _refuse('Set the bowler and both batters before resuming.');
    }

    return _setTrio(striker: striker, nonStriker: nonStriker, bowler: bowler);
  }

  /// Send everything the queue still owes the server.
  Future<void> drainOutbox() => _session.drain();

  // ── Plumbing ─────────────────────────────────────────────────────────────

  Future<Either<Failure, Unit>> _setTrio({
    required String striker,
    required String nonStriker,
    required String bowler,
  }) => _busy(
    () => _session.setTrio(
      strikerId: striker,
      nonStrikerId: nonStriker,
      bowlerId: bowler,
    ),
  );

  /// The guards that exist to produce a sentence the scorer can act on.
  ///
  /// A wicket clears whichever end the dismissed batter was at. Recording a
  /// delivery before it is refilled credits it to nobody: a real innings
  /// reached 182/5 through four consecutive wickets and then logged a single
  /// with the non-striker's end empty. The pad gates on this too; this is the
  /// backstop for every other route into a write.
  Future<Either<Failure, Unit>> _record(
    BallDraft Function(ScoringState) draft,
  ) {
    final s = state.value;
    if (s == null) return _notReady();
    if (!s.bowlerSet) {
      return _refuse('Choose a bowler before recording a delivery.');
    }
    if (!s.battersSet) {
      return _refuse('Choose the next batter before recording a delivery.');
    }
    return _session.record(draft(s));
  }

  Future<Either<Failure, Unit>> _notReady() =>
      Future.value(const Left(ValidationFailure('Not ready')));

  Future<Either<Failure, Unit>> _refuse(String message) =>
      Future.value(Left(ValidationFailure(message)));

  Future<Either<Failure, Unit>> _busy(
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    _setBusy(true);
    final result = await action();
    _setBusy(false);
    return result;
  }

  void _setBusy(bool value) {
    _isBusy = value;
    final s = state.value;
    if (ref.mounted && s != null) state = AsyncData(s.copyWith(isBusy: value));
  }
}
