import 'dart:io';

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../matches/domain/entities/match.dart';
import '../../domain/draw/draw_plan.dart';
import '../../domain/entities/ground.dart';
import '../../domain/entities/my_tournament_entry.dart';
import '../../domain/entities/scorer_candidate.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/match_official.dart';
import '../../domain/entities/tournament_awards.dart';
import '../../domain/entities/tournament_fee_entry.dart';
import '../../domain/entities/tournament_leader.dart';
import '../../domain/entities/tournament_organizer.dart';
import '../../domain/ops/revised_target.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament_registration.dart';
import '../../domain/entities/tournament_standing.dart';
import '../../domain/repositories/tournaments_repository.dart';
import '../datasources/tournaments_remote_datasource.dart';

/// Implementation of [TournamentsRepository] that translates all raw exceptions to [Failure]s.
class TournamentsRepositoryImpl implements TournamentsRepository {
  TournamentsRepositoryImpl({required TournamentsRemoteDataSource remote})
      : _remote = remote;

  final TournamentsRemoteDataSource _remote;

  @override
  Future<Either<Failure, Tournament>> getTournament(
      String tournamentId) async {
    try {
      final dto = await _remote.getTournament(tournamentId);
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> getMyTournaments() async {
    try {
      final dtos = await _remote.getMyTournaments();
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> getDiscoverTournaments({
    double? latitude,
    double? longitude,
    double? radiusKm,
    TournamentType? type,
    TournamentStatus? status,
    String? city,
  }) async {
    try {
      final dtos = await _remote.getDiscoverTournaments(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        type: type,
        status: status,
        city: city,
      );
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Tournament>> createTournament(
      CreateTournamentParams params) async {
    try {
      final dto = await _remote.createTournament(params);
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTournament(
      String tournamentId, Map<String, dynamic> updates) async {
    try {
      await _remote.updateTournament(tournamentId, updates);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> publishTournament(
      String tournamentId) async {
    try {
      await _remote.publishTournament(tournamentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelTournament(
      String tournamentId, String reason) async {
    try {
      await _remote.cancelTournament(tournamentId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentRegistration>>>
      getTournamentRegistrations(String tournamentId) async {
    try {
      final dtos = await _remote.getTournamentRegistrations(tournamentId);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentRegistration>> registerTeam({
    required String tournamentId,
    required String teamId,
    required List<String> squadPlayerIds,
    String? message,
  }) async {
    try {
      final dto = await _remote.registerTeam(
        tournamentId: tournamentId,
        teamId: teamId,
        squadPlayerIds: squadPlayerIds,
        message: message,
      );
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveRegistration(
      String registrationId) async {
    try {
      await _remote.approveRegistration(registrationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectRegistration(
      String registrationId, String reason) async {
    try {
      await _remote.rejectRegistration(registrationId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> withdrawRegistration(
      String registrationId) async {
    try {
      await _remote.withdrawRegistration(registrationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePaymentStatus(
      String registrationId, String paymentStatus) async {
    try {
      await _remote.updatePaymentStatus(registrationId, paymentStatus);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignTeamGroup({
    required String registrationId,
    required String? groupId,
  }) async {
    try {
      await _remote.assignTeamGroup(registrationId, groupId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignMultipleTeamsGroup({
    required List<String> registrationIds,
    required String? groupId,
  }) async {
    try {
      await _remote.assignMultipleTeamsGroup(registrationIds, groupId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> autoDistributeGroups({
    required String tournamentId,
    required List<String> groupNames,
  }) async {
    try {
      await _remote.autoDistributeGroups(tournamentId, groupNames);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getTournamentFixtures(
      String tournamentId) async {
    try {
      final fixtures = await _remote.getTournamentFixtures(tournamentId);
      return Right(fixtures);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentStanding>>> getStandings(
      String tournamentId) async {
    try {
      final dtos = await _remote.getStandings(tournamentId);
      return Right(
        dtos.asMap().entries.map((entry) {
          return entry.value.toEntity(rank: entry.key + 1);
        }).toList(),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<TournamentStanding>> watchStandings(String tournamentId) {
    return _remote.watchStandings(tournamentId).map((dtos) {
      return dtos.asMap().entries.map((entry) {
        return entry.value.toEntity(rank: entry.key + 1);
      }).toList();
    });
  }

  @override
  Future<Either<Failure, int>> generateAndPublishFixtures({
    required String tournamentId,
    required DrawPlan plan,
    List<String> seedOrder = const [],
  }) async {
    // A type with no generator reaches here as an empty plan carrying its
    // reason; say the reason rather than "no fixtures to publish".
    final unsupported = plan.unsupported;
    if (unsupported != null) {
      return Left(
        ValidationFailure('$unsupported draws are not supported yet.'),
      );
    }
    if (plan.isEmpty) {
      return const Left(ValidationFailure('There are no fixtures to publish.'));
    }
    try {
      final count = await _remote.generateAndPublishFixtures(
        tournamentId: tournamentId,
        plan: plan,
        seedOrder: seedOrder,
      );
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentAwards>> getSuggestedAwards(
      String tournamentId) async {
    try {
      final awards = await _remote.getSuggestedAwards(tournamentId);
      return Right(awards);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmAwards(
      String tournamentId, TournamentAwards awards) async {
    try {
      await _remote.confirmAwards(tournamentId, awards);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MyTournamentEntry>>> getMyPlayingEntries(
      List<String> teamIds) async {
    if (teamIds.isEmpty) return const Right([]);
    try {
      final rows = await _remote.getMyRegistrations(teamIds);
      return Right([
        for (final row in rows)
          MyTournamentEntry(
            tournament: row.tournament.toEntity(),
            registration: row.registration.toEntity(),
          ),
      ]);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Artwork ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, TournamentArtwork>> uploadArtwork({
    required String tournamentId,
    File? banner,
    File? logo,
  }) async {
    if (banner == null && logo == null) {
      return const Right(TournamentArtwork());
    }
    try {
      final urls = await _remote.uploadArtwork(
        tournamentId: tournamentId,
        banner: banner,
        logo: logo,
      );
      return Right(
        TournamentArtwork(bannerUrl: urls.bannerUrl, logoUrl: urls.logoUrl),
      );
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Grounds ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Ground>>> searchGrounds({
    String? query,
    double? latitude,
    double? longitude,
    int limit = 12,
  }) async {
    try {
      final grounds = await _remote.searchGrounds(
        query: query,
        latitude: latitude,
        longitude: longitude,
        limit: limit,
      );
      return Right(grounds);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ground>> createGround({
    required String name,
    String? city,
    double? latitude,
    double? longitude,
    GroundSurface? surface,
    bool hasFloodlights = false,
    String? notes,
  }) async {
    final trimmed = name.trim();
    // Mirrors the length CHECK on the table so the sheet can fail fast.
    if (trimmed.length < 2 || trimmed.length > 80) {
      return const Left(
        ValidationFailure('A ground name is between 2 and 80 characters.'),
      );
    }
    try {
      final ground = await _remote.createGround(
        name: trimmed,
        city: city,
        latitude: latitude,
        longitude: longitude,
        surface: surface,
        hasFloodlights: hasFloodlights,
        notes: notes,
      );
      return Right(ground);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Ground>>> getTournamentGrounds(
      String tournamentId) async {
    try {
      return Right(await _remote.getTournamentGrounds(tournamentId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setTournamentGrounds({
    required String tournamentId,
    required List<String> groundIds,
  }) async {
    try {
      await _remote.setTournamentGrounds(
        tournamentId: tournamentId,
        groundIds: groundIds,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Live Ops ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<TournamentLiveMatch>>> getLiveBoard(
      String tournamentId) async {
    try {
      final dtos = await _remote.getLiveBoard(tournamentId);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignScorer({
    required String matchId,
    required String userId,
  }) async {
    try {
      await _remote.assignScorer(matchId: matchId, userId: userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rescheduleMatch({
    required String matchId,
    required DateTime startTime,
    String? venue,
  }) async {
    try {
      await _remote.rescheduleMatch(
        matchId: matchId,
        startTime: startTime,
        venue: venue,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> abandonMatch({
    required String matchId,
    required AbandonMode mode,
    DateTime? rescheduleTo,
    String? reason,
  }) async {
    // Business rule, enforced here as well as in SQL so the sheet can fail
    // fast without a round trip.
    if (mode == AbandonMode.reschedule && rescheduleTo == null) {
      return const Left(
        ValidationFailure('Pick a new date before rescheduling this match'),
      );
    }
    try {
      await _remote.abandonMatch(
        matchId: matchId,
        mode: mode.wire,
        rescheduleTo: rescheduleTo,
        reason: reason,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> declareWalkover({
    required String matchId,
    required String winnerTeamId,
    String? reason,
  }) async {
    try {
      await _remote.declareWalkover(
        matchId: matchId,
        winnerTeamId: winnerTeamId,
        reason: reason,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> overrideResult({
    required String matchId,
    required String winnerTeamId,
    required String reason,
  }) async {
    // The canvas makes the reason mandatory: it is what the audit trail
    // shows both managers.
    if (reason.trim().length < 10) {
      return const Left(
        ValidationFailure('Give a reason of at least 10 characters'),
      );
    }
    try {
      await _remote.overrideResult(
        matchId: matchId,
        winnerTeamId: winnerTeamId,
        reason: reason.trim(),
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setCoOrganizer({
    required String tournamentId,
    required String userId,
    required bool add,
  }) async {
    try {
      await _remote.setCoOrganizer(
        tournamentId: tournamentId,
        userId: userId,
        add: add,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScorerCandidate>>> getScorerCandidates(
      String tournamentId) async {
    try {
      final people = await _remote.getScorerCandidates(tournamentId);
      return Right(people);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> sendAnnouncement({
    required String tournamentId,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Write a message first'));
    }
    if (trimmed.length > 300) {
      return const Left(
        ValidationFailure('Announcements are limited to 300 characters'),
      );
    }
    try {
      final count = await _remote.sendAnnouncement(
        tournamentId: tournamentId,
        message: trimmed,
      );
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Fee ledger (artboard 24c) ──────────────────────────────────────────────

  @override
  Future<Either<Failure, List<TournamentFeeEntry>>> getFeeLedger(
    String tournamentId,
  ) async {
    try {
      final dtos = await _remote.getFeeLedger(tournamentId);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> recordPayment({
    required String registrationId,
    required double amountPaid,
    PaymentChannel? channel,
    String? reference,
  }) async {
    // Business rules live here, not in the sheet: a negative receipt is a
    // typo, and a reference longer than the column would be truncated
    // silently by Postgres.
    if (amountPaid < 0) {
      return const Left(ValidationFailure('An amount cannot be negative'));
    }
    final note = reference?.trim();
    if (note != null && note.length > 200) {
      return const Left(
        ValidationFailure('Keep the reference under 200 characters'),
      );
    }

    try {
      await _remote.recordPayment(
        registrationId: registrationId,
        amountPaid: amountPaid,
        channel: channel,
        reference: note == null || note.isEmpty ? null : note,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Match officials (artboard 27j) ─────────────────────────────────────────

  @override
  Future<Either<Failure, List<MatchOfficial>>> getMatchOfficials(
    String matchId,
  ) async {
    try {
      final dtos = await _remote.getMatchOfficials(matchId);
      return Right(
        dtos.map((d) => d.toEntity()).whereType<MatchOfficial>().toList(),
      );
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OfficialCandidate>>> getOfficialCandidates({
    required String tournamentId,
    required String matchId,
  }) async {
    try {
      final dtos = await _remote.getOfficialCandidates(
        tournamentId: tournamentId,
        matchId: matchId,
      );
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> assignOfficial({
    required String matchId,
    required String userId,
    required OfficialRole role,
  }) async {
    if (role == OfficialRole.scorer) {
      return const Left(
        ValidationFailure('Use Assign scorer to change who is scoring'),
      );
    }
    try {
      await _remote.assignOfficial(
        matchId: matchId,
        userId: userId,
        role: role,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeOfficial({
    required String matchId,
    required OfficialRole role,
  }) async {
    if (role == OfficialRole.scorer) {
      return const Left(
        ValidationFailure('Use Assign scorer to change who is scoring'),
      );
    }
    try {
      await _remote.removeOfficial(matchId: matchId, role: role);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Matchday-morning ops (artboards 27k, 27m, 28b, 28c) ────────────────────

  @override
  Future<Either<Failure, int>> autoAssignScorers(String tournamentId) async {
    try {
      return Right(await _remote.autoAssignScorers(tournamentId));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> reviseMatchConditions({
    required String matchId,
    required int revisedOvers,
    required int bowlerQuota,
    int? revisedTarget,
    TargetMethod method = TargetMethod.runRate,
    String? reason,
  }) async {
    // The five-over floor is a competition rule, so it is checked on the way
    // out as well as in SQL — the sheet should never be able to post a
    // revision the server will only reject after a round trip.
    if (revisedOvers < RevisedTargetCalculator.minimumOvers) {
      return const Left(
        ValidationFailure(
          'A result needs at least '
          '${RevisedTargetCalculator.minimumOvers} overs per side',
        ),
      );
    }
    if (bowlerQuota < 1) {
      return const Left(
        ValidationFailure('Each bowler needs at least one over'),
      );
    }
    if (method != TargetMethod.runRate &&
        revisedTarget != null &&
        revisedTarget < 1) {
      return const Left(ValidationFailure('A target must be at least 1 run'));
    }

    try {
      await _remote.reviseMatchConditions(
        matchId: matchId,
        revisedOvers: revisedOvers,
        bowlerQuota: bowlerQuota,
        revisedTarget: revisedTarget,
        method: method,
        reason: reason,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> triggerSuperOver({
    required String matchId,
    required String batsFirstTeamId,
  }) async {
    try {
      await _remote.triggerSuperOver(
        matchId: matchId,
        batsFirstTeamId: batsFirstTeamId,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentLeaderboards>> getLeaderboards(
    String tournamentId, {
    int limit = 5,
  }) async {
    try {
      return Right(await _remote.getLeaderboards(tournamentId, limit: limit));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentOrganizer?>> getOrganizer(
    String tournamentId,
  ) async {
    try {
      return Right(await _remote.getOrganizer(tournamentId));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
