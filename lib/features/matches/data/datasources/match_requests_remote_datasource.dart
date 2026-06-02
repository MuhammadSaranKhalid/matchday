import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/match.dart' show MatchFormat;
import '../models/match_request_dto.dart';

/// Talks to Supabase for the `match_requests` table and its challenge-handshake
/// RPCs (send / accept / counter / decline / cancel / find-by-code).
///
/// A match request is its OWN aggregate: it has an independent id and lifecycle
/// (pending → countered → accepted / declined / withdrawn) and exists BEFORE
/// any `matches` row is materialised. So it gets its own data source instead of
/// riding inside the match-lifecycle one. Returns DTOs / RPC result types;
/// throws raw exceptions (translated to Failures in the repository).
///
/// Methods take typed values and build the snake_case `p_*` RPC params HERE, at
/// the data boundary — including wire serialization (dates → ISO-8601 UTC,
/// [MatchFormat] → jsonb via [MatchRequestDto.formatToJson]). The repository
/// stays free of wire-format assembly (and of any DTO import).
class MatchRequestsRemoteDataSource {
  MatchRequestsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'match_requests';

  /// Send a challenge. Returns the new request id.
  Future<String> sendMatchChallenge({
    required String fromTeamId,
    String? toTeamId,
    DateTime? proposedStartTime,
    String? proposedVenue,
    MatchFormat? proposedFormat,
    String? message,
    required int playersPerSide,
    required List<String> fromTeamXi,
    String? fromTeamKeeperId,
  }) async {
    try {
      final result = await _supabase.rpc<dynamic>('send_match_request', params: {
        'p_from_team_id': fromTeamId,
        if (toTeamId != null) 'p_to_team_id': toTeamId,
        if (proposedStartTime != null)
          'p_proposed_start_time': proposedStartTime.toUtc().toIso8601String(),
        if (proposedVenue != null) 'p_proposed_venue': proposedVenue,
        if (proposedFormat != null)
          'p_proposed_format': MatchRequestDto.formatToJson(proposedFormat),
        if (message != null) 'p_message': message,
        'p_players_per_side': playersPerSide,
        'p_from_team_xi': fromTeamXi,
        if (fromTeamKeeperId != null) 'p_from_team_keeper_id': fromTeamKeeperId,
      });
      if (result is String) return result;
      if (result is List && result.isNotEmpty) return result.first.toString();
      throw ServerException('send_match_request returned no id');
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  /// Receiver accepts a pending request (or sender accepts a counter). Returns
  /// the new match id materialised by the RPC.
  Future<String?> acceptMatchChallenge({
    required String requestId,
    DateTime? scheduledStartTime,
    String? venue,
    MatchFormat? format,
    String? decisionNote,
    String? toTeamId,
    required List<String> toTeamXi,
    String? toTeamKeeperId,
  }) async {
    try {
      final result =
          await _supabase.rpc<dynamic>('accept_match_request', params: {
        'p_request_id': requestId,
        if (scheduledStartTime != null)
          'p_scheduled_start_time': scheduledStartTime.toUtc().toIso8601String(),
        if (venue != null) 'p_venue': venue,
        if (format != null) 'p_format': MatchRequestDto.formatToJson(format),
        if (decisionNote != null) 'p_decision_note': decisionNote,
        if (toTeamId != null) 'p_to_team_id': toTeamId,
        'p_to_team_xi': toTeamXi,
        if (toTeamKeeperId != null) 'p_to_team_keeper_id': toTeamKeeperId,
      });
      if (result is String) return result;
      if (result is List && result.isNotEmpty) return result.first.toString();
      return null;
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<void> counterMatchChallenge({
    required String requestId,
    DateTime? counteredStartTime,
    String? counteredVenue,
    MatchFormat? counteredFormat,
    int? counteredPlayersPerSide,
    String? decisionNote,
  }) async {
    try {
      await _supabase.rpc<void>('counter_match_request', params: {
        'p_request_id': requestId,
        if (counteredStartTime != null)
          'p_countered_start_time': counteredStartTime.toUtc().toIso8601String(),
        if (counteredVenue != null) 'p_countered_venue': counteredVenue,
        if (counteredFormat != null)
          'p_countered_format': MatchRequestDto.formatToJson(counteredFormat),
        if (counteredPlayersPerSide != null)
          'p_countered_players_per_side': counteredPlayersPerSide,
        if (decisionNote != null) 'p_decision_note': decisionNote,
      });
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<void> declineMatchChallenge({
    required String requestId,
    String? decisionNote,
    String? decisionReason,
  }) async {
    try {
      await _supabase.rpc<void>('decline_match_request', params: {
        'p_request_id': requestId,
        if (decisionNote != null) 'p_decision_note': decisionNote,
        if (decisionReason != null) 'p_decision_reason': decisionReason,
      });
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<void> withdrawMatchChallenge({
    required String requestId,
    String? decisionNote,
  }) async {
    try {
      await _supabase.rpc<void>('cancel_match_request', params: {
        'p_request_id': requestId,
        if (decisionNote != null) 'p_decision_note': decisionNote,
      });
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<MatchRequestDto?> getMatchChallenge(String requestId) async {
    try {
      final row = await _supabase
          .from(_table)
          .select()
          .eq('request_id', requestId)
          .maybeSingle();
      return row == null ? null : MatchRequestDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<MatchRequestDto?> findMatchChallengeByCode(String code) async {
    try {
      final rows = await _supabase.rpc<List<dynamic>>(
        'find_match_request_by_code',
        params: {'p_code': code},
      );
      if (rows.isEmpty) return null;
      return MatchRequestDto.fromJson(
        Map<String, dynamic>.from(rows.first as Map),
      );
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<List<MatchRequestDto>> listMyMatchChallenges() async {
    try {
      final rows = await _supabase
          .from(_table)
          .select()
          .order('created_at', ascending: false);
      return rows.map(MatchRequestDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Translate RPC PostgrestException codes into our own exceptions.
  Exception _rpcException(PostgrestException e) {
    if (e.code == '42501' || e.code == '28000') {
      return UnauthorizedException(e.message);
    }
    return ServerException(e.message);
  }
}
