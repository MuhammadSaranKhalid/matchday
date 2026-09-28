import 'dart:io';

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../matches/domain/entities/match.dart';
import '../draw/draw_plan.dart';
import '../entities/ground.dart';
import '../entities/my_tournament_entry.dart';
import '../entities/scorer_candidate.dart';
import '../entities/tournament.dart';
import '../entities/match_official.dart';
import '../entities/tournament_awards.dart';
import '../entities/tournament_fee_entry.dart';
import '../entities/tournament_leader.dart';
import '../entities/tournament_organizer.dart';
import '../ops/revised_target.dart';
import '../entities/tournament_live_match.dart';
import '../entities/tournament_registration.dart';
import '../entities/tournament_standing.dart';

/// The URLs stored after an artwork upload. Either may be null when only one
/// image was supplied.
class TournamentArtwork {
  const TournamentArtwork({this.bannerUrl, this.logoUrl});

  final String? bannerUrl;
  final String? logoUrl;
}

/// Parameters required to create a new tournament.
class CreateTournamentParams {
  const CreateTournamentParams({
    required this.name,
    required this.type,
    required this.privacy,
    this.description,
    this.format = const {},
    this.rules = const {},
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.city,
    this.latitude,
    this.longitude,
    this.venues = const [],
    this.groundIds = const [],
    this.prizeDetails,
    this.entryFee,
    this.minTeams,
    this.maxTeams,
    this.bannerImageUrl,
    this.logoUrl,
  });

  final String name;
  final TournamentType type;
  final TournamentPrivacy privacy;
  final String? description;
  final Map<String, dynamic> format;
  final Map<String, dynamic> rules;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  final String? city;
  final double? latitude;
  final double? longitude;
  /// Legacy free-text venue list. Still written so older reads keep working;
  /// [groundIds] is the authoritative link.
  final List<TournamentVenue> venues;

  /// Rows in `grounds`, in display order — the order drives the G1/G2 labels.
  final List<String> groundIds;
  final String? prizeDetails;
  final double? entryFee;
  final int? minTeams;
  final int? maxTeams;
  final String? bannerImageUrl;
  final String? logoUrl;
}

/// Abstract contract for tournament data operations. Pure Dart.
abstract class TournamentsRepository {
  Future<Either<Failure, Tournament>> getTournament(String tournamentId);

  Future<Either<Failure, List<Tournament>>> getMyTournaments();

  Future<Either<Failure, List<Tournament>>> getDiscoverTournaments({
    double? latitude,
    double? longitude,
    double? radiusKm,
    TournamentType? type,
    TournamentStatus? status,
    String? city,
  });

  Future<Either<Failure, Tournament>> createTournament(
    CreateTournamentParams params,
  );

  Future<Either<Failure, void>> updateTournament(
    String tournamentId,
    Map<String, dynamic> updates,
  );

  Future<Either<Failure, void>> publishTournament(String tournamentId);

  Future<Either<Failure, void>> cancelTournament(String tournamentId, String reason);

  // Registrations
  Future<Either<Failure, List<TournamentRegistration>>> getTournamentRegistrations(
    String tournamentId,
  );

  Future<Either<Failure, TournamentRegistration>> registerTeam({
    required String tournamentId,
    required String teamId,
    required List<String> squadPlayerIds,
    String? message,
  });

  Future<Either<Failure, void>> approveRegistration(String registrationId);

  Future<Either<Failure, void>> rejectRegistration(
    String registrationId,
    String reason,
  );

  Future<Either<Failure, void>> withdrawRegistration(String registrationId);

  Future<Either<Failure, void>> updatePaymentStatus(
    String registrationId,
    String paymentStatus,
  );

  Future<Either<Failure, void>> assignTeamGroup({
    required String registrationId,
    required String? groupId,
  });

  Future<Either<Failure, void>> assignMultipleTeamsGroup({
    required List<String> registrationIds,
    required String? groupId,
  });

  Future<Either<Failure, void>> autoDistributeGroups({
    required String tournamentId,
    required List<String> groupNames,
  });

  // Fixtures, Bracket & Standings
  Future<Either<Failure, List<Match>>> getTournamentFixtures(
    String tournamentId,
  );

  Future<Either<Failure, List<TournamentStanding>>> getStandings(
    String tournamentId,
  );

  Stream<List<TournamentStanding>> watchStandings(String tournamentId);

  /// Publishes the draw and returns how many fixtures were created.
  ///
  /// Takes the whole [DrawPlan] — every round, including the unresolved ones
  /// linked by feeder slot — rather than a flat slot list, because a knockout
  /// with only its first round inserted has nothing for the advancement
  /// trigger to move winners into. [seedOrder] is the approved teams in draw
  /// order; position becomes `seed_number`, written in the same transaction.
  Future<Either<Failure, int>> generateAndPublishFixtures({
    required String tournamentId,
    required DrawPlan plan,
    List<String> seedOrder = const [],
  });

  // Awards
  Future<Either<Failure, TournamentAwards>> getSuggestedAwards(
    String tournamentId,
  );

  Future<Either<Failure, void>> confirmAwards(
    String tournamentId,
    TournamentAwards awards,
  );

  /// Tournaments the caller's teams are registered in, with the registration
  /// that puts them there. Backs the hub's "Playing" bucket.
  Future<Either<Failure, List<MyTournamentEntry>>> getMyPlayingEntries(
    List<String> teamIds,
  );

