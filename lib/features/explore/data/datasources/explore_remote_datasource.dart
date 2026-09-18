import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/match_result_dto.dart';
import '../models/player_result_dto.dart';
import '../models/team_result_dto.dart';
import '../models/tournament_result_dto.dart';

/// Wraps the `search-all` edge function.
///
/// One function, two modes: a body with `q` searches, a body without it
/// browses. Grouping server-side is what lets the four categories share a
/// single relevance ordering and one round-trip per keystroke.
class ExploreRemoteDataSource {
  ExploreRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _fn = 'search-all';

  /// Text search. Returns the raw grouped payload; mapping to entities is the
  /// repository's job.
  Future<({
    List<PlayerResultDto> players,
    List<TeamResultDto> teams,
    List<MatchResultDto> matches,
    List<TournamentResultDto> tournaments,
  })> search(
    String query, {
    String? kind,
    int? limit,
    Future<void>? cancelSignal,
  }) async {
    final data = await _invoke({
      'q': query,
      if (kind != null) 'kind': kind,
      if (limit != null) 'limit': limit,
    }, abortSignal: cancelSignal);
    return (
      players: _list(data, 'players', PlayerResultDto.fromJson),
      teams: _list(data, 'teams', TeamResultDto.fromJson),
      matches: _list(data, 'matches', MatchResultDto.fromJson),
      tournaments: _list(data, 'tournaments', TournamentResultDto.fromJson),
    );
  }

  /// Empty-query discovery: live matches, open tournaments, recent teams,
  /// players to follow.
  Future<({
    List<MatchResultDto> live,
    List<TournamentResultDto> tournaments,
    List<TeamResultDto> teams,
    List<PlayerResultDto> players,
  })> browse() async {
    final data = await _invoke(const <String, dynamic>{});
    return (
      live: _list(data, 'live', MatchResultDto.fromJson),
      tournaments: _list(data, 'tournaments', TournamentResultDto.fromJson),
      teams: _list(data, 'teams', TeamResultDto.fromJson),
      players: _list(data, 'players', PlayerResultDto.fromJson),
    );
  }

  Future<Map<String, dynamic>> _invoke(
    Map<String, dynamic> body, {
    Future<void>? abortSignal,
  }) async {
    try {
      final res = await _supabase.functions.invoke(
        _fn,
        body: body,
        abortSignal: abortSignal,
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw ServerException('Unexpected search response shape');
      }
      // The function reports its own failures in-band as {ok:false, error}.
      // A 500 arrives as a FunctionException instead — both are handled.
      if (data['ok'] == false) {
        final err = data['error'];
        final message = err is Map ? '${err['message']}' : 'Search failed';
        throw ServerException(message);
      }
      return data;
    } on RequestAbortedException {
      throw const OperationCancelledException();
    } on FunctionsHttpException catch (e) {
      final details = e.details;
      final message = details is Map && details['error'] is Map
          ? '${(details['error'] as Map)['message']}'
          : 'Search failed (${e.status})';
      if (e.status == 401) throw UnauthorizedException(message);
      throw ServerException(message, statusCode: e.status);
    } on FunctionsFetchException catch (e) {
      throw NetworkException(
        e.reasonPhrase ?? 'Failed to reach search service',
      );
    } on FunctionsRelayException catch (e) {
      throw ServerException(
        'Search relay failure: ${e.reasonPhrase ?? ''}',
        statusCode: e.status,
      );
    } on FunctionException catch (e) {
      // Details carries the function's JSON body when it returned one.
      final details = e.details;
      final message = details is Map && details['error'] is Map
          ? '${(details['error'] as Map)['message']}'
          : 'Search failed (${e.status})';
      if (e.status == 401) throw UnauthorizedException(message);
      throw ServerException(message, statusCode: e.status);
    }
  }

  /// Decodes one group, skipping rows that fail to parse rather than failing
  /// the whole search — one malformed row must not blank the results list.
  static List<T> _list<T>(
    Map<String, dynamic> data,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = data[key];
    if (raw is! List) return const [];
    final out = <T>[];
    for (final row in raw) {
      if (row is! Map) continue;
      try {
        out.add(fromJson(Map<String, dynamic>.from(row)));
      } catch (_) {
        // skip the bad row
      }
    }
    return out;
  }
}
