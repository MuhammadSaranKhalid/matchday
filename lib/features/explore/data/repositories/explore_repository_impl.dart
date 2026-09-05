import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/explore_results.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_remote_datasource.dart';

/// The only place raw exceptions become [Failure]s for this feature
/// (CLAUDE.md Rule 2).
class ExploreRepositoryImpl implements ExploreRepository {
  ExploreRepositoryImpl(this._remote);
  final ExploreRemoteDataSource _remote;

  /// Below this the trigram threshold makes matching useless and we would
  /// pay a round-trip for noise. Mirrors the server's own MIN_QUERY_LEN, so
  /// a short query is rejected here rather than returning empty from the wire.
  static const _minQueryLen = 2;

  @override
  Future<Either<Failure, ExploreResults>> search(
    String query, {
    ExploreCategory? category,
    int? limit,
  }) async {
    final q = query.trim();
    if (q.length < _minQueryLen) return const Right(ExploreResults.empty);
    try {
      final res = await _remote.search(
        q,
        kind: category?.wireName,
        limit: limit,
      );
      return Right(
        ExploreResults(
          players: res.players.map((d) => d.toEntity()).toList(),
          teams: res.teams.map((d) => d.toEntity()).toList(),
          matches: res.matches.map((d) => d.toEntity()).toList(),
          tournaments: res.tournaments.map((d) => d.toEntity()).toList(),
        ),
      );
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, ExploreBrowse>> browse() async {
    try {
      final res = await _remote.browse();
      return Right(
        ExploreBrowse(
          live: res.live.map((d) => d.toEntity()).toList(),
          tournaments: res.tournaments.map((d) => d.toEntity()).toList(),
          teams: res.teams.map((d) => d.toEntity()).toList(),
          players: res.players.map((d) => d.toEntity()).toList(),
        ),
      );
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  /// Shared translation so search and browse cannot report the same
  /// condition differently.
  Failure _toFailure(Object e) => switch (e) {
        UnauthorizedException(:final message) => AuthFailure(message),
        NotFoundException(:final message) => NotFoundFailure(message),
        ServerException(:final message) => ServerFailure(message),
        // Explore is the screen most likely to be opened on a bad connection,
        // so a socket error gets its own Failure rather than falling through
        // to Unknown — the UI offers "retry" for it specifically.
        SocketException() => const NetworkFailure('No connection'),
        _ => UnknownFailure(e.toString()),
      };
}
