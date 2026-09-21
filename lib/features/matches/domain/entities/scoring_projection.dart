import 'package:equatable/equatable.dart';

import 'ball.dart';
import 'match.dart';
import 'match_innings_state.dart';
import 'match_player.dart';

/// A scoring write this device has made that the server has not accepted yet.
///
/// The queue of these IS the difference between what the scorer can see and
/// what the server holds. Replaying them over the confirmed state is what
/// produces a [ScoringProjection] — see `domain/scoring/scoring_replay.dart`.
sealed class PendingScoringOp {
  const PendingScoringOp(this.opId);

  /// Client-generated idempotency key. Decided once, before the write-ahead
  /// log entry, so a replay after a dropped connection presents the same key
  /// and the server can reject the duplicate.
  final String opId;
}

/// A delivery, queued.
class PendingBall extends PendingScoringOp {
  const PendingBall({required String opId, required this.draft}) : super(opId);

  /// The delivery exactly as the scorer entered it — with NO engine answer
  /// attached. The answer is derived during replay instead of frozen at tap
  /// time, so what the screen shows and what the wire carries cannot diverge.
  final BallDraft draft;
}

/// A change to the on-field trio, queued.
class PendingTrio extends PendingScoringOp {
  const PendingTrio({
    required String opId,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
    this.target,
  }) : super(opId);

  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;
  final int? target;
}

/// The innings as it currently stands: the server's confirmed state with every
/// queued write replayed on top of it.
///
/// This is the ONLY thing the scoring screen renders. It is never patched in
/// place — every change to either ingredient throws it away and recomputes it,
/// which is what makes "the score on screen" and "the score in the log" the
/// same statement rather than two that have to be kept in agreement.
class ScoringProjection extends Equatable {
  const ScoringProjection({
    required this.match,
    required this.innings,
    required this.balls,
    required this.matchPlayers,
    required this.canScore,
    required this.pendingCount,
    this.computedByOpId = const {},
    this.rejectedOpIds = const [],
  });

  final Match match;
  final MatchInningsState? innings;

  /// Confirmed deliveries followed by the queued ones, in order.
  final List<Ball> balls;

  final List<MatchPlayer> matchPlayers;

  /// Whether this device is the authorised scorer for this innings.
  final bool canScore;

  /// Deliveries and trio changes still owed to the server. A count of rows in
  /// the log, never a running total — it cannot drift, and cannot go negative.
  final int pendingCount;

  /// The engine's answer for each queued delivery, keyed by op id. Handed to
  /// the wire at send time; the server stores it and computes nothing itself.
  final Map<String, ComputedDelivery> computedByOpId;

  /// Queued ops the engine refused during replay. Should be empty — an op that
  /// was legal when tapped stays legal — but a confirmed base arriving out of
  /// order can strand one, and it must be dropped rather than crash the fold.
  final List<String> rejectedOpIds;

  ScoringProjection copyWith({bool? canScore}) => ScoringProjection(
    match: match,
    innings: innings,
    balls: balls,
    matchPlayers: matchPlayers,
    canScore: canScore ?? this.canScore,
    pendingCount: pendingCount,
    computedByOpId: computedByOpId,
    rejectedOpIds: rejectedOpIds,
  );

  @override
  List<Object?> get props => [
    match,
    innings,
    balls,
    matchPlayers,
    canScore,
    pendingCount,
    rejectedOpIds,
  ];
}
