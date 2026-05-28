import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/ball_dto.dart';
import '../models/innings_dto.dart';
import '../models/match_dto.dart';
import '../models/match_request_dto.dart';

/// Talks to Supabase for the `matches` table. Returns DTOs, throws raw
/// exceptions. RLS scopes reads/writes.
class MatchesRemoteDataSource {
  MatchesRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'matches';

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  Future<MatchDto> create(Map<String, dynamic> payload) async {
    try {
      final row = await _supabase
          .from(_table)
          .insert({...payload, 'created_by': _requireUid()})
          .select()
          .single();
      return MatchDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<MatchDto> update(String id, Map<String, dynamic> changes) async {
    try {
      final row = await _supabase
          .from(_table)
          .update(changes)
          .eq('match_id', id)
          .select()
          .single();
      return MatchDto.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException('Match $id not found or already responded');
      }
      throw ServerException(e.message);
    }
  }

  Future<MatchDto?> getById(String id) async {
    try {
      final row =
          await _supabase.from(_table).select().eq('match_id', id).maybeSingle();
      return row == null ? null : MatchDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<InningsDto> createInnings(Map<String, dynamic> payload) async {
    try {
      final row =
          await _supabase.from('innings').insert(payload).select().single();
      return InningsDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Innings + balls (scoring) ──────────────────────────────────────────

  Future<InningsDto> updateInnings(
      String inningsId, Map<String, dynamic> changes) async {
    try {
      final row = await _supabase
          .from('innings')
          .update(changes)
          .eq('innings_id', inningsId)
          .select()
          .single();
      return InningsDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// The latest innings for a match (highest innings_number).
  Future<InningsDto?> getCurrentInnings(String matchId) async {
    try {
      final rows = await _supabase
          .from('innings')
          .select()
          .eq('match_id', matchId)
          .order('innings_number', ascending: false)
          .limit(1);
      return rows.isEmpty ? null : InningsDto.fromJson(rows.first);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<InningsDto?> getInnings(String inningsId) async {
    try {
      final row = await _supabase
          .from('innings')
          .select()
          .eq('innings_id', inningsId)
          .maybeSingle();
      return row == null ? null : InningsDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Insert one delivery; the DB trigger rolls it into the innings totals.
  Future<void> insertBall(Map<String, dynamic> payload) async {
    try {
      await _supabase.from('balls').insert({
        ...payload,
        'entered_by': _requireUid(),
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Stream<List<BallDto>> watchBalls(String inningsId) => _supabase
      .from('balls')
      .stream(primaryKey: ['ball_id'])
      .eq('innings_id', inningsId)
      .order('ball_id')
      .map((rows) => rows.map(BallDto.fromJson).toList());

  Stream<InningsDto?> watchInnings(String inningsId) => _supabase
      .from('innings')
      .stream(primaryKey: ['innings_id'])
      .eq('innings_id', inningsId)
      .map((rows) => rows.isEmpty ? null : InningsDto.fromJson(rows.first));

  /// Innings rows for a bounded set of match ids. One query rather than N.
  /// Returns the raw DTOs; the repository groups them by match.
  Future<List<InningsDto>> listInningsForMatches(List<String> matchIds) async {
    if (matchIds.isEmpty) return const [];
    try {
      final rows = await _supabase
          .from('innings')
          .select()
          .inFilter('match_id', matchIds);
      return rows.map(InningsDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Match Start RPCs (deployed in migration 0623) ──────────────────────

  /// Host phone records the toss outcome.
  Future<void> recordMatchToss({
    required String matchId,
    required String wonBy,
    required String decision,
    String? face,
  }) async {
    try {
      await _supabase.rpc<void>('record_match_toss', params: {
        'p_match_id': matchId,
        'p_won_by': wonBy,
        'p_decision': decision,
        if (face != null) 'p_face': face,
      });
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  /// Batting captain locks striker + non-striker.
  Future<void> submitMatchOpeners({
    required String matchId,
    required String strikerId,
    required String nonStrikerId,
  }) async {
    try {
      await _supabase.rpc<void>('submit_match_openers', params: {
        'p_match_id': matchId,
        'p_striker_id': strikerId,
        'p_non_striker_id': nonStrikerId,
      });
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  /// Batting captain tips the match into Live.
  Future<void> startMatchNow(String matchId) async {
    try {
      await _supabase.rpc<void>('start_match_now', params: {
        'p_match_id': matchId,
      });
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  /// Subscribes to the `match:<id>:state` private broadcast channel. The
  /// server-side `broadcast_match_state` trigger fires on every UPDATE; we
  /// emit a hydrated MatchDto each time. Also performs an initial GET so the
  /// caller sees the current row before any broadcast arrives.
  Stream<MatchDto?> watchMatch(String matchId) async* {
    // Initial hydration — broadcast only fires on UPDATE, not on subscribe.
    yield await getById(matchId);

    final controller = StreamController<MatchDto?>();
    final channel = _supabase.channel(
      'match:$matchId:state',
      opts: const RealtimeChannelConfig(self: true, private: true),
    );

    channel
        .onBroadcast(
          event: 'match_state_updated',
          callback: (payload) {
            // The trigger sends `to_jsonb(new)` as the payload — the row
            // shape, but realtime wraps it in `{payload: {...}}`.
            final data = (payload['payload'] as Map<String, dynamic>?) ?? payload;
            try {
              controller.add(MatchDto.fromJson(data));
            } catch (e) {
              controller.addError(ServerException(e.toString()));
            }
          },
        )
        .subscribe();

    yield* controller.stream.asBroadcastStream(
      onCancel: (sub) async {
        await _supabase.removeChannel(channel);
        await controller.close();
      },
    );
  }

  /// Translate RPC failures into our own exceptions. `42501` is the
  /// permission-check error our RPCs raise via `raise exception ... using
  /// errcode = '42501'`. Other codes route to ServerException.
  Exception _rpcException(PostgrestException e) {
    if (e.code == '42501' || e.code == '28000') {
      return UnauthorizedException(e.message);
    }
    if (e.code == '23502' || e.code == '23000' || e.code == '23514') {
      return ServerException(e.message);
    }
    return ServerException(e.message);
  }

  // ─── Match Requests (Challenge handshake — deployed via migration 0600) ──

  Future<String> sendMatchChallenge(Map<String, dynamic> params) async {
    try {
      final result = await _supabase.rpc<dynamic>(
        'send_match_request',
        params: params,
      );
      // RPC returns the new request_id as a string-typed uuid.
      if (result is String) return result;
      if (result is List && result.isNotEmpty) return result.first.toString();
      throw ServerException('send_match_request returned no id');
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<String?> acceptMatchChallenge(Map<String, dynamic> params) async {
    try {
      final result = await _supabase.rpc<dynamic>(
        'accept_match_request',
        params: params,
      );
      if (result is String) return result;
      if (result is List && result.isNotEmpty) return result.first.toString();
      return null;
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<void> counterMatchChallenge(Map<String, dynamic> params) async {
    try {
      await _supabase.rpc<void>('counter_match_request', params: params);
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<void> declineMatchChallenge(Map<String, dynamic> params) async {
    try {
      await _supabase.rpc<void>('decline_match_request', params: params);
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<void> withdrawMatchChallenge(Map<String, dynamic> params) async {
    try {
      await _supabase.rpc<void>('cancel_match_request', params: params);
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<MatchRequestDto?> getMatchChallenge(String requestId) async {
    try {
      final row = await _supabase
          .from('match_requests')
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

  /// All match_requests the caller can read (manager-of-either-team RLS).
  /// One-shot fetch — realtime updates ride the user:notifications broadcast
  /// channel, which invalidates the caller's list provider.
  Future<List<MatchRequestDto>> listMyMatchChallenges() async {
    try {
      final rows = await _supabase
          .from('match_requests')
          .select()
          .order('created_at', ascending: false);
      return rows.map(MatchRequestDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// All matches visible to the user (RLS-scoped), newest first.
  Future<List<MatchDto>> list() async {
    try {
      final rows =
          await _supabase.from(_table).select().order('created_at', ascending: false);
      return rows.map(MatchDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
