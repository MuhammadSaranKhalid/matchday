import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/format_preset.dart';
import '../../domain/entities/innings_summary.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_batsman_stats.dart';
import '../../domain/entities/match_bowler_stats.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/entities/match_pool_application.dart';
import '../../domain/entities/match_request.dart';
import '../../domain/entities/match_wicket.dart';
import '../../domain/repositories/matches_repository.dart';
import '../datasources/format_presets_remote_datasource.dart';
import '../datasources/match_requests_remote_datasource.dart';
import '../datasources/matches_remote_datasource.dart';

/// Online-only matches repository. The only place the remote data sources'
import '../datasources/matches_local_datasource.dart';

/// Concrete repository implementation. Wraps data sources and ensures that all
/// raw exceptions become [Failure]s. Composes focused data sources —
/// one repository per aggregate, several data sources behind it:
///  • [MatchesRemoteDataSource]        — match lifecycle + live scoring
///  • [MatchRequestsRemoteDataSource]  — the challenge handshake
///  • [FormatPresetsRemoteDataSource]  — the format catalog
///  • [MatchesLocalDataSource]         — offline write-ahead log & snapshots
class MatchesRepositoryImpl implements MatchesRepository {
  MatchesRepositoryImpl(
    this._remote,
    this._requests,
    this._presets, [
    this._local,
  ]);

  final MatchesRemoteDataSource _remote;
  final MatchRequestsRemoteDataSource _requests;
  final FormatPresetsRemoteDataSource _presets;
  final MatchesLocalDataSource? _local;

