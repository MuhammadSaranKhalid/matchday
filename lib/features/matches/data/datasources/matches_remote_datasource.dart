import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/ball_dto.dart';
import '../models/match_dto.dart';
import '../models/match_request_dto.dart';

/// Talks to Supabase for the `matches`, `balls`, and `match_requests`
/// tables. Returns DTOs / RPC result types, throws raw exceptions. RLS +
/// SECURITY DEFINER RPCs scope reads/writes.
class MatchesRemoteDataSource {
  MatchesRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _matches = 'matches';
  static const _balls = 'balls';

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  // ─── Matches ────────────────────────────────────────────────────────────

  Future<MatchDto> update(String id, Map<String, dynamic> changes) async {
    try {
      final row = await _supabase
          .from(_matches)
          .update(changes)
          .eq('match_id', id)
          .select()
          .single();
      return MatchDto.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException('Match $id not found');
      }
      throw ServerException(e.message);
    }
  }

  Future<MatchDto?> getById(String id) async {
    try {
      final row = await _supabase
          .from(_matches)
          .select()
          .eq('match_id', id)
          .maybeSingle();
      return row == null ? null : MatchDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// All matches visible to the user (RLS-scoped), newest first.
  Future<List<MatchDto>> list() async {
    try {
      final rows = await _supabase
          .from(_matches)
          .select()
          .order('created_at', ascending: false);
      return rows.map(MatchDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Match Start RPCs (deployed in migration 0623) ───────────────────────

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

  Future<void> startMatchNow(String matchId) async {
    try {
      await _supabase.rpc<void>('start_match_now', params: {
        'p_match_id': matchId,
      });
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  /// Subscribes to the `match:<id>:state` private broadcast channel.
  Stream<MatchDto?> watchMatch(String matchId) async* {
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
            final data =
                (payload['payload'] as Map<String, dynamic>?) ?? payload;
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

  // ─── Scoring RPCs (deployed in migration 0420 / 0410 / 0623) ─────────────

  Future<void> startInnings({
    required String matchId,
    required int inningsNumber,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  }) async {
    try {
      await _supabase.rpc<void>('start_innings', params: {
        'p_match_id': matchId,
        'p_innings_number': inningsNumber,
        'p_striker_id': strikerId,
        'p_non_striker_id': nonStrikerId,
        'p_bowler_id': bowlerId,
      });
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  /// `record_ball` returns the inserted balls row (the RPC's RETURN type).
  Future<BallDto> recordBall(Map<String, dynamic> params) async {
    try {
      final result = await _supabase.rpc<dynamic>('record_ball', params: params);
      if (result is Map) {
        return BallDto.fromJson(Map<String, dynamic>.from(result));
      }
      if (result is List && result.isNotEmpty) {
        return BallDto.fromJson(Map<String, dynamic>.from(result.first as Map));
      }
      throw ServerException('record_ball returned no row');
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<bool> undoLastBall({
    required String matchId,
    required int inningsNumber,
  }) async {
    try {
      final result = await _supabase.rpc<dynamic>(
        'undo_last_ball',
        params: {
          'p_match_id': matchId,
          'p_innings_number': inningsNumber,
        },
      );
      return result == true;
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  /// Initial-hydration GET for balls in (match, innings) — feeds the
  /// broadcast stream's first emission.
  Future<List<BallDto>> listBalls({
    required String matchId,
    required int inningsNumber,
  }) async {
    try {
      final rows = await _supabase
          .from(_balls)
          .select()
          .eq('match_id', matchId)
          .eq('innings_number', inningsNumber)
          .order('seq', ascending: true);
      return rows.map(BallDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Subscribes to the `match:<id>:balls` broadcast channel and emits the
  /// list of balls for `inningsNumber`, oldest-first, after each broadcast.
  Stream<List<BallDto>> watchBalls({
    required String matchId,
    required int inningsNumber,
  }) async* {
    // Initial hydration.
    var current = await listBalls(matchId: matchId, inningsNumber: inningsNumber);
    yield current;

    final controller = StreamController<List<BallDto>>();
    final channel = _supabase.channel(
      'match:$matchId:balls',
      opts: const RealtimeChannelConfig(self: true, private: true),
    );

    channel
        .onBroadcast(
          event: 'ball_recorded',
          callback: (payload) {
            final data =
                (payload['payload'] as Map<String, dynamic>?) ?? payload;
            try {
              final dto = BallDto.fromJson(data);
              if (dto.inningsNumber != inningsNumber) return;
              current = [...current, dto]..sort((a, b) => a.seq.compareTo(b.seq));
              controller.add(List.unmodifiable(current));
            } catch (e) {
              controller.addError(ServerException(e.toString()));
            }
          },
        )
        .onBroadcast(
          event: 'ball_deleted',
          callback: (payload) {
            final data =
                (payload['payload'] as Map<String, dynamic>?) ?? payload;
            final deletedId = data['ball_id'] as String?;
            if (deletedId == null) return;
            current = current.where((b) => b.ballId != deletedId).toList();
            controller.add(List.unmodifiable(current));
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

  /// Per-team innings aggregates for a set of matches. We pull all balls
  /// for the requested match ids in one query then bucket by
  /// (match_id, innings_number, batting team) — the batting team is
  /// derived from the match row, since balls only carry batsman_id.
  Future<List<BallDto>> listBallsForMatches(List<String> matchIds) async {
    if (matchIds.isEmpty) return const [];
    try {
      final rows = await _supabase
          .from(_balls)
          .select()
          .inFilter('match_id', matchIds);
      return rows.map(BallDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Match Requests (Challenge handshake — migration 0600) ───────────────

  Future<String> sendMatchChallenge(Map<String, dynamic> params) async {
    try {
      final result = await _supabase.rpc<dynamic>(
        'send_match_request',
        params: params,
      );
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

  /// Translate RPC PostgrestException codes into our own exceptions.
  Exception _rpcException(PostgrestException e) {
    if (e.code == '42501' || e.code == '28000') {
      return UnauthorizedException(e.message);
    }
    return ServerException(e.message);
  }

  /// Tag the auth-required guard on inserts that don't go through an RPC.
  /// Currently only used internally — kept to avoid unused-warning churn
  /// if a future helper needs it.
  // ignore: unused_element
  String _ensureAuthed() => _requireUid();
}
