import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/ball.dart';
import '../entities/format_preset.dart';
import '../entities/innings_summary.dart';
import '../entities/match.dart';
import '../entities/match_innings_state.dart';
import '../entities/match_player.dart';
import '../entities/match_pool_application.dart';
import '../entities/match_request.dart';
import '../entities/match_innings.dart';
import '../entities/match_wicket.dart';
import '../entities/match_room_snapshot.dart';

/// Online-only matches contract. Reads/writes hit Supabase directly; no
/// local mirror. The deployed schema has NO innings table — innings are
/// keyed by `(match_id, innings_number)` on the `balls` table; per-team
/// totals are aggregated from balls.
abstract class MatchesRepository {
  /// The active format presets from the backend catalog (setup picker source).
  Future<Either<Failure, List<FormatPreset>>> listFormatPresets();

  Future<Either<Failure, Match?>> getMatch(MatchId id);

  /// Matches involving any team the user owns/manages.
  Future<Either<Failure, List<Match>>> listMyMatches();

  /// Every match in [statuses], for the Matches tab's public board.
  ///
  /// Distinct from [listMyMatches] on purpose: the bottom nav shows the world,
  /// the side panel shows you. Windowed by scheduled start so "Upcoming" and
  /// "Finished" stay to a week either side rather than the whole archive.
  Future<Either<Failure, List<Match>>> listPublicMatches({
    required Set<MatchStatus> statuses,
    DateTime? from,
    DateTime? to,
    bool newestFirst = false,
  });

  /// Per-team innings totals (runs/wickets/overs) for a set of matches,
  /// aggregated from the `balls` table. Used by My Matches past tiles.
  /// Matches with no balls return an empty list. Returns a map keyed by
  /// match id.
  Future<Either<Failure, Map<MatchId, List<InningsSummary>>>>
  listInningsForMatches(Iterable<MatchId> matchIds);

  /// Real-time match row updates. Subscribes to the broadcast channel
  /// `match:<id>:state` (per migration 0810) and decodes the payload into
  /// the [Match] entity. The first event arrives after the initial GET
  /// hydration on subscribe.
  Stream<Match?> watchMatch(MatchId id);

  Future<Either<Failure, MatchRoomSnapshot>> getMatchRoom(MatchId id);

  Stream<MatchRoomSnapshot> watchMatchRoom(MatchId id);

  Future<Either<Failure, MatchRoomSnapshot>> startMatch({
    required MatchId id,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  });

  Future<Either<Failure, MatchRoomSnapshot>> addMatchParticipant({
    required MatchId id,
    required MatchTeamSide side,
    required String displayName,
    required String idempotencyKey,
  });

  /// Record the complete physical toss atomically.
  ///
  /// The authorized Cricket setup-side member/official records both the winner and the winning
  /// side's verbal bat/bowl choice. The server authorizes this through
  /// `cricket.match.setup`; role names and `created_by` are not authorization.
  Future<Either<Failure, Unit>> recordToss({
    required MatchId id,
    required TeamId wonBy,
    required TossDecision decision,
    String? face,
  });

  /// Effective generic RBAC check used only to render the correct UI.
  /// The Edge Function independently re-checks the same permission on write.
  Future<Either<Failure, bool>> canTeamPermission({
    required TeamId teamId,
    required String permission,
  });

  /// Match-scoped effective permission, used for assigned officials.
  Future<Either<Failure, bool>> canMatchPermission({
    required MatchId matchId,
    required String permission,
  });

  /// A user with `cricket.match.setup` for the batting team (or a match-scoped
  /// setup grant) locks the opening pair. Advances
  /// `start_phase: lineup → ready`. Idempotent — supports EDIT PICKS.
  Future<Either<Failure, Unit>> submitMatchOpeners({
    required MatchId id,
    required String strikerId,
    required String nonStrikerId,
  });

  /// A user with batting-side/match `cricket.match.setup` taps Start. Promotes
  /// status → live, start_phase → live,
  /// stamps actual_start_time, and adds the caller to `assigned_scorers`.
  Future<Either<Failure, Unit>> startMatchNow(MatchId id);

  /// Cancel a confirmed, non-tournament match before it goes live.
  ///
  /// Authorization:
  /// - effective team-scoped `match.cancel` on either participating team
  /// - OR an explicit match-scoped `match.cancel` grant
  ///
  /// The Edge Function re-checks this authoritatively.
  Future<Either<Failure, Unit>> cancelMatch({
    required MatchId id,
    String? reason,
  });

  // ─── Match Requests (challenge handshake) ────────────────────────────────

  /// Send a friendly-match challenge. Returns the newly-created request id.
  /// `toTeamId` null means an open challenge (any nearby team can claim with
  /// the share code).
  Future<Either<Failure, MatchRequestId>> sendMatchChallenge({
    required TeamId fromTeamId,
    TeamId? toTeamId,
    DateTime? proposedStartTime,
    String? proposedVenue,
    String? proposedFormatCode,
    MatchFormat? proposedFormat,
    String? message,
    int playersPerSide = 11,
    List<String> fromTeamXi = const [],
    String? fromTeamKeeperId,
  });

