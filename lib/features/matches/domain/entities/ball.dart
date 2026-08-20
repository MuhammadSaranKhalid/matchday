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
  List<Object?> get props => [id, seq, isWicket, runsScored, extras];
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
    this.runsScored = 0,
    this.extras = 0,
    this.isWicket = false,
    this.wicketType,
    this.batsmanId,
    this.nonStrikerId,
    this.bowlerId,
    this.fielderId,
    this.commentary,
    this.expectedVersion,
  });

  final MatchId matchId;
  final int inningsNumber;
  final bool isLegalDelivery;
  final BallKind ballKind;
  final int runsScored;
  final int extras;
  final bool isWicket;
  final WicketType? wicketType;

  /// Player ids — under the new schema these are `match_player_id`
  /// values (NOT profile uuids). The scoring screen looks them up from
  /// the match's [MatchPlayer] list before constructing the draft.
  final String? batsmanId;
  final String? nonStrikerId;
  final String? bowlerId;
  final String? fielderId;
  final String? commentary;

  /// Optimistic-lock guard. When set, the [record_ball] RPC will reject
  /// the call (40001) if `match_innings_state.version` has advanced
  /// since the client read it — protecting against two scorers
  /// committing the same delivery. Pass NULL in single-scorer flows.
  final int? expectedVersion;
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
