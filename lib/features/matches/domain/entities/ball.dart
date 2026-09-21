import 'package:equatable/equatable.dart';

import 'match.dart';
import 'match_innings_state.dart';

/// One recorded delivery. The deployed `balls` table keys by
/// `(match_id, innings_number, seq)` — there is no separate innings table;
/// the innings is identified by the match_id + innings_number pair.
class Ball extends Equatable {
  const Ball({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.seq,
    required this.overNumber,
    required this.ballInOver,
    required this.isLegalDelivery,
    required this.ballKind,
    required this.runsScored,
    required this.extras,
    required this.isWicket,
    required this.isFreeHit,
    this.wicketType,
    this.dismissedPlayerId,
    this.batsmanId,
    this.nonStrikerId,
    this.bowlerId,
    this.fielderId,
    this.commentary,
  });

  final BallId id;
  final MatchId matchId;
  final int inningsNumber;

  /// Global delivery sequence within this innings (1, 2, 3...). Server-side
  /// trigger `_balls_assign_seq` fills this on insert.
  final int seq;

  final int overNumber;

  /// Position within the over: 1-based for legal deliveries, illegal ones
  /// keep the same `ball_in_over` as the next legal ball but with a wide /
  /// no-ball flag.
  final int ballInOver;

  /// True when this delivery counts towards the over (everything except a
  /// wide or no-ball).
  final bool isLegalDelivery;

  final BallKind ballKind;

  /// Runs off the bat (or off the body for byes/leg-byes — see ballKind).
  final int runsScored;

  /// Penalty / extra runs not credited to the batter (1 for wide/no-ball
  /// plus any overthrows or completed bye runs depending on ballKind).
  final int extras;

  final bool isWicket;
  final bool isFreeHit;
  final WicketType? wicketType;
  final String? dismissedPlayerId;

  /// Striker at the time of the delivery. Nullable because retired-hurt /
  /// timed-out paths can record a wicket without a batter on strike.
  final String? batsmanId;
  final String? nonStrikerId;
  final String? bowlerId;
  final String? fielderId;
  final String? commentary;

  /// Total runs charged to the bowler / added to the team total.
  int get totalRuns => runsScored + extras;

  bool get isFour => ballKind == BallKind.legal && runsScored == 4;
  bool get isSix => ballKind == BallKind.legal && runsScored == 6;

  @override
  List<Object?> get props => [
    id,
    seq,
    isWicket,
    runsScored,
    extras,
    dismissedPlayerId,
  ];
}

class BallId extends Equatable {
  const BallId(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
  @override
  String toString() => value;
}

/// Mirrors the deployed `ball_kind` enum — the kind of delivery, NOT the
/// physical ball type (which is `MatchBallType` on the match format).
enum BallKind {
  /// A normal legal delivery (could be a dot, 1, 2, 3, 4, 6).
  legal('legal'),
  wide('wide'),
  noBall('no_ball'),
  bye('bye'),
  legBye('leg_bye');

  const BallKind(this.wire);
  final String wire;
  static BallKind fromWire(String? w) =>
      values.where((e) => e.wire == w).firstOrNull ?? BallKind.legal;
}

/// Mirrors the deployed `wicket_kind` enum — all 10 dismissal types.
enum WicketType {
  bowled('bowled'),
  caught('caught'),
  lbw('lbw'),
  runOut('run_out'),
  stumped('stumped'),
  hitWicket('hit_wicket'),
  retiredHurt('retired_hurt'),
  obstructing('obstructing'),
  timedOut('timed_out'),
  handledBall('handled_ball');

  const WicketType(this.wire);
  final String wire;
  static WicketType? fromWire(String? w) =>
      w == null ? null : values.where((e) => e.wire == w).firstOrNull;

  String get label {
    switch (this) {
      case bowled:
        return 'Bowled';
      case caught:
        return 'Caught';
      case lbw:
        return 'LBW';
      case runOut:
        return 'Run out';
      case stumped:
        return 'Stumped';
      case hitWicket:
        return 'Hit wicket';
      case retiredHurt:
        return 'Retired hurt';
      case obstructing:
        return 'Obstructing';
      case timedOut:
        return 'Timed out';
      case handledBall:
        return 'Handled ball';
    }
  }
}

/// What the device's scoring engine computed for one delivery.
///
/// The server stores every one of these values **as given** — it does not
/// recompute them (see docs/offline-scoring-design.md D10). That is not
/// laziness: the device has to compute an innings unaided while it has no
/// signal, so it is the only thing that can be authoritative about the
/// arithmetic, and a second implementation on the server could only agree or
/// silently disagree.
///
/// Lives in this file rather than importing the engine's own types because
/// `scoring_types.dart` imports *this* file for [BallKind] — the other
/// direction would be a cycle.
class ComputedDelivery {
  const ComputedDelivery({
    required this.overNumber,
    required this.ballInOver,
    required this.isFreeHit,
    required this.inningsEnded,
    required this.isAllOut,
    required this.ballsPerOver,
    this.strikerAfter,
    this.nonStrikerAfter,
    this.bowlerAfter,
    this.isBowlerCredited = false,
  });

  /// Over this delivery belongs to, and its position within the over —
  /// 1-based for legal deliveries, 0 for wides and no-balls.
  final int overNumber;
  final int ballInOver;

  /// Whether THIS delivery was bowled as a free hit.
  final bool isFreeHit;

  /// The engine says this delivery ended the innings. The server decides what
  /// that means for the match — a device may never render a result (§19.4).
  final bool inningsEnded;

