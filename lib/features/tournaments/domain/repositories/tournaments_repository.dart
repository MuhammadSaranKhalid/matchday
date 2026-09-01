import 'dart:io';

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../matches/domain/entities/match.dart';
import '../entities/ground.dart';
import '../entities/my_tournament_entry.dart';
import '../entities/scorer_candidate.dart';
import '../entities/tournament.dart';
import '../entities/tournament_awards.dart';
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

/// Parameters to schedule a fixture slot.
class FixtureSlotParams {
  const FixtureSlotParams({
    required this.teamAId,
    required this.teamBId,
    required this.scheduledStartTime,
    required this.venue,
    this.round,
    this.bracketRoundNumber,
    this.bracketMatchNumber,
    this.prevMatchAId,
    this.prevMatchBId,
  });

  final String teamAId;
  final String teamBId;
  final DateTime scheduledStartTime;
  final String venue;
  final String? round;
  final int? bracketRoundNumber;
  final int? bracketMatchNumber;
  final String? prevMatchAId;
  final String? prevMatchBId;
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
  Future<Either<Failure, int>> generateAndPublishFixtures({
    required String tournamentId,
    required List<FixtureSlotParams> slots,
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
}
