import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/format_preset.dart';
import '../../domain/entities/innings_summary.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/entities/match_request.dart';
import '../../domain/repositories/matches_repository.dart';
import '../datasources/format_presets_remote_datasource.dart';
import '../datasources/match_requests_remote_datasource.dart';
import '../datasources/matches_remote_datasource.dart';

/// Online-only matches repository. The only place the remote data sources'
/// raw exceptions become [Failure]s. Composes three focused data sources —
/// one repository per aggregate, several data sources behind it:
///  • [MatchesRemoteDataSource]        — match lifecycle + live scoring
///  • [MatchRequestsRemoteDataSource]  — the challenge handshake
///  • [FormatPresetsRemoteDataSource]  — the format catalog
class MatchesRepositoryImpl implements MatchesRepository {
  MatchesRepositoryImpl(this._remote, this._requests, this._presets);

  final MatchesRemoteDataSource _remote;
  final MatchRequestsRemoteDataSource _requests;
  final FormatPresetsRemoteDataSource _presets;

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
    try {
      final dto = await _remote.getById(id.value);
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
  Future<Either<Failure, Unit>> recordMatchToss({
    required MatchId id,
    required TeamId wonBy,
    required TossDecision decision,
    String? face,
  }) async {
    try {
      await _remote.recordMatchToss(
        matchId: id.value,
        wonBy: wonBy.value,
        decision: decision.wire,
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
    try {
      final dtos = await _remote.listMatchPlayers(matchId.value);
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
    try {
      final dto = await _remote.getMatchInningsState(
        matchId: matchId.value,
        inningsNumber: inningsNumber,
      );
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
  Future<Either<Failure, Ball>> recordBall(BallDraft d) async {
    // Cricket invariants the server also checks, but failing fast here gives
    // a clean ValidationFailure rather than a Postgres error.
    if (d.isWicket && d.wicketType == null) {
      return const Left(ValidationFailure('A wicket needs a wicket type'));
    }
    if (d.runsScored < 0 || d.extras < 0) {
      return const Left(
        ValidationFailure('Runs and extras must be non-negative'),
      );
    }
    if ((d.ballKind == BallKind.bye || d.ballKind == BallKind.legBye) &&
        d.runsScored != 0) {
      return const Left(
        ValidationFailure('Bye / leg-bye runs belong in extras'),
      );
    }
    try {
      final dto = await _remote.recordBall({
        'p_match_id': d.matchId.value,
        'p_innings_number': d.inningsNumber,
        'p_is_legal_delivery': d.isLegalDelivery,
        'p_ball_type': d.ballKind.wire,
        'p_runs_scored': d.runsScored,
        'p_extras': d.extras,
        'p_is_wicket': d.isWicket,
        if (d.wicketType != null) 'p_wicket_type': d.wicketType!.wire,
        if (d.batsmanId != null) 'p_batsman_id': d.batsmanId,
        if (d.nonStrikerId != null) 'p_non_striker_id': d.nonStrikerId,
        if (d.bowlerId != null) 'p_bowler_id': d.bowlerId,
        if (d.fielderId != null) 'p_fielder_id': d.fielderId,
        if (d.commentary != null) 'p_commentary': d.commentary,
        // Optimistic-lock guard. Null skips the check (single-scorer mode);
        // a non-null value asks the RPC to reject with 40001 when the
        // server's match_innings_state.version has advanced past it.
        if (d.expectedVersion != null) 'p_expected_version': d.expectedVersion,
      });
      return Right(dto.toEntity());
    } on ConflictException catch (e) {
      // Another scorer advanced the version first. Benign: the realtime stream
      // already carries the fresh state, so the UI can refresh and retry.
      return Left(ConflictFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> undoLastBall({
    required MatchId matchId,
    required int inningsNumber,
  }) async {
    try {
      final ok = await _remote.undoLastBall(
        matchId: matchId.value,
        inningsNumber: inningsNumber,
      );
      return Right(ok);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
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
