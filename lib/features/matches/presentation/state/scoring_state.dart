import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/scoring/scoring_adapter.dart';
import '../../domain/scoring/scoring_engine.dart';
import '../../domain/scoring/scoring_rules.dart';
import 'match_start_state.dart';

/// One selectable person in a scoring sheet — a fielder, an incoming batter,
/// the next bowler. Keyed by `match_player_id`, which is what every scoring
/// write speaks.
class ScoringPerson extends Equatable {
  const ScoringPerson({
    required this.matchPlayerId,
    required this.name,
    this.photoUrl,
  });

  final String matchPlayerId;
  final String name;

  /// Avatar URL, or null when the player has none — unclaimed placeholders
  /// never have one. The picker falls back to the monogram.
  final String? photoUrl;

  @override
  List<Object?> get props => [matchPlayerId, name, photoUrl];
}

/// Everything the scoring screen renders, derived once per emission.
///
/// This exists because the cricket rules below — is the innings over, is the
/// next ball a free hit, how do runs split between batter and extras — used to
/// live inside `ScoringScreen`'s widget methods, where no unit test could
/// reach them. A scorecard-corrupting wide-attribution bug survived there
/// precisely because of that. Rules live here or in the controller now; the
/// screen only lays them out.
class ScoringState extends Equatable {
  const ScoringState({
    required this.match,
    required this.inningsNumber,
    required this.innings,
    required this.balls,
    required this.matchPlayers,
    required this.canScore,
    this.isBusy = false,
    this.pendingCount = 0,
  });

  final Match match;
  final int inningsNumber;

  /// Live innings row. Null until the first broadcast/snapshot lands.
  final MatchInningsState? innings;

  /// Deliveries this innings, oldest first.
  final List<Ball> balls;

  /// The full XI for both sides — the id-translation boundary, and since the
  /// `match_players` read resolves its own joins, the name/avatar source too.
  ///
  /// Names used to be a separate `player_ref_id → name` map built from the two
  /// team rosters. That silently mislabelled anyone in the XI but off the
  /// roster — guests, substitutes, players since removed — as "Player 3f2a".
  final List<MatchPlayer> matchPlayers;

  /// Whether this device may record deliveries, as answered by the server.
  final bool canScore;

  /// A write is in flight.
  ///
  /// This NO LONGER disables the run pad. Deliveries are computed locally and
  /// painted immediately, so the scorer keeps scoring while the previous write
  /// is still travelling; the writes themselves are serialised behind the
  /// paint. It still drives the saving indicator, and still gates undo — undoing
  /// a delivery that has not been written yet has nothing to undo.
  final bool isBusy;

  /// Deliveries shown but not yet confirmed by the server. 0 is the steady
  /// state; a number that stays above 0 means writes are not landing.
  final int pendingCount;

  bool get hasPending => pendingCount > 0;

  // ── On-field trio ────────────────────────────────────────────────────────

  String? get strikerRefId => matchPlayers.playerRefIdOf(innings?.strikerId?.value);
  String? get nonStrikerRefId =>
      matchPlayers.playerRefIdOf(innings?.nonStrikerId?.value);
  String? get bowlerRefId => matchPlayers.playerRefIdOf(innings?.bowlerId?.value);

  String nameOf(String? refId) =>
      refId == null ? '—' : (matchPlayers.byRefId(refId)?.displayName ?? '—');

  /// Avatar for a player ref id, or null when they have none.
  String? photoOf(String? refId) => matchPlayers.byRefId(refId)?.photoUrl;

  String get strikerName => nameOf(strikerRefId);
  String get nonStrikerName => nameOf(nonStrikerRefId);
  String get bowlerName => nameOf(bowlerRefId);

  String? get strikerPhoto => photoOf(strikerRefId);
  String? get nonStrikerPhoto => photoOf(nonStrikerRefId);
  String? get bowlerPhoto => photoOf(bowlerRefId);

  /// A delivery cannot be recorded without a bowler. The server clears
  /// `bowler_id` at the innings start and after every completed over, so this
  /// is false exactly when a (new) bowler is owed.
  bool get bowlerSet => (innings?.bowlerId?.value ?? '').isNotEmpty;

  /// True when the opening bowler has never been chosen for this innings.
  bool get needsOpeningBowler => !bowlerSet && balls.isEmpty;

  /// Both ends are occupied.
  ///
  /// A wicket clears whichever end the dismissed batter was at, and the slot
  /// stays empty until a replacement is chosen. Nothing used to notice: the run
  /// pad stayed live, and deliveries were recorded against an empty end — a
  /// real innings reached 182/5 with four consecutive wickets and then a single
  /// scored by nobody.
  bool get battersSet =>
      (innings?.strikerId?.value ?? '').isNotEmpty &&
      (innings?.nonStrikerId?.value ?? '').isNotEmpty;

