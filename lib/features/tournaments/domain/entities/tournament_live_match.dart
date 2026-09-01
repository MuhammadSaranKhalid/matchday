import 'package:meta/meta.dart';

/// One innings line on a live ground card — "161/7 (20.0)".
@immutable
class LiveInningsLine {
  const LiveInningsLine({
    required this.inningsNumber,
    required this.battingTeamId,
    required this.runs,
    required this.wickets,
    required this.legalBalls,
  });

  final int inningsNumber;
  final String? battingTeamId;
  final int runs;
  final int wickets;
  final int legalBalls;

  /// Overs in cricket's `O.B` notation — 16.2 means 16 overs and 2 balls.
  /// Purely a display transform of a count the engine already produced; no
  /// scoring arithmetic is being re-derived here.
  String get oversText {
    final overs = legalBalls ~/ 6;
    final balls = legalBalls % 6;
    return '$overs.$balls';
  }

  String get scoreText => '$runs/$wickets ($oversText)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveInningsLine &&
          other.inningsNumber == inningsNumber &&
          other.battingTeamId == battingTeamId &&
          other.runs == runs &&
          other.wickets == wickets &&
          other.legalBalls == legalBalls;

  @override
  int get hashCode =>
      Object.hash(inningsNumber, battingTeamId, runs, wickets, legalBalls);
}

/// A fixture as the organiser's Live Ops board sees it (artboard 27): the
/// ground it is on, who is scoring it, and how stale the last ball is.
@immutable
class TournamentLiveMatch {
  const TournamentLiveMatch({
    required this.matchId,
    required this.venue,
    required this.status,
    required this.scheduledStartTime,
    this.round,
    this.teamAId,
    this.teamAName,
    this.teamBId,
    this.teamBName,
    this.winnerId,
    this.resultDescription,
    this.scorerId,
    this.scorerName,
    this.lastBallAt,
    this.inningsLines = const [],
  });

  final String matchId;
  final String venue;
  final String status;
  final DateTime scheduledStartTime;
  final String? round;
  final String? teamAId;
  final String? teamAName;
  final String? teamBId;
  final String? teamBName;
  final String? winnerId;
  final String? resultDescription;
  final String? scorerId;
  final String? scorerName;
  final DateTime? lastBallAt;
  final List<LiveInningsLine> inningsLines;

  bool get isLive =>
      status == 'live' || status == 'innings_break' || status == 'super_over';

  bool get isFinished => const {
        'completed',
        'abandoned',
        'tied',
        'no_result',
        'walkover',
      }.contains(status);

  /// The console's cream "needs action" row: a fixture yet to be played with
  /// nobody appointed to score it.
  bool get needsScorer => scorerId == null && !isFinished;

  String displayNameFor(String? teamId) {
    if (teamId == null) return 'TBC';
    if (teamId == teamAId) return teamAName ?? 'Team A';
    if (teamId == teamBId) return teamBName ?? 'Team B';
    return 'TBC';
  }

  LiveInningsLine? lineFor(String? teamId) {
    if (teamId == null) return null;
    for (final line in inningsLines) {
      if (line.battingTeamId == teamId) return line;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentLiveMatch &&
          other.matchId == matchId &&
          other.status == status &&
          other.venue == venue &&
          other.scorerId == scorerId &&
          other.lastBallAt == lastBallAt &&
          other.winnerId == winnerId;

  @override
  int get hashCode =>
      Object.hash(matchId, status, venue, scorerId, lastBallAt, winnerId);
}

/// How an abandoned match is resolved (artboard 28, sheet 1).
enum AbandonMode {
  /// Scorecard discarded; the fixture returns as upcoming.
  reschedule('reschedule'),

  /// Points split 1–1. Counts as played; NRR unaffected.
  noResult('no_result');

  const AbandonMode(this.wire);
  final String wire;
}