  // ─── Artwork ───────────────────────────────────────────────────────────────

  /// Uploads the supplied artwork and stores the resulting URLs on the
  /// tournament. Only valid once the tournament exists — the storage policy
  /// authorises against the tournament id in the object path.
  Future<Either<Failure, TournamentArtwork>> uploadArtwork({
    required String tournamentId,
    File? banner,
    File? logo,
  });

  // ─── Grounds ───────────────────────────────────────────────────────────────

  /// Ranked by name similarity then proximity. An empty [query] lists the
  /// nearest grounds.
  Future<Either<Failure, List<Ground>>> searchGrounds({
    String? query,
    double? latitude,
    double? longitude,
    int limit,
  });

  Future<Either<Failure, Ground>> createGround({
    required String name,
    String? city,
    double? latitude,
    double? longitude,
    GroundSurface? surface,
    bool hasFloodlights,
    String? notes,
  });

  Future<Either<Failure, List<Ground>>> getTournamentGrounds(
    String tournamentId,
  );

  Future<Either<Failure, void>> setTournamentGrounds({
    required String tournamentId,
    required List<String> groundIds,
  });

  // ─── Live Ops (artboards 27, 27c–g, 28) ────────────────────────────────────

  /// The multi-ground board: every fixture with its scorer and last-ball
  /// staleness already resolved server-side.
  Future<Either<Failure, List<TournamentLiveMatch>>> getLiveBoard(
    String tournamentId,
  );

  Future<Either<Failure, void>> assignScorer({
    required String matchId,
    required String userId,
  });

  Future<Either<Failure, void>> rescheduleMatch({
    required String matchId,
    required DateTime startTime,
    String? venue,
  });

  /// [AbandonMode.reschedule] discards the scorecard and needs [rescheduleTo];
  /// [AbandonMode.noResult] splits the points and leaves NRR untouched.
  Future<Either<Failure, void>> abandonMatch({
    required String matchId,
    required AbandonMode mode,
    DateTime? rescheduleTo,
    String? reason,
  });

  Future<Either<Failure, void>> declareWalkover({
    required String matchId,
    required String winnerTeamId,
    String? reason,
  });

  /// Audited: the reason is attached to the scorecard permanently.
  Future<Either<Failure, void>> overrideResult({
    required String matchId,
    required String winnerTeamId,
    required String reason,
  });

  Future<Either<Failure, void>> setCoOrganizer({
    required String tournamentId,
    required String userId,
    required bool add,
  });

  /// Organisers and approved-team managers — the people at the ground.
  Future<Either<Failure, List<ScorerCandidate>>> getScorerCandidates(
    String tournamentId,
  );

  /// Returns the number of people the announcement actually reached.
  Future<Either<Failure, int>> sendAnnouncement({
    required String tournamentId,
    required String message,
  });

  // ─── Fee ledger (artboard 24c) ──────────────────────────────────────────────

  /// Every approved team's fee line. Organiser-only — it names who paid what.
  Future<Either<Failure, List<TournamentFeeEntry>>> getFeeLedger(
    String tournamentId,
  );

  /// Records the cumulative amount received for one registration. A set, not
  /// an increment: the sheet shows the running total and the organiser
  /// confirms the new figure, so a mistyped entry is fixed by re-recording.
  Future<Either<Failure, Unit>> recordPayment({
    required String registrationId,
    required double amountPaid,
    PaymentChannel? channel,
    String? reference,
  });

  // ─── Match officials (artboard 27j) ─────────────────────────────────────────

  Future<Either<Failure, List<MatchOfficial>>> getMatchOfficials(String matchId);

  Future<Either<Failure, List<OfficialCandidate>>> getOfficialCandidates({
    required String tournamentId,
    required String matchId,
  });

  /// Appoints an umpire or referee. The scorer role goes through
  /// [assignScorer] — it carries handover rules these do not.
  Future<Either<Failure, Unit>> assignOfficial({
    required String matchId,
    required String userId,
    required OfficialRole role,
  });

  Future<Either<Failure, Unit>> removeOfficial({
    required String matchId,
    required OfficialRole role,
  });

  // ─── Matchday-morning ops (artboards 27k, 27m, 28b, 28c) ────────────────────

  /// Fills every unscored fixture it can and returns how many it filled.
  Future<Either<Failure, int>> autoAssignScorers(String tournamentId);

  /// Applies a rain revision. The caller computes the numbers with
  /// [RevisedTargetCalculator]; this records the decision.
  Future<Either<Failure, Unit>> reviseMatchConditions({
    required String matchId,
    required int revisedOvers,
    required int bowlerQuota,
    int? revisedTarget,
    TargetMethod method,
    String? reason,
  });

  /// Moves a tied fixture into its super over (artboard 28c).
  Future<Either<Failure, Unit>> triggerSuperOver({
    required String matchId,
    required String batsFirstTeamId,
  });

  /// The orange- and purple-cap boards, aggregated from what has been scored
  /// (artboards 10, 11, 15). Distinct from `getSuggestedAwards`, which reads
  /// the organiser's *published* awards and is empty until the cup ends.
  Future<Either<Failure, TournamentLeaderboards>> getLeaderboards(
    String tournamentId, {
    int limit,
  });

  /// The organiser's track record, for the credibility row (artboard 09).
  Future<Either<Failure, TournamentOrganizer?>> getOrganizer(
    String tournamentId,
  );
}