  /// A replacement batter is owed before the next delivery.
  bool get needsBatter => !battersSet && !inningsOver;

  /// Whether anyone is left to send in. False means the side has run out of
  /// batters, which is a finished innings rather than a pending choice.
  bool get hasBatterAvailable => availableBatters.isNotEmpty;

  // ── Score ────────────────────────────────────────────────────────────────

  int get legalBalls {
    final ballsCount = balls.where((b) => b.isLegalDelivery).length;
    final serverCount = innings?.legalBallCount ?? 0;
    return math.max(serverCount, ballsCount);
  }

  int get totalRuns {
    final ballsRuns = balls.fold<int>(0, (sum, b) => sum + b.totalRuns);
    final serverRuns = innings?.totalRuns ?? 0;
    return math.max(serverRuns, ballsRuns);
  }

  int get totalWickets {
    final ballsWickets = balls.where((b) => b.isWicket).length;
    final serverWickets = innings?.totalWickets ?? 0;
    return math.max(serverWickets, ballsWickets);
  }

  int get ballsPerOver =>
      match.format.ballsPerOver == 0 ? 6 : match.format.ballsPerOver;

  int get formatOvers =>
      match.format.oversPerInnings == 0 ? 20 : match.format.oversPerInnings;

  String get overText => '${legalBalls ~/ ballsPerOver}.${legalBalls % ballsPerOver}';

  int get ballsRemaining => (formatOvers * ballsPerOver) - legalBalls;

  double get currentRunRate =>
      legalBalls > 0 ? totalRuns / (legalBalls / ballsPerOver) : 0;

  Ball? get lastBall => balls.isEmpty ? null : balls.last;

  // ── Cricket rules ────────────────────────────────────────────────────────

  /// The next delivery is a free hit when the most recent non-wide delivery
  /// was a no-ball — intervening wides do not consume it.
  ///
  /// Delegates to the same derivation the engine is given, rather than walking
  /// the ball log again here. It is asked at a different moment — "is the NEXT
  /// delivery a free hit", where the ball row answers "was THAT one" — but it
  /// is the same question of the same data, so it is the same code.
  bool get freeHitActive =>
      prevNonWideKind(balls) == BallKind.noBall;

  /// The innings has ended.
  ///
  /// Answered by the engine's own rule, evaluated against the state as it
  /// currently stands. Derived here rather than read from the match status so
  /// the screen still ends the innings when the separate match-status
  /// broadcast is delayed or dropped.
  ///
  /// This used to be a second, hand-written copy of the rule, and it had drifted
  /// in two ways: it guarded all-out on `playersPerTeam > 0` rather than
  /// `wicketsToAllOut > 0` (so a format with all-out disabled read as over from
  /// the first ball), and it omitted the target and declaration cases entirely
  /// (so a chase reaching its target — the most common way an innings ends —
  /// never registered on the client at all).
  bool get inningsOver {
    if (innings == null) return false;
    return evaluateTermination(
      format: engineFormatFrom(match.format),
      legalBallCount: legalBalls,
      totalRuns: totalRuns,
      totalWickets: totalWickets,
      target: innings?.target,
      isDeclared: innings?.isDeclared ?? false,
    ).ended;
  }

  /// True when the delivery just recorded completed an over, so a new bowler
  /// is owed before the next one.
  bool get overJustCompleted {
    if (balls.isEmpty) return false;
    final lastOver = balls.last.overNumber;
    final legalInOver = balls
        .where((b) => b.overNumber == lastOver && b.isLegalDelivery)
        .length;
    return legalInOver >= ballsPerOver;
  }

  /// Deliveries bowled in the over currently in progress, oldest first.
  ///
  /// The screen used to slice this itself and map it straight to chip models;
  /// exposing the balls instead keeps the presentation mapping in the widget
  /// and the slicing rule here, where it is testable.
  List<Ball> get currentOverBalls {
    if (balls.isEmpty) return const [];
    final over = legalBalls ~/ ballsPerOver;
    return [
      for (final b in balls)
        if (b.overNumber == over) b,
    ];
  }

  // ── Sides and squads ─────────────────────────────────────────────────────

  /// The team batting THIS innings.
  ///
  /// Innings alternate: 1 and 3 belong to whoever batted first, 2 and 4 to the
  /// other side. The screen previously special-cased `inningsNumber == 1`,
  /// which gave the wrong side from innings 3 onward (super overs, Tests).
  TeamId get battingTeamId {
    final first = battingFirstTeam(match) ?? match.teamAId;
    if (inningsNumber.isOdd) return first;
    return first == match.teamAId ? match.teamBId : match.teamAId;
  }

