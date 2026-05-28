import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/ball.dart';
import '../entities/innings.dart';
import '../entities/match.dart';
import '../entities/match_request.dart';

/// Online-only matches contract (Phase 1). Reads/writes hit Supabase directly;
/// no local mirror.
abstract class MatchesRepository {
  /// Propose a friendly. Creates a match in [MatchStatus.pending] with team A's
  /// side filled in.
  Future<Either<Failure, Match>> createMatchRequest({
    required TeamId teamAId,
    required TeamId teamBId,
    required MatchFormat format,
    required List<String> squad,
    required String captain,
    String? keeper,
    Venue? venue,
    DateTime? scheduledStartTime,
  });

  Future<Either<Failure, Match?>> getMatch(MatchId id);

  /// Matches involving any team the user owns/manages.
  Future<Either<Failure, List<Match>>> listMyMatches();

  /// Innings rows for the given match ids in one query. Returns a map keyed
  /// by match id so callers can render per-match score breakdowns without
  /// an N+1 fan-out. Matches not in the result map have no innings yet.
  Future<Either<Failure, Map<MatchId, List<Innings>>>> listInningsForMatches(
    Iterable<MatchId> matchIds,
  );

  /// Opponent accepts: fills team B's side and moves the match to `accepted`.
  Future<Either<Failure, Match>> acceptMatch({
    required MatchId id,
    required List<String> squad,
    required String captain,
    String? keeper,
  });

  /// Opponent declines, with an optional reason. Moves to `declined`.
  Future<Either<Failure, Match>> declineMatch({
    required MatchId id,
    String? reason,
  });

  /// Single-phone match start: records the toss, creates innings 1 with its
  /// openers, and moves the match accepted → live. Returns the new innings.
  ///
  /// Deprecated by the 2-phone Match Start flow ([recordMatchToss] +
  /// [submitMatchOpeners] + [startMatchNow]) but kept until the legacy
  /// single-phone screen is removed.
  Future<Either<Failure, Innings>> startMatch({
    required MatchId id,
    required TeamId tossWonBy,
    required TossDecision tossDecision,
    required TeamId battingTeamId,
    required TeamId bowlingTeamId,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  });

  /// Real-time match row updates. Subscribes to the broadcast channel
  /// `match:<id>:state` (per migration 0810) and decodes the payload into
  /// the [Match] entity. The first event arrives after the initial GET
  /// hydration on subscribe.
  Stream<Match?> watchMatch(MatchId id);

  /// Host phone records the toss. Advances `start_phase: toss → lineup`.
  /// Idempotent — re-calling with the same values is a no-op.
  Future<Either<Failure, Unit>> recordMatchToss({
    required MatchId id,
    required TeamId wonBy,
    required TossDecision decision,
    String? face,
  });

  /// Batting captain locks the opening pair. Advances
  /// `start_phase: lineup → ready`. Idempotent — supports EDIT PICKS.
  Future<Either<Failure, Unit>> submitMatchOpeners({
    required MatchId id,
    required String strikerId,
    required String nonStrikerId,
  });

  /// Batting captain taps Start. Promotes status → live, start_phase → live,
  /// stamps actual_start_time, and adds the caller to `assigned_scorers`.
  Future<Either<Failure, Unit>> startMatchNow(MatchId id);

  // ─── Match Requests (challenge handshake) ────────────────────────────────

  /// Send a friendly-match challenge. Returns the newly-created request id.
  /// `toTeamId` null means an open challenge (any nearby team can claim with
  /// the share code).
  Future<Either<Failure, MatchRequestId>> sendMatchChallenge({
    required TeamId fromTeamId,
    TeamId? toTeamId,
    DateTime? proposedStartTime,
    String? proposedVenue,
    MatchFormat? proposedFormat,
    String? message,
    int playersPerSide = 11,
    List<String> fromTeamXi = const [],
    String? fromTeamKeeperId,
  });

  /// Receiver accepts a pending request, OR sender accepts a counter.
  /// Returns the new match id materialised by `accept_match_request`.
  Future<Either<Failure, MatchId>> acceptMatchChallenge({
    required MatchRequestId requestId,
    DateTime? scheduledStartTime,
    String? venue,
    MatchFormat? format,
    String? decisionNote,
    TeamId? toTeamId,
    List<String> toTeamXi = const [],
    String? toTeamKeeperId,
  });

  /// Receiver proposes changes. Pending → countered. Counter cannot be
  /// re-countered in v1 — the sender must accept or decline.
  Future<Either<Failure, Unit>> counterMatchChallenge({
    required MatchRequestId requestId,
    DateTime? counteredStartTime,
    String? counteredVenue,
    MatchFormat? counteredFormat,
    int? counteredPlayersPerSide,
    String? decisionNote,
  });

  /// Receiver declines a pending request, OR sender declines a counter.
  Future<Either<Failure, Unit>> declineMatchChallenge({
    required MatchRequestId requestId,
    String? decisionNote,
    DeclineReason? decisionReason,
  });

  /// Sender withdraws their own pending or countered request.
  Future<Either<Failure, Unit>> withdrawMatchChallenge({
    required MatchRequestId requestId,
    String? decisionNote,
  });

  /// One-shot fetch of a single match request by id.
  Future<Either<Failure, MatchRequest?>> getMatchChallenge(
    MatchRequestId requestId,
  );

  /// One-shot list of all match requests the user can see (managers of
  /// either side). Both incoming and outgoing. Realtime updates ride the
  /// `user:<id>:notifications` broadcast channel — when a match_request
  /// notification arrives, callers invalidate this provider and re-fetch.
  Future<Either<Failure, List<MatchRequest>>> listMyMatchChallenges();

  /// Lookup the 6-digit in-person share code. Returns null when unknown,
  /// expired, or visible only via the SECURITY DEFINER lookup.
  Future<Either<Failure, MatchRequest?>> findMatchChallengeByCode(String code);

  /// The latest innings for a match (for opening the spectator/scorer by match).
  Future<Either<Failure, Innings?>> getCurrentInnings(MatchId matchId);

  /// Mark a match completed with a result description. Moves to `completed`.
  Future<Either<Failure, Match>> completeMatch({
    required MatchId id,
    required String description,
  });

  /// Persist one delivery ([BallDraft]) and update the innings' current
  /// striker/non-striker/bowler. Aggregate totals update via a DB trigger.
  /// Returns the refreshed innings.
  Future<Either<Failure, Innings>> recordBall(BallDraft draft);

  /// Live deliveries for an innings (oldest first), via Supabase realtime.
  Stream<List<Ball>> watchBalls(InningsId inningsId);

  /// Live innings state (totals + current players), via Supabase realtime.
  Stream<Innings?> watchInnings(InningsId inningsId);
}
