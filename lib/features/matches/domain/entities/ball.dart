import 'innings.dart';
import 'match.dart';

/// One recorded delivery. Aggregate innings totals are derived server-side by a
/// trigger (see migration 006); this entity is the raw delivery record.
class Ball {
  const Ball({
    required this.id,
    required this.inningsId,
    required this.matchId,
    required this.overNumber,
    required this.ballNumber,
    required this.legalBallNumber,
    required this.bowlerId,
    required this.strikerId,
    required this.nonStrikerId,
    required this.runsScored,
    required this.extraRuns,
    required this.totalRuns,
    this.extraType,
    this.isFour = false,
    this.isSix = false,
    this.isWicket = false,
    this.wicketType,
    this.dismissedPlayerId,
  });

  final BallId id;
  final InningsId inningsId;
  final MatchId matchId;
  final int overNumber;
  final int ballNumber;
  final int legalBallNumber;
  final String bowlerId;
  final String strikerId;
  final String nonStrikerId;
  final int runsScored;
  final int extraRuns;
  final int totalRuns;
  final ExtraType? extraType;
  final bool isFour;
  final bool isSix;
  final bool isWicket;
  final WicketType? wicketType;
  final String? dismissedPlayerId;

  /// True for deliveries that count towards the over (everything except a
  /// wide or no-ball).
  bool get isLegal => extraType == null || extraType == ExtraType.bye || extraType == ExtraType.legBye;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ball &&
          other.id == id &&
          other.overNumber == overNumber &&
          other.ballNumber == ballNumber &&
          other.totalRuns == totalRuns &&
          other.isWicket == isWicket;

  @override
  int get hashCode =>
      Object.hash(id, overNumber, ballNumber, totalRuns, isWicket);
}

class BallId {
  const BallId(this.value);
  final String value;
  @override
  bool operator ==(Object other) => other is BallId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

enum ExtraType {
  wide('wide'),
  noBall('no_ball'),
  bye('bye'),
  legBye('leg_bye'),
  penalty('penalty');

  const ExtraType(this.wire);
  final String wire;
  static ExtraType? fromWire(String? w) =>
      w == null ? null : values.where((e) => e.wire == w).firstOrNull;
}

/// A computed delivery (no id yet) plus the resulting current-players state.
/// Produced by the RecordBall use case; the repository assigns the id, inserts
/// the ball, and updates the innings. Lives in the entity layer so both the
/// use case and the repository contract can reference it without a cycle.
class BallDraft {
  const BallDraft({
    required this.inningsId,
    required this.matchId,
    required this.overNumber,
    required this.ballNumber,
    required this.legalBallNumber,
    required this.bowlerId,
    required this.strikerId,
    required this.nonStrikerId,
    required this.runsScored,
    required this.extraRuns,
    required this.totalRuns,
    required this.extraType,
    required this.isFour,
    required this.isSix,
    required this.isWicket,
    required this.wicketType,
    required this.dismissedPlayerId,
    required this.nextStrikerId,
    required this.nextNonStrikerId,
    required this.nextBowlerId,
    required this.overEnded,
  });

  final InningsId inningsId;
  final MatchId matchId;
  final int overNumber;
  final int ballNumber;
  final int legalBallNumber;
  final String bowlerId;
  final String strikerId;
  final String nonStrikerId;
  final int runsScored;
  final int extraRuns;
  final int totalRuns;
  final ExtraType? extraType;
  final bool isFour;
  final bool isSix;
  final bool isWicket;
  final WicketType? wicketType;
  final String? dismissedPlayerId;
  final String nextStrikerId;
  final String nextNonStrikerId;
  final String nextBowlerId;
  final bool overEnded;
}

enum WicketType {
  bowled('bowled'),
  caught('caught'),
  lbw('lbw'),
  runOut('run_out'),
  stumped('stumped'),
  hitWicket('hit_wicket');

  const WicketType(this.wire);
  final String wire;
  static WicketType? fromWire(String? w) =>
      w == null ? null : values.where((e) => e.wire == w).firstOrNull;
}