  @override
  Future<Either<Failure, List<FormatPreset>>> listFormatPresets() async {
    try {
      final dtos = await _presets.listFormatPresets();
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
  Future<Either<Failure, Match?>> getMatch(MatchId id) async {
    final local = _local;
    if (local != null) {
      final cached = await local.getCachedMatch(id.value);
      if (cached != null) {
        // Return cached immediately; refresh in background if online
        unawaited(_remote.getById(id.value).then((dto) {
          if (dto != null) local.cacheMatch(dto);
        }).catchError((_) {}));
        return Right(cached.toEntity());
      }
    }
    try {
      final dto = await _remote.getById(id.value);
      if (dto != null && local != null) {
        await local.cacheMatch(dto);
      }
      return Right(dto?.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> listMyMatches() async {
    try {
      final dtos = await _remote.list();
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> listPublicMatches({
    required Set<MatchStatus> statuses,
    DateTime? from,
    DateTime? to,
    bool newestFirst = false,
  }) async {
    try {
      final dtos = await _remote.listPublic(
        statuses: statuses.map((s) => s.wire),
        from: from,
        to: to,
        newestFirst: newestFirst,
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
  Future<Either<Failure, Map<MatchId, List<InningsSummary>>>>
      listInningsForMatches(Iterable<MatchId> matchIds) async {
    try {
      final ids = matchIds.toList();
      if (ids.isEmpty) return const Right({});
      // Fetch matches (need team-a / team-b ids to bucket balls by batting
      // team) and balls in one round trip.
      final matchDtos = await Future.wait(
        ids.map((id) async => await _remote.getById(id.value)),
      );
      final matchesById = <String, _MatchInfo>{};
      for (final dto in matchDtos) {
        if (dto == null) continue;
        matchesById[dto.matchId] = _MatchInfo(
          teamAId: dto.teamAId,
          teamBId: dto.teamBId,
          tossWonBy: dto.tossWonBy,
          tossDecision: dto.tossDecision,
        );
      }
      final ballDtos = await _remote.listBallsForMatches(
        ids.map((m) => m.value).toList(),
      );

      // Bucket by (matchId, inningsNumber) and aggregate.
      final byKey = <String, _InningsAcc>{};
      for (final b in ballDtos) {
        final info = matchesById[b.matchId];
        if (info == null) continue;
        final battingTeamId = _battingTeamForInnings(info, b.inningsNumber);
        final key = '${b.matchId}|${b.inningsNumber}';
        final acc = byKey.putIfAbsent(
          key,
          () => _InningsAcc(
            matchId: b.matchId,
            inningsNumber: b.inningsNumber,
            battingTeamId: battingTeamId,
          ),
        );
        acc.totalRuns += b.runsScored + b.extras;
        if (b.isWicket) acc.wickets++;
        if (b.isLegalDelivery) acc.legalBalls++;
      }

      final grouped = <MatchId, List<InningsSummary>>{};
      for (final acc in byKey.values) {
        final mid = MatchId(acc.matchId);
        grouped.putIfAbsent(mid, () => []).add(InningsSummary(
              matchId: mid,
              inningsNumber: acc.inningsNumber,
              battingTeamId: TeamId(acc.battingTeamId),
              totalRuns: acc.totalRuns,
              totalWickets: acc.wickets,
              legalBallsFaced: acc.legalBalls,
            ));
      }
      for (final list in grouped.values) {
        list.sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
      }
      return Right(grouped);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Match Start ─────────────────────────────────────────────────────────

  @override
  Stream<Match?> watchMatch(MatchId id) => _remote
      .watchMatch(id.value)
      .map((dto) => dto?.toEntity())
      .handleError(
        (Object e) => throw FailureWrapper(ServerFailure(e.toString())),
      );

  @override
  Future<Either<Failure, Unit>> recordTossWinner({
    required MatchId id,
    required TeamId wonBy,
    String? face,
  }) async {
    try {
      await _remote.recordTossWinner(
        matchId: id.value,
        wonBy: wonBy.value,
        face: face,
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
  Future<Either<Failure, Unit>> recordTossDecision({
    required MatchId id,
    required TossDecision decision,
  }) async {
    try {
      await _remote.recordTossDecision(
        matchId: id.value,
        decision: decision.wire,
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
  Future<Either<Failure, Unit>> submitMatchOpeners({
    required MatchId id,
    required String strikerId,
    required String nonStrikerId,
  }) async {
    if (strikerId.isEmpty || nonStrikerId.isEmpty) {
      return const Left(ValidationFailure('Both openers are required'));
    }
    if (strikerId == nonStrikerId) {
      return const Left(
        ValidationFailure('Striker and non-striker must be different players'),
      );
    }
    try {
      await _remote.submitMatchOpeners(
        matchId: id.value,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
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
  Future<Either<Failure, Unit>> startMatchNow(MatchId id) async {
    try {
      await _remote.startMatchNow(id.value);
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Scoring ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> startInnings({
    required MatchId matchId,
    required int inningsNumber,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
    int? target,
  }) async {
    if (strikerId.isEmpty || nonStrikerId.isEmpty || bowlerId.isEmpty) {
      return const Left(
        ValidationFailure('Striker, non-striker, and bowler are all required'),
      );
    }
    if (strikerId == nonStrikerId) {
      return const Left(
        ValidationFailure('Striker and non-striker must be different'),
      );
    }

    // Online-only, and no write-ahead log entry. This is the innings-break
    // handover, which the banner keeps online-only; it used to queue an op
    // that only the scoring drain loop could send, so on this path the op was
    // written and then never drained.
    try {
      await _remote.startInnings(
        matchId: matchId.value,
        inningsNumber: inningsNumber,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        bowlerId: bowlerId,
        target: target,
      );
      return const Right(unit);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MatchPlayer>>> listMatchPlayers(
    MatchId matchId,
  ) async {
    final local = _local;
    if (local != null) {
      final cached = await local.getCachedMatchPlayers(matchId.value);
      if (cached.isNotEmpty) {
        unawaited(_remote.listMatchPlayers(matchId.value).then((dtos) {
          if (dtos.isNotEmpty) local.cacheMatchPlayers(matchId.value, dtos);
        }).catchError((_) {}));
        return Right(cached.map((d) => d.toEntity()).toList());
      }
    }
    try {
      final dtos = await _remote.listMatchPlayers(matchId.value);
      if (dtos.isNotEmpty && local != null) {
        await local.cacheMatchPlayers(matchId.value, dtos);
      }
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
  Future<Either<Failure, MatchInningsState?>> getMatchInningsState({
    required MatchId matchId,
    required int inningsNumber,
  }) async {
    final local = _local;
    if (local != null) {
      final cached = await local.getCachedInningsState(
        matchId: matchId.value,
        inningsNumber: inningsNumber,
      );
      if (cached != null) {
        unawaited(_remote.getMatchInningsState(
          matchId: matchId.value,
          inningsNumber: inningsNumber,
        ).then((dto) {
          if (dto != null) local.cacheInningsState(matchId.value, dto);
        }).catchError((_) {}));
        return Right(cached.toEntity());
      }
    }
    try {
      final dto = await _remote.getMatchInningsState(
        matchId: matchId.value,
        inningsNumber: inningsNumber,
      );
      if (dto != null && local != null) {
        await local.cacheInningsState(matchId.value, dto);
      }
      return Right(dto?.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<MatchInningsState?> watchMatchInningsState({
    required MatchId matchId,
    required int inningsNumber,
  }) =>
      _remote
          .watchMatchInningsState(
            matchId: matchId.value,
            inningsNumber: inningsNumber,
          )
          .map((dto) => dto?.toEntity());

  @override
  Future<Either<Failure, bool>> canScoreInnings({
    required MatchId matchId,
    required int inningsNumber,
  }) async {
    try {
      final allowed = await _remote.canScoreInnings(
        matchId: matchId.value,
        inningsNumber: inningsNumber,
      );
      return Right(allowed);
    } on UnauthorizedException {
      // Not entitled is an answer, not an error — the screen renders the
      // read-only scoreboard rather than an error state.
      return const Right(false);
    } on ServerException {
      // Offline fallback: allow local scoring to proceed
      return const Right(true);
    } catch (_) {
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, List<Ball>>> listBalls(
    MatchId matchId,
    int inningsNumber,
  ) async {
    try {
      final dtos = await _remote.listBalls(
        matchId: matchId.value,
        inningsNumber: inningsNumber,
      );
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      final local = _local;
      if (local != null) {
        final pending = await local.pendingOps(
          matchId: matchId.value,
          inningsNumber: inningsNumber,
        );
        if (pending.isNotEmpty) {
          final balls = <Ball>[];
          for (final op in pending) {
            if (op.kind == 'ball') {
              final p = op.payload;
              final rawRuns = p['runs_scored'] ?? p['p_runs_scored'];
              final int runsScored = rawRuns is num ? rawRuns.toInt() : 0;
              final rawExtras = p['extras'] ?? p['p_extras'];
              final int extras = rawExtras is num ? rawExtras.toInt() : 0;
              final isWicket = (p['is_wicket'] ?? p['p_is_wicket']) == true;
              final rawWicket = (p['wicket_type'] ?? p['p_wicket_type']) as String?;
              final wicketType = rawWicket != null
                  ? WicketType.values.where((w) => w.wire == rawWicket).firstOrNull
                  : null;
              final isLegal = (p['is_legal_delivery'] ?? p['p_is_legal_delivery']) == true;
              final rawKind = (p['ball_type'] ?? p['p_ball_type'] ?? 'legal') as String;
              final ballKind = BallKind.values.where((k) => k.wire == rawKind).firstOrNull ?? BallKind.legal;
              final rawOver = p['over_number'] ?? p['p_over_number'];
              final int overNumber = rawOver is num ? rawOver.toInt() : 0;
              final rawBallInOver = p['ball_in_over'] ?? p['p_ball_in_over'];
              final int ballInOver = rawBallInOver is num ? rawBallInOver.toInt() : 0;

              balls.add(Ball(
                id: BallId('local:${op.opId}'),
                matchId: matchId,
                inningsNumber: inningsNumber,
                seq: op.localSeq,
                overNumber: overNumber,
                ballInOver: ballInOver,
                isLegalDelivery: isLegal,
                ballKind: ballKind,
                runsScored: runsScored,
                extras: extras,
                isWicket: isWicket,
                isFreeHit: (p['is_free_hit'] ?? p['p_is_free_hit']) == true,
                wicketType: wicketType,
                dismissedPlayerId: (p['dismissed_player_id'] ?? p['p_dismissed_player_id']) as String?,
                batsmanId: (p['batsman_id'] ?? p['p_batsman_id']) as String?,
                nonStrikerId: (p['non_striker_id'] ?? p['p_non_striker_id']) as String?,
                bowlerId: (p['bowler_id'] ?? p['p_bowler_id']) as String?,
                fielderId: (p['fielder_id'] ?? p['p_fielder_id']) as String?,
                commentary: (p['commentary'] ?? p['p_commentary']) as String?,
              ));
            }
          }
          return Right(balls);
        }
      }
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Ball>> watchBalls(MatchId matchId, int inningsNumber) => _remote
      .watchBalls(matchId: matchId.value, inningsNumber: inningsNumber)
      .map((dtos) => dtos.map((d) => d.toEntity()).toList())
      .handleError(
        (Object e) => throw FailureWrapper(ServerFailure(e.toString())),
      );

  // ─── Match Requests ──────────────────────────────────────────────────────

  @override
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
  }) async {
    if (message != null && message.length > 500) {
      return const Left(ValidationFailure('Message too long (max 500 chars)'));
    }
    if (playersPerSide < 5 || playersPerSide > 15) {
      return const Left(
        ValidationFailure('Players per side must be between 5 and 15'),
      );
    }
    if (fromTeamXi.length > playersPerSide) {
      return const Left(
        ValidationFailure('XI has more players than players_per_side'),
      );
    }
    final trimmedMessage = message?.trim();
    try {
      final id = await _requests.sendMatchChallenge(
        fromTeamId: fromTeamId.value,
        toTeamId: toTeamId?.value,
        proposedStartTime: proposedStartTime,
        proposedVenue: proposedVenue,
        proposedFormat: proposedFormat,
        message: trimmedMessage,
        playersPerSide: playersPerSide,
        fromTeamXi: fromTeamXi,
        fromTeamKeeperId: fromTeamKeeperId,
      );
      return Right(MatchRequestId(id));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ConflictException catch (e) {
      return Left(ConflictFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MatchId>> acceptMatchChallenge({
    required MatchRequestId requestId,
    DateTime? scheduledStartTime,
    String? venue,
    MatchFormat? format,
    String? decisionNote,
    TeamId? toTeamId,
    List<String> toTeamXi = const [],
    String? toTeamKeeperId,
  }) async {
    try {
      final id = await _requests.acceptMatchChallenge(
        requestId: requestId.value,
        scheduledStartTime: scheduledStartTime,
        venue: venue,
        format: format,
        decisionNote: decisionNote,
        toTeamId: toTeamId?.value,
        toTeamXi: toTeamXi,
        toTeamKeeperId: toTeamKeeperId,
      );
      if (id == null) {
        return const Left(ServerFailure('Accept returned no match id'));
      }
      return Right(MatchId(id));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> counterMatchChallenge({
    required MatchRequestId requestId,
    DateTime? counteredStartTime,
    String? counteredVenue,
    MatchFormat? counteredFormat,
    int? counteredPlayersPerSide,
    String? decisionNote,
  }) async {
    final changesAny = counteredStartTime != null ||
        (counteredVenue != null && counteredVenue.trim().isNotEmpty) ||
        counteredFormat != null ||
        counteredPlayersPerSide != null;
    if (!changesAny) {
      return const Left(
        ValidationFailure('A counter must change at least one field'),
      );
    }
    if (counteredPlayersPerSide != null &&
        (counteredPlayersPerSide < 5 || counteredPlayersPerSide > 15)) {
      return const Left(
        ValidationFailure('Players per side must be between 5 and 15'),
      );
    }
    final trimmedNote = decisionNote?.trim();
    try {
      await _requests.counterMatchChallenge(
        requestId: requestId.value,
        counteredStartTime: counteredStartTime,
        counteredVenue: counteredVenue,
        counteredFormat: counteredFormat,
        counteredPlayersPerSide: counteredPlayersPerSide,
        decisionNote: trimmedNote,
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
  Future<Either<Failure, Unit>> declineMatchChallenge({
    required MatchRequestId requestId,
    String? decisionNote,
    DeclineReason? decisionReason,
  }) async {
    final trimmedNote = decisionNote?.trim();
    try {
      await _requests.declineMatchChallenge(
        requestId: requestId.value,
        decisionNote: trimmedNote,
        decisionReason: decisionReason?.wire,
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
  Future<Either<Failure, Unit>> withdrawMatchChallenge({
    required MatchRequestId requestId,
    String? decisionNote,
  }) async {
    final trimmedNote = decisionNote?.trim();
    try {
      await _requests.withdrawMatchChallenge(
        requestId: requestId.value,
        decisionNote: trimmedNote,
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
  Future<Either<Failure, MatchRequest?>> getMatchChallenge(
    MatchRequestId requestId,
  ) async {
    try {
      final dto = await _requests.getMatchChallenge(requestId.value);
      return Right(dto?.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MatchRequest?>> findMatchChallengeByCode(
    String code,
  ) async {
    final trimmed = code.trim();
    if (trimmed.length != 6 || int.tryParse(trimmed) == null) {
      return const Left(ValidationFailure('Share code must be 6 digits'));
    }
    try {
      final dto = await _requests.findMatchChallengeByCode(trimmed);
      return Right(dto?.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MatchRequest>>> listMyMatchChallenges() async {
    try {
      final dtos = await _requests.listMyMatchChallenges();
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Completion ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Match>> completeMatch({
    required MatchId id,
    required String description,
  }) async {
    final desc = description.trim();
    if (desc.isEmpty) {
      return const Left(ValidationFailure('A result is required'));
    }
    try {
      final dto = await _remote.update(id.value, {
        'status': 'completed',
        'result': {'description': desc},
        'end_time': DateTime.now().toIso8601String(),
      });
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> applyToMatchPool({
    required MatchRequestId requestId,
    required TeamId teamId,
    List<String> xi = const [],
    String? keeperId,
    String? message,
  }) async {
    try {
      final appId = await _requests.applyToMatchPool(
        requestId: requestId.value,
        applicantTeamId: teamId.value,
        applicantXi: xi,
        applicantKeeperId: keeperId,
        message: message,
      );
      return Right(appId);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MatchPoolApplication>>> listPoolApplications(
    MatchRequestId requestId,
  ) async {
    try {
      final dtos = await _requests.listPoolApplications(requestId.value);
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
  Future<Either<Failure, MatchId>> acceptPoolApplication({
    required String applicationId,
    String? decisionNote,
  }) async {
    try {
      final matchId = await _requests.acceptPoolApplication(
        applicationId: applicationId,
        decisionNote: decisionNote,
      );
      return Right(MatchId(matchId));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> rejectPoolApplication({
    required String applicationId,
    String? reason,
  }) async {
    try {
      await _requests.rejectPoolApplication(
        applicationId: applicationId,
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

  // ─── Materialized Scorecards & Wickets ──────────────────────────────────

  @override
  Future<Either<Failure, List<MatchBatsmanStats>>> getBatsmanStats(
    String inningsId,
  ) async {
    try {
      final dtos = await _remote.listBatsmanStats(inningsId);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MatchBowlerStats>>> getBowlerStats(
    String inningsId,
  ) async {
    try {
      final dtos = await _remote.listBowlerStats(inningsId);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MatchWicket>>> getWickets(
    String inningsId,
  ) async {
    try {
      final dtos = await _remote.listWickets(inningsId);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Scorer Lease ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Map<String, dynamic>>> acquireScorerLease({
    required MatchId matchId,
    required String deviceId,
  }) async {
    try {
      final result = await _remote.acquireScorerLease(
        matchId: matchId.value,
        deviceId: deviceId,
      );
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> heartbeatScorerLease({
    required MatchId matchId,
    required String deviceId,
  }) async {
    try {
      final result = await _remote.heartbeatScorerLease(
        matchId: matchId.value,
        deviceId: deviceId,
      );
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}

// ─── Internal helpers (innings aggregation) ───────────────────────────────

class _MatchInfo {
  const _MatchInfo({
    required this.teamAId,
    required this.teamBId,
    this.tossWonBy,
    this.tossDecision,
  });
  final String teamAId;
  final String teamBId;
  final String? tossWonBy; // team id that won the toss
  final String? tossDecision; // 'bat' | 'bowl'
}

/// Which team bats in [inningsNumber], derived from the toss. Odd innings are
/// the team that batted first; even innings the other. Mirrors the scoring
/// screen's `_battingTeamId` and the edge function so all three agree.
String _battingTeamForInnings(_MatchInfo info, int inningsNumber) {
  final tossWon = info.tossWonBy;
  final decision = info.tossDecision;
  final String batsFirst;
  if (tossWon != null && decision != null) {
    batsFirst = decision == 'bat'
        ? tossWon
        : (tossWon == info.teamAId ? info.teamBId : info.teamAId);
  } else {
    batsFirst = info.teamAId;
  }
  final other = batsFirst == info.teamAId ? info.teamBId : info.teamAId;
  return inningsNumber.isOdd ? batsFirst : other;
}

class _InningsAcc {
  _InningsAcc({
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
  });

  final String matchId;
  final int inningsNumber;
  final String battingTeamId;
  int totalRuns = 0;
  int wickets = 0;
  int legalBalls = 0;
}