  /// Receiver accepts a pending request, OR sender accepts a counter.
  /// Returns the new match id materialised by match request acceptance.
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
    String? counteredFormatCode,
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
  /// either side). Both incoming and outgoing.
  Future<Either<Failure, List<MatchRequest>>> listMyMatchChallenges();

  /// Lookup the 6-digit in-person share code.
  Future<Either<Failure, MatchRequest?>> findMatchChallengeByCode(String code);

  /// Apply to an open match pool post with a team and optional XI.
  Future<Either<Failure, String>> applyToMatchPool({
    required MatchRequestId requestId,
    required TeamId teamId,
    List<String> xi = const [],
    String? keeperId,
    String? message,
  });

  /// List all applications submitted for a match challenge.
  Future<Either<Failure, List<MatchPoolApplication>>> listPoolApplications(
    MatchRequestId requestId,
  );

  /// Host captain accepts an applicant to lock in the match fixture.
  Future<Either<Failure, MatchId>> acceptPoolApplication({
    required String applicationId,
    String? decisionNote,
  });

  /// Host captain rejects an applicant.
  Future<Either<Failure, Unit>> rejectPoolApplication({
    required String applicationId,
    String? reason,
  });

  /// Mark a match completed with a result description.
  Future<Either<Failure, Match>> completeMatch({
    required MatchId id,
    required String description,
  });

  // ─── Match players (per-match XI) ────────────────────────────────────────

  /// The full playing XI for a match — both sides, in batting order
  /// where set. Powers the bowler / batter / fielder pickers on the
  /// scoring screen and the lineup display on the spectator side.
  /// Returns an empty list for matches whose lineup has not been
  /// materialised yet.
  Future<Either<Failure, List<MatchPlayer>>> listMatchPlayers(MatchId matchId);

  // ─── Live innings state ──────────────────────────────────────────────────

  /// One-shot fetch of the (match, innings) live state. Returns null if
  /// the innings hasn't been opened yet (start_innings or
  /// submit_match_openers hasn't run for this innings).
  Future<Either<Failure, MatchInningsState?>> getMatchInningsState({
    required MatchId matchId,
    required int inningsNumber,
  });

  /// Real-time live-state updates for one innings. Subscribes to the
  /// `match:<id>:state` broadcast channel and emits on every
  /// `innings_state_updated` event for [inningsNumber]. First emission
  /// is the initial-hydration fetch.
  Stream<MatchInningsState?> watchMatchInningsState({
    required MatchId matchId,
    required int inningsNumber,
  });

  // ─── Live scoring ────────────────────────────────────────────────────────

  /// Open innings N — inserts (or upserts) the (match, innings) row in
  /// match_innings_state with the on-field trio and flips matches.status
  /// → live. Idempotent: re-calling overwrites the trio without
  /// inserting balls. Used for the opener pick at ball 1 of innings 1
  /// and for opening the chase at innings 2.
  ///
  /// Online-only, like the rest of the innings-break handover. Trio changes
  /// made DURING an innings are a scoring write and go through
  /// `ScoringSession`, which queues them.
  ///
  /// IDs are match_player_id values — look them up from
  /// [listMatchPlayers] before calling.
  Future<Either<Failure, Unit>> startInnings({
    required MatchId matchId,
    required int inningsNumber,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,

    /// The chase target for this innings (first-innings runs + 1). Only set when
    /// opening the second innings; null preserves any existing target.
    int? target,
  });

  /// One-shot list of deliveries for (match, innings), oldest-first.
  Future<Either<Failure, List<Ball>>> listBalls(
    MatchId matchId,
    int inningsNumber,
  );

  /// Live deliveries for (match, innings). Subscribes to the broadcast
  /// channel `match:<id>:balls` (per migration 0810) and emits the full
  /// list filtered to this innings, oldest-first. Initial hydration via a
  /// one-shot SELECT.
  Stream<List<Ball>> watchBalls(MatchId matchId, int inningsNumber);

  /// Whether the signed-in user may record deliveries for this innings.
  ///
  /// Answered by the server so the UI gate and the write-path check are the
  /// same rule: a tournament organiser, an assigned scorer, a practice-match
  /// creator, or a manager of the side currently batting. Deriving it on the
  /// client instead produced a narrower rule that locked assigned scorers out
  /// of matches they were entitled to score.
  Future<Either<Failure, bool>> canScoreInnings({
    required MatchId matchId,
    required int inningsNumber,
  });

  // ─── Innings & Wickets ──────────────────────────────────────────────────

  /// The innings rows for a match, oldest-first.
  ///
  /// Needed to reach [getWickets], which is keyed by the innings uuid while
  /// deliveries carry only an innings number.
  Future<Either<Failure, List<MatchInnings>>> listInnings(MatchId matchId);

  Future<Either<Failure, List<MatchWicket>>> getWickets(String inningsId);

  // ─── Scorer Lease ───────────────────────────────────────────────────────

  Future<Either<Failure, Map<String, dynamic>>> acquireScorerLease({
    required MatchId matchId,
    required String deviceId,
  });

  Future<Either<Failure, Map<String, dynamic>>> heartbeatScorerLease({
    required MatchId matchId,
    required String deviceId,
  });
}
