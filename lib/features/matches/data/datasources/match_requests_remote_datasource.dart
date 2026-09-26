import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/match.dart' show MatchFormat;
import '../models/match_pool_application_dto.dart';
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

  static const _table = 'match_challenges';

  /// Send a challenge. Returns the new request id.
  ///
  /// Goes through the `send-match-request` edge function (TS orchestrator,
  /// see `supabase/functions/send-match-request/index.ts`) which mirrors the
  /// `send_match_request` PG function — same `p_*` body shape — but lets us
  /// extend validation / push fan-out without DB migrations. The PG function
  /// remains in place as a fallback for direct-DB callers.
  Future<String> sendMatchChallenge({
    required String fromTeamId,
    String? toTeamId,
    DateTime? proposedStartTime,
    String? proposedVenue,
    String? proposedFormatCode,
    MatchFormat? proposedFormat,
    String? message,
    int playersPerSide = 11,
    List<String> fromTeamXi = const [],
    String? fromTeamKeeperId,
  }) async {
    final body = <String, dynamic>{
      'p_from_team_id': fromTeamId,
      if (toTeamId != null) 'p_to_team_id': toTeamId,
      if (proposedStartTime != null)
        'p_proposed_start_time': proposedStartTime.toUtc().toIso8601String(),
      if (proposedVenue != null) 'p_proposed_venue': proposedVenue,
      if (proposedFormatCode != null)
        'p_proposed_format_code': proposedFormatCode,
      if (proposedFormat != null)
        'p_proposed_format': MatchRequestDto.formatToJson(proposedFormat),
      if (message != null) 'p_message': message,
      'p_players_per_side': playersPerSide,
    };
    try {
      final res = await _supabase.functions.invoke(
        'send-match-request',
        body: body,
      );
      final data = res.data;
      if (data is Map && data['request_id'] is String) {
        return data['request_id'] as String;
      }
      throw const ServerException('send-match-request returned no request_id');
    } on FunctionException catch (e) {
      throw _functionException(e);
    }
  }

  /// Receiver accepts a pending request (or sender accepts a counter).
  /// Dispatches to the transactional `match-request-action` Edge command.
  /// Returns the newly created match id.
  Future<String> acceptMatchChallenge({
    required String requestId,
    String? decisionNote,
    String? toTeamId,
    DateTime? scheduledStartTime,
    String? venue,
    MatchFormat? format,
    List<String> toTeamXi = const [],
    String? toTeamKeeperId,
  }) async {
    final body = <String, dynamic>{
      'request_id': requestId,
      if (decisionNote != null) 'decision_note': decisionNote,
      if (toTeamId != null) 'to_team_id': toTeamId,
    };
    try {
      final res = await _supabase.functions.invoke(
        'match-request-action',
        body: {'action': 'accept_challenge', 'body': body},
      );
      final data = res.data;
      if (data is Map &&
          data['match_id'] is String &&
          (data['match_id'] as String).isNotEmpty) {
        return data['match_id'] as String;
      }
      throw const ServerException('match-request-action returned no match_id');
    } on FunctionException catch (e) {
      throw _functionException(e, fallbackMessage: 'accept_challenge failed');
    }
  }

  Future<void> counterMatchChallenge({
    required String requestId,
    DateTime? counteredStartTime,
    String? counteredVenue,
    String? counteredFormatCode,
    MatchFormat? counteredFormat,
    int? counteredPlayersPerSide,
    String? decisionNote,
  }) async {
    try {
      await _supabase.rpc<void>(
        'counter_match_request',
        params: {
          'p_request_id': requestId,
          if (counteredStartTime != null)
            'p_countered_start_time':
                counteredStartTime.toUtc().toIso8601String(),
          if (counteredVenue != null) 'p_countered_venue': counteredVenue,
          if (counteredFormatCode != null)
            'p_countered_format_code': counteredFormatCode,
          if (counteredFormat != null)
            'p_countered_format': MatchRequestDto.formatToJson(counteredFormat),
          if (decisionNote != null) 'p_decision_note': decisionNote,
        },
      );
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
      await _supabase.rpc<void>(
        'decline_match_request',
        params: {
          'p_request_id': requestId,
          if (decisionNote != null) 'p_decision_note': decisionNote,
          if (decisionReason != null) 'p_decision_reason': decisionReason,
        },
      );
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<void> withdrawMatchChallenge({
    required String requestId,
    String? decisionNote,
  }) async {
    try {
      await _supabase.rpc<void>(
        'cancel_match_request',
        params: {
          'p_request_id': requestId,
          if (decisionNote != null) 'p_decision_note': decisionNote,
        },
      );
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<MatchRequestDto?> getMatchChallenge(String requestId) async {
    try {
      final row =
          await _supabase
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

  Future<String> applyToMatchPool({
    required String requestId,
    required String applicantTeamId,
    List<String> applicantXi = const [],
    String? applicantKeeperId,
    String? message,
  }) async {
    try {
      final id = await _supabase.rpc<String>(
        'apply_to_match_pool',
        params: {
          'p_request_id': requestId,
          'p_applicant_team_id': applicantTeamId,
          if (message != null) 'p_message': message,
        },
      );
      return id;
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<List<MatchPoolApplicationDto>> listPoolApplications(
    String requestId,
  ) async {
    try {
      final rows = await _supabase
          .from('match_pool_applications')
          .select()
          .eq('request_id', requestId)
          .order('created_at', ascending: false);
      return rows.map(MatchPoolApplicationDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<String> acceptPoolApplication({
    required String applicationId,
    String? decisionNote,
  }) async {
    final body = <String, dynamic>{
      'application_id': applicationId,
      if (decisionNote != null) 'decision_note': decisionNote,
    };
    try {
      final res = await _supabase.functions.invoke(
        'match-request-action',
        body: {'action': 'accept_pool_application', 'body': body},
      );
      final data = res.data;
      if (data is Map &&
          data['match_id'] is String &&
          (data['match_id'] as String).isNotEmpty) {
        return data['match_id'] as String;
      }
      throw const ServerException('match-request-action returned no match_id');
    } on FunctionException catch (e) {
      throw _functionException(
        e,
        fallbackMessage: 'accept_pool_application failed',
      );
    }
  }

  Future<void> rejectPoolApplication({
    required String applicationId,
    String? reason,
  }) async {
    try {
      await _supabase.rpc<void>(
        'reject_pool_application',
        params: {
          'p_application_id': applicationId,
          if (reason != null) 'p_reason': reason,
        },
      );
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  /// Translate RPC PostgrestException codes into our own exceptions.
  Exception _rpcException(PostgrestException e) {
    if (e.code == '42501' || e.code == '28000') {
      return UnauthorizedException(e.message);
    }
    return ServerException(e.message);
  }

  /// Translate edge function failures into typed exceptions. The TS handler
  /// always returns `{ ok:false, error:{ code, message } }` on failure with
  /// an appropriate HTTP status (see `send-match-request/index.ts`).
  Exception _functionException(
    FunctionException e, {
    String fallbackMessage = 'match request action failed',
  }) {
    if (e is FunctionsFetchException) {
      return NetworkException(
        e.reasonPhrase ?? 'No connection to match request service',
      );
    }
    if (e is FunctionsRelayException) {
      return ServerException(
        'Relay error: ${e.reasonPhrase ?? ''}',
        statusCode: e.status,
      );
    }
    String? msg;
    final d = e.details;
    if (d is Map && d['error'] is Map) {
      msg = (d['error'] as Map)['message']?.toString();
    }
    switch (e.status) {
      case 401:
      case 403:
        return UnauthorizedException(
          msg ?? 'Not allowed to perform this match action',
        );
      case 409:
        return ConflictException(msg ?? 'A pending request already exists');
      case 422:
        return ValidationException(msg ?? 'Validation failed');
      default:
        return ServerException(
          msg ?? fallbackMessage,
          statusCode: e.status,
        );
    }
  }
}