  final bool isAllOut;

  /// Needed only to place the fall-of-wicket in overs notation.
  final int ballsPerOver;

  /// The on-field trio AFTER this delivery: strike rotation applied, the
  /// dismissed batter cleared, and the bowler cleared if the over ended.
  /// Null means the slot is vacant and someone must be chosen.
  final String? strikerAfter;
  final String? nonStrikerAfter;
  final String? bowlerAfter;

  /// Whether the wicket (if any) is credited to the bowler.
  final bool isBowlerCredited;
}

/// Input payload for the `record_ball` RPC. Built by [RecordBall] use case
/// from a tap on the scoring keypad + any sheet selections (wicket type,
/// fielder, etc.). Lives in the entity layer so the use case + repo can
/// both reference it without an import cycle.
class BallDraft {
  const BallDraft({
    required this.matchId,
    required this.inningsNumber,
    required this.isLegalDelivery,
    required this.ballKind,
    this.opId,
    this.runsScored = 0,
    this.extras = 0,
    this.isWicket = false,
    this.wicketType,
    this.dismissedPlayerId,
    this.batsmanId,
    this.nonStrikerId,
    this.bowlerId,
    this.fielderId,
    this.commentary,
    this.computed,
  });

  final String? opId;
  final MatchId matchId;
  final int inningsNumber;
  final bool isLegalDelivery;
  final BallKind ballKind;
  final int runsScored;
  final int extras;
  final bool isWicket;
  final WicketType? wicketType;
  final String? dismissedPlayerId;

  /// Player ids — under the new schema these are `match_player_id`
  /// values (NOT profile uuids). The scoring screen looks them up from
  /// the match's [MatchPlayer] list before constructing the draft.
  final String? batsmanId;
  final String? nonStrikerId;
  final String? bowlerId;
  final String? fielderId;
  final String? commentary;

  /// What the local engine made of this delivery. Set by the controller after
  /// `applyBall` and sent with the write; the server stores it verbatim.
  ///
  /// Replaces the old `expectedVersion` optimistic lock, which is gone: the
  /// batting side owns its innings outright (D12), so there is no second writer
  /// to race. Gating on it caused a real bug — a scorer tapping a second ball
  /// before the first reply landed sent a stale version and lost the delivery.
  final ComputedDelivery? computed;

  BallDraft copyWith({
    String? opId,
    MatchId? matchId,
    int? inningsNumber,
    bool? isLegalDelivery,
    BallKind? ballKind,
    int? runsScored,
    int? extras,
    bool? isWicket,
    WicketType? wicketType,
    String? dismissedPlayerId,
    String? batsmanId,
    String? nonStrikerId,
    String? bowlerId,
    String? fielderId,
    String? commentary,
    ComputedDelivery? computed,
  }) => BallDraft(
    opId: opId ?? this.opId,
    matchId: matchId ?? this.matchId,
    inningsNumber: inningsNumber ?? this.inningsNumber,
    isLegalDelivery: isLegalDelivery ?? this.isLegalDelivery,
    ballKind: ballKind ?? this.ballKind,
    runsScored: runsScored ?? this.runsScored,
    extras: extras ?? this.extras,
    isWicket: isWicket ?? this.isWicket,
    wicketType: wicketType ?? this.wicketType,
    dismissedPlayerId: dismissedPlayerId ?? this.dismissedPlayerId,
    batsmanId: batsmanId ?? this.batsmanId,
    nonStrikerId: nonStrikerId ?? this.nonStrikerId,
    bowlerId: bowlerId ?? this.bowlerId,
    fielderId: fielderId ?? this.fielderId,
    commentary: commentary ?? this.commentary,
    computed: computed ?? this.computed,
  );
}

/// Which of undo's two paths was taken.
enum UndoKind {
  /// The delivery had never reached the server — the queued write was thrown
  /// away and the server was not contacted.
  discardedPending,

  /// The stored delivery was removed on the server.
  removedStored,

  /// There was nothing to undo.
  nothing,
}

/// What an undo actually did.
///
/// The caller MUST distinguish these. Discarding a queued write leaves the
/// server untouched — it never saw that delivery — so re-reading the ball list
/// from the server afterwards would erase every OTHER unsent delivery still
/// waiting in the queue. Undo used to re-read unconditionally.
class UndoOutcome extends Equatable {
  const UndoOutcome.discardedPending(String this.opId)
    : kind = UndoKind.discardedPending;
  const UndoOutcome.removedStored()
    : kind = UndoKind.removedStored,
      opId = null;
  const UndoOutcome.nothing() : kind = UndoKind.nothing, opId = null;

  final UndoKind kind;

  /// The discarded op, so the caller can drop exactly that painted delivery.
  final String? opId;

  @override
  List<Object?> get props => [kind, opId];
}

/// What the server produced from one recorded delivery: the persisted ball,
/// and the innings row as it stands after it.
///
/// The innings row is returned so the scoring screen can show the new score
/// the moment the write replies. Before this existed the client got only the
/// ball, threw it away, and waited for the realtime broadcast to make a second
/// trip back from the server before the scoreboard moved — which is what made
/// a tap feel slow even when the write itself was quick.
///
/// [innings] is nullable because an older deployment of the record-ball
/// function does not return it. Callers fall back to the broadcast in that
/// case, so a client running ahead of the server still works — just no faster
/// than before.
class BallOutcome extends Equatable {
  const BallOutcome({required this.ball, this.innings});

  final Ball ball;
  final MatchInningsState? innings;

  @override
  List<Object?> get props => [ball, innings];
}