  MatchTeamSide get battingSide =>
      battingTeamId == match.teamAId ? MatchTeamSide.a : MatchTeamSide.b;

  MatchTeamSide get bowlingSide =>
      battingSide == MatchTeamSide.a ? MatchTeamSide.b : MatchTeamSide.a;

  List<ScoringPerson> _squad(MatchTeamSide side) => [
        for (final p in matchPlayers)
          if (p.teamSide == side)
            ScoringPerson(
              matchPlayerId: p.id.value,
              name: p.displayName,
              photoUrl: p.photoUrl,
            ),
      ];

  /// The fielding XI — candidate fielders for a dismissal.
  List<ScoringPerson> get fieldingXi => _squad(bowlingSide);

  /// Whoever bowled the most recent delivery, as a `match_player_id`.
  ///
  /// Deliberately read from the ball log rather than `innings.bowlerId`: the
  /// server *clears* `bowler_id` the moment an over completes (that is what
  /// [bowlerSet] detects), so at exactly the point the next-bowler picker
  /// opens the innings row no longer knows who just bowled. Reading it there
  /// let the same player be picked for two overs in a row and rendered the
  /// picker's subtitle with an empty name.
  String? get lastOverBowlerId {
    for (final b in balls.reversed) {
      if (b.bowlerId != null) return b.bowlerId;
    }
    return null;
  }

  /// Name of whoever bowled the last delivery, for the picker's subtitle.
  String get lastOverBowlerName =>
      nameOf(matchPlayers.playerRefIdOf(lastOverBowlerId));

  /// Legal deliveries bowled by a given bowler this innings.
  int bowlerLegalBalls(String? bowlerMatchPlayerId) {
    if (bowlerMatchPlayerId == null) return 0;
    return balls
        .where((b) => b.bowlerId == bowlerMatchPlayerId && b.isLegalDelivery)
        .length;
  }

  /// Bowlers who may take the next over: the fielding side minus whoever just
  /// bowled (since nobody bowls consecutive overs) AND minus anyone who has
  /// reached the max overs per bowler limit.
  List<ScoringPerson> get availableBowlers {
    final justBowled = innings?.bowlerId?.value ?? lastOverBowlerId;
    final maxBalls = (match.format.maxOversPerBowler > 0)
        ? match.format.maxOversPerBowler * ballsPerOver
        : 0;

    return [
      for (final p in fieldingXi)
        if (p.matchPlayerId != justBowled &&
            (maxBalls == 0 || bowlerLegalBalls(p.matchPlayerId) < maxBalls))
          p,
    ];
  }

  /// Batters who have not been in yet — the bench a wicket draws from.
  List<ScoringPerson> get availableBatters {
    final used = <String>{
      for (final b in balls)
        if (b.batsmanId != null) b.batsmanId!,
      if (innings?.strikerId != null) innings!.strikerId!.value,
      if (innings?.nonStrikerId != null) innings!.nonStrikerId!.value,
    };
    return [
      for (final p in _squad(battingSide))
        if (!used.contains(p.matchPlayerId)) p,
    ];
  }

  int? get target => innings?.target;
  bool get isChase => target != null;
  int get runsNeeded => target == null ? 0 : (target! - totalRuns).clamp(0, 1 << 30);

  double? get requiredRunRate {
    if (target == null || ballsRemaining <= 0) return null;
    return (runsNeeded * ballsPerOver) / ballsRemaining;
  }

  // ── Stats ────────────────────────────────────────────────────────────────

  BatterStats get strikerStats => batterStats(innings?.strikerId?.value);
  BatterStats get nonStrikerStats =>
      batterStats(innings?.nonStrikerId?.value);

  PartnershipStats get currentPartnership => currentPartnershipFor(
        balls,
        innings?.strikerId?.value,
        innings?.nonStrikerId?.value,
      );

  BatterStats batterStats(String? matchPlayerId) =>
      batterStatsFor(balls, matchPlayerId);

  BowlerSpell get bowlerSpell => bowlerSpellFor(
        balls,
        innings?.bowlerId?.value,
        ballsPerOver: ballsPerOver,
      );

  ScoringState copyWith({
    bool? isBusy,
    int? pendingCount,
    MatchInningsState? innings,
    List<Ball>? balls,
  }) =>
      ScoringState(
        match: match,
        inningsNumber: inningsNumber,
        innings: innings ?? this.innings,
        balls: balls ?? this.balls,
        matchPlayers: matchPlayers,
        canScore: canScore,
        isBusy: isBusy ?? this.isBusy,
        pendingCount: pendingCount ?? this.pendingCount,
      );

  @override
  List<Object?> get props => [
        match,
        inningsNumber,
        innings,
        balls,
        matchPlayers,
        canScore,
        isBusy,
        pendingCount,
      ];
}
