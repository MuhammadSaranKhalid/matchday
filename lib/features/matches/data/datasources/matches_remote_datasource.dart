import 'dart:async';
import 'dart:io' show SocketException;

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/realtime/ably_service.dart';
import '../models/ball_dto.dart';
import '../models/match_dto.dart';
import '../models/match_innings_state_dto.dart';
import '../models/match_player_dto.dart';
import '../models/match_innings_dto.dart';
import '../models/match_wicket_dto.dart';

/// Talks to Supabase for the match-lifecycle tables — `matches`,
/// `match_players`, `match_innings_state`, and `match_deliveries` — plus the match-start
/// and scoring RPCs / `record-ball` edge function. Returns DTOs / RPC result
/// types, throws raw exceptions. RLS + SECURITY DEFINER RPCs scope
/// reads/writes.
///
/// The format catalog and the challenge handshake are NOT here — they're
/// separate concerns with their own data sources:
/// [FormatPresetsRemoteDataSource] and [MatchRequestsRemoteDataSource].
class MatchesRemoteDataSource {
  MatchesRemoteDataSource(this._supabase, this._ablyService);
  final SupabaseClient _supabase;
  final AblyService _ablyService;

  static const _matches = 'matches';
  static const _matchPlayers = 'match_players';

  /// `match_players` plus the identity of whoever the row points at.
  ///
  /// The row carries a XOR of (`profile_id`, `unclaimed_id`) and real FKs to
  /// both, so one embedded select resolves the name + avatar for every player
  /// in the XI. Doing it here — rather than looking names up against the team
  /// roster in the presentation layer — is what makes guests, substitutes and
  /// ex-roster players render correctly: they are in `match_players` but not
  /// on the roster, and used to come out as "Player 3f2a".
  ///
  /// `profiles` SELECT is public but filtered to `account_status = 'active'`,
  /// so the embed can still come back null for a suspended account. The DTO
  /// falls back accordingly.
  static const _matchPlayersSelect =
      '*, profile:profiles!user_id(display_name, username, profile_photo_url), '
      'unclaimed:unclaimed_players!unclaimed_id(display_name)';
  static const _matchInningsState = 'match_innings_state';
  static const _balls = 'match_deliveries';
  static const _matchInnings = 'match_innings';
  static const _wickets = 'match_wickets';
  static const _scorerLeases = 'match_scorer_leases';

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

  /// Matches the signed-in user actually participates in — they created it, a
  /// team they're a member of is playing, or they're an assigned official —
  /// newest first.
  /// Every match in [statuses], optionally windowed by scheduled start.
  ///
  /// A plain read, not `list_my_matches`: the Matches tab is the world's
  /// board, and `matches_read_all` is `using (true)`, so the whole fixture
  /// list is public. Narrowing it to the viewer is what the side panel does.
  Future<List<MatchDto>> listPublic({
    required Iterable<String> statuses,
    DateTime? from,
    DateTime? to,
    bool newestFirst = false,
    int limit = 200,
  }) async {
    try {
      var query = _supabase
          .from(_matches)
          .select()
          .inFilter('status', statuses.toList());
      if (from != null) {
        query = query.gte('scheduled_start_time', from.toIso8601String());
      }
      if (to != null) {
        query = query.lte('scheduled_start_time', to.toIso8601String());
      }
      final rows = await query
          .order('scheduled_start_time', ascending: !newestFirst)
          .limit(limit);
      return rows.map(MatchDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// The caller's own matches — created, captaining, on a roster, in an XI, or
  /// officiating. Scoped server-side by `list_my_matches`, because
  /// `matches_read_all` is `using (true)` and a plain select returns the
  /// world's fixtures.
  ///
  /// There used to be a `list-my-matches` EDGE FUNCTION fallback here. It was
  /// removed on 2026-09-06: the two implementations had drifted (the function
  /// ignored `team_members.status`, so removed members kept seeing a team's
  /// matches, and the two matched on different participant tables), which made
  /// the result set depend on whether the RPC or the fallback answered. The
  /// union of both definitions now lives in the RPC alone.
  Future<List<MatchDto>> list() async {
    try {
      final rows = await _supabase.rpc<List<dynamic>>('list_my_matches');
      return rows
          .map((row) =>
              MatchDto.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) rethrow;
      throw ServerException(e.toString());
    }
  }


  // ─── Match Start RPCs (deployed in migration 0623) ───────────────────────

  /// Runs a match-start RPC with timing and outcome on the `match.rpc`
  /// channel. These three calls are the whole write surface of the flow, so
  /// having every one of them timestamped is what makes a two-phone session
  /// reconstructable after the fact.
  Future<void> _startRpc(String name, Map<String, dynamic> params) async {
    try {
      await _supabase.rpc<void>(name, params: params);
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<void> recordTossWinner({
    required String matchId,
    required String wonBy,
    String? face,
  }) =>
      _startRpc('record_toss_winner', {
        'p_match_id': matchId,
        'p_won_by': wonBy,
        if (face != null) 'p_face': face,
      });

  Future<void> recordTossDecision({
    required String matchId,
    required String decision,
  }) =>
      _startRpc('record_toss_decision', {
        'p_match_id': matchId,
        'p_decision': decision,
      });

  Future<void> submitMatchOpeners({
    required String matchId,
    required String strikerId,
    required String nonStrikerId,
  }) =>
      _startRpc('submit_match_openers', {
        'p_match_id': matchId,
        'p_striker_id': strikerId,
        'p_non_striker_id': nonStrikerId,
      });

  Future<void> startMatchNow(String matchId) =>
      _startRpc('start_match_now', {'p_match_id': matchId});

  /// Whether the signed-in user may record deliveries for this innings.
  ///
  /// Delegates to the same rule the write path enforces, so the UI cannot
  /// drift from it.
  Future<bool> canScoreInnings({
    required String matchId,
    required int inningsNumber,
  }) async {
    try {
      final allowed = await _supabase.rpc<dynamic>('can_score_innings', params: {
        'p_match_id': matchId,
        'p_innings_number': inningsNumber,
      });
      return allowed == true;
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  /// Subscribes to the `match:<id>:state` private broadcast channel.
  ///
  /// Broadcast has no delivery guarantee and no queue: a frame that lands
  /// while the socket is down is gone. So the socket is treated as a latency
  /// optimisation, never as the transport — correctness comes from the
  /// snapshot re-fetch and the poll, which run whether or not realtime works.
  ///
  /// Four things feed the stream, all funnelled through [emit] so ordering
  /// and duplicates are handled once:
  ///
  ///  * an immediate snapshot, for first paint;
  ///  * [ReplayOption], which asks Supabase for messages this channel missed
  ///    (only works for `realtime.send()` messages — which is what the 0400
  ///    trigger uses);
  ///  * a snapshot on every `subscribed` transition, so each reconnect
  ///    re-syncs;
  ///  * a periodic snapshot, so a permanently broken socket is merely slow.
  Stream<MatchDto?> watchMatch(String matchId) {
    final controller = StreamController<MatchDto?>();
    var hasEmitted = false;
    MatchDto? last;
    var refreshing = false;

    // MatchDto is freezed, so `==` is a full value comparison. That makes
    // duplicate broadcasts, replayed frames and redundant polls free to drop.
    void emit(MatchDto? dto, String source) {
      if (hasEmitted && dto == last) return;
      hasEmitted = true;
      last = dto;
      if (!controller.isClosed) controller.add(dto);
    }

    Future<void> resnapshot(String reason) async {
      if (refreshing || controller.isClosed) return;
      refreshing = true;
      try {
        final dto = await getById(matchId);
        emit(dto, 'snapshot·$reason');
      } catch (e) {
        if (!hasEmitted && !controller.isClosed) {
          controller.addError(
            ServerException('Could not load match $matchId'),
          );
        }
      } finally {
        refreshing = false;
      }
    }

    final channelName = 'match:$matchId:state';
    final channel = _ablyService.getChannel(channelName);

    final subscription = channel.subscribe(name: 'match_state_updated').listen((ably.Message msg) {
      if (msg.data is Map) {
        try {
          final dto = MatchDto.fromJson(Map<String, dynamic>.from(msg.data as Map));
          emit(dto, 'live');
        } catch (_) {
          resnapshot('bad-frame');
        }
      }
    });

    // First paint snapshot
    unawaited(resnapshot('open'));

    controller.onCancel = () async {
      await subscription.cancel();
      await _ablyService.releaseChannel(channelName);
      await controller.close();
    };

    return controller.stream;
  }

  // ─── Scoring RPCs (deployed in migration 0420 / 0410 / 0623) ─────────────

  Future<void> startInnings({
    required String matchId,
    required int inningsNumber,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
    int? target,
  }) async {
    await _transport(() async {
      try {
        await _supabase.rpc<void>('start_innings', params: {
          'p_match_id': matchId,
          'p_innings_number': inningsNumber,
          'p_striker_id': strikerId,
          'p_non_striker_id': nonStrikerId,
          'p_bowler_id': bowlerId,
          if (target != null) 'p_target': target,
        });
      } on PostgrestException catch (e) {
        throw _rpcException(e);
      }
    });
  }

  // ─── match_players ───────────────────────────────────────────────────────

  /// List every match_players row for a match. Powers the Lineup screen,
  /// the bowler/batter/fielder pickers on the scoring screen, and any
  /// "who's on the field" UI on the spectator side.
  ///
  /// Match_players has no realtime broadcast in v1 — the table changes
  /// rarely (lineup-lock, mid-match substitutions). Callers that need to
  /// react to substitutions can re-fetch on the matches `match_state_updated`
  /// broadcast.
  Future<List<MatchPlayerDto>> listMatchPlayers(String matchId) async {
    try {
      final rows = await _supabase
          .from(_matchPlayers)
          .select(_matchPlayersSelect)
          .eq('match_id', matchId)
          .order('team_side', ascending: true)
          .order('batting_order', ascending: true, nullsFirst: false);
      return rows.map(MatchPlayerDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── match_innings_state ─────────────────────────────────────────────────

  /// One-shot fetch of the (match, innings) state row. Returns null if
  /// the innings hasn't been opened yet.
  Future<MatchInningsStateDto?> getMatchInningsState({
    required String matchId,
    required int inningsNumber,
  }) async {
    try {
      final row = await _supabase
          .from(_matchInningsState)
          .select()
          .eq('match_id', matchId)
          .eq('innings_number', inningsNumber)
          .maybeSingle();
      return row == null ? null : MatchInningsStateDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Subscribes to the `match:<id>:state` private broadcast channel for
  /// `innings_state_updated` events. Shares the channel topic with
  /// [watchMatch] but emits a different DTO, and carries the same
  /// replay / snapshot / poll resilience — see [watchMatch] for why.
  Stream<MatchInningsStateDto?> watchMatchInningsState({
    required String matchId,
    required int inningsNumber,
  }) {
    final controller = StreamController<MatchInningsStateDto?>();
    var hasEmitted = false;
    MatchInningsStateDto? last;
    var refreshing = false;

    void emit(MatchInningsStateDto? dto, String source) {
      if (hasEmitted && dto == last) return;
      hasEmitted = true;
      last = dto;
      if (!controller.isClosed) controller.add(dto);
    }

    Future<void> resnapshot(String reason) async {
      if (refreshing || controller.isClosed) return;
      refreshing = true;
      try {
        final dto = await getMatchInningsState(
          matchId: matchId,
          inningsNumber: inningsNumber,
        );
        emit(dto, 'snapshot·$reason');
      } catch (_) {
        if (!hasEmitted && !controller.isClosed) {
          controller.addError(
            ServerException('Could not load innings $inningsNumber'),
          );
        }
      } finally {
        refreshing = false;
      }
    }

    final channelName = 'match:$matchId:state';
    final channel = _ablyService.getChannel(channelName);

    final subscription = channel.subscribe(name: 'innings_state_updated').listen((ably.Message msg) {
      if (msg.data is Map) {
        try {
          final dto = MatchInningsStateDto.fromJson(Map<String, dynamic>.from(msg.data as Map));
          if (dto.inningsNumber == inningsNumber) {
            emit(dto, 'live');
          }
        } catch (_) {
          resnapshot('bad-frame');
        }
      }
    });

    unawaited(resnapshot('open'));

    controller.onCancel = () async {
      await subscription.cancel();
      await _ablyService.releaseChannel(channelName);
      await controller.close();
    };

    return controller.stream;
  }

  // ─── Ball recording ──────────────────────────────────────────────────────

  /// `record_ball` returns the inserted balls row (the RPC's RETURN type).
  /// Records a delivery through the `record-ball` edge function (the split
  /// scoring engine). The request body is the same `p_*` shape that fed the
  /// old `record_ball` RPC — only the transport changed. A `409` means the
  /// optimistic-lock version moved (another scorer committed first); it is
  /// surfaced as a [ConflictException] so the repo can map it to a benign
  /// retry rather than a hard error.
  /// Records a delivery and returns what the server made of it: the ball, and
  /// the innings row after it.
  ///
  /// [RecordBallResult.innings] is null against a deployment of the function
  /// that predates `returning *` on the innings update — the caller then falls
  /// back to the realtime broadcast, as it always used to.
  Future<RecordBallResult> recordBall(Map<String, dynamic> params) =>
      _transport(() async {
        try {
          final res =
              await _supabase.functions.invoke('record-ball', body: params);
          final data = res.data;
          final ball = data is Map ? data['ball'] : null;
          if (ball is Map) {
            final innings = data is Map ? data['innings'] : null;
            return RecordBallResult(
              ball: BallDto.fromJson(Map<String, dynamic>.from(ball)),
              innings: innings is Map
                  ? MatchInningsStateDto.fromJson(
                      Map<String, dynamic>.from(innings))
                  : null,
            );
          }
          throw ServerException('record-ball returned no ball row');
        } on FunctionException catch (e) {
          throw _functionException(e);
        }
      });

  Future<bool> undoLastBall({
    required String matchId,
    required int inningsNumber,
  }) =>
      _transport(() async {
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
      });

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
    final channelName = 'match:$matchId:balls';
    final channel = _ablyService.getChannel(channelName);

    final subRecorded = channel.subscribe(name: 'ball_recorded').listen((ably.Message msg) {
      if (msg.data is Map) {
        try {
          final dto = BallDto.fromJson(Map<String, dynamic>.from(msg.data as Map));
          if (dto.inningsNumber != inningsNumber) return;
          current = [...current, dto]..sort((a, b) => a.seq.compareTo(b.seq));
          controller.add(List.unmodifiable(current));
        } catch (e) {
          controller.addError(ServerException(e.toString()));
        }
      }
    });

    final subDeleted = channel.subscribe(name: 'ball_deleted').listen((ably.Message msg) {
      if (msg.data is Map) {
        final data = Map<String, dynamic>.from(msg.data as Map);
        final deletedId = (data['delivery_id'] ?? data['ball_id']) as String?;
        if (deletedId == null) return;
        current = current.where((b) => b.ballId != deletedId).toList();
        controller.add(List.unmodifiable(current));
      }
    });

    yield* controller.stream.asBroadcastStream(
      onCancel: (sub) async {
        await subRecorded.cancel();
        await subDeleted.cancel();
        await _ablyService.releaseChannel(channelName);
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

  /// Translate RPC PostgrestException codes into our own exceptions.
  /// Maps a failed RPC to our exception vocabulary.
  ///
  /// The match-start RPCs raise with deliberate SQLSTATEs and messages written
  /// for a developer reading a log, not for a captain standing on a pitch. The
  /// codes are stable, so they translate to sentences here rather than leaking
  /// `errcode` strings into a snackbar.
  /// True when the call never reached the server — DNS, socket, or timeout.
  ///
  /// This distinction is load-bearing for the scoring write path, not
  /// cosmetic. The repository queues an op for retry on a transport failure
  /// and marks it terminally refused on a server answer; conflating the two
  /// meant a rule violation was reported to the scorer as success and then
  /// retried forever. Mirrors the precedent in
  /// `messages_remote_datasource.dart`.
  static bool _isTransportFailure(Object e) =>
      e is SocketException || e is http.ClientException || e is TimeoutException;

  /// Wraps a call so transport failures surface as [NetworkException] while
  /// everything else keeps whatever the inner `on` clauses already threw.
  static Future<T> _transport<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      if (_isTransportFailure(e)) {
        throw NetworkException(
          e is SocketException ? e.message : 'No internet connection',
        );
      }
      rethrow;
    }
  }

  Exception _rpcException(PostgrestException e) {
    switch (e.code) {
      case '28000':
        return UnauthorizedException('Sign in again to continue.');
      case '42501':
        return UnauthorizedException(
          'Only the captains of these two teams can do this.',
        );
      case '23000':
      case '23514':
      case '23502':
        return ServerException(_startRuleMessage(e.message));
      default:
        return ServerException(e.message);
    }
  }

  /// The rule violations the match-start RPCs can raise, as written sentences.
  /// Falls through to the raw message for anything unrecognised — better a
  /// developer string than a silent failure.
  static String _startRuleMessage(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('toss cannot be changed') ||
        m.contains('toss can not be changed')) {
      return 'The openers are already locked, so the toss can no longer be '
          'changed.';
    }
    if (m.contains('already started') || m.contains('finalised')) {
      return 'This match has already started.';
    }
    if (m.contains('not in the batting xi') ||
        m.contains('must be in the batting xi')) {
      return 'Those openers are not in the batting XI. Pick them again.';
    }
    if (m.contains('openers must be locked')) {
      return 'Lock both openers before starting the match.';
    }
    if (m.contains('toss must be recorded')) {
      return 'Record the toss first.';
    }
    if (m.contains('must be different players')) {
      return 'The striker and non-striker have to be two different players.';
    }
    if (m.contains('toss winner must be one of')) {
      return 'Pick one of the two teams as the toss winner.';
    }
    if (m.contains('cannot record toss on a match in status')) {
      return 'This match has moved past the toss.';
    }
    return raw;
  }

  /// Maps a failed edge-function call to our exception vocabulary. The function
  /// returns a structured `{ ok:false, error:{ code, message } }` (or
  /// `{ conflict:true }`) body, surfaced on [FunctionException.details].
  Exception _functionException(FunctionException e) {
    final msg = _functionErrorMessage(e);

    switch (e.status) {
      case 409:
        // Since the version lock was removed (D12: the batting side owns its
        // innings), a 409 means the innings is not open for writing — never
        // started, or the match already closed. It is not a race to retry.
        return ConflictException(
          msg ?? 'This innings is not open for scoring.',
        );
      case 401:
      case 403:
        return UnauthorizedException(msg ?? 'Not allowed to score this match');
      case 404:
        // The function is not deployed on this project. Distinct from every
        // other failure because no amount of retrying fixes it — this bit us
        // on a fresh project where migrations were pushed but
        // `supabase functions deploy` had never been run.
        return ServerException(
          'Scoring is unavailable — the record-ball function is not deployed '
          'on this Supabase project.',
          statusCode: 404,
        );
      default:
        return ServerException(
          // Never a bare "failed": carry the status so the next person has
          // somewhere to start.
          msg ?? 'Could not record that ball (HTTP ${e.status}).',
          statusCode: e.status,
        );
    }
  }

  /// Digs the server's own message out of a [FunctionException].
  ///
  /// The edge functions return `{ ok:false, error:{ code, message } }`, but a
  /// failure that never reaches the handler — a 404, a boot error, a gateway
  /// timeout — puts a bare string or HTML in `details` instead. Both shapes
  /// have to be handled or the message silently becomes null.
  static String? _functionErrorMessage(FunctionException e) {
    final d = e.details;
    if (d is Map) {
      final err = d['error'];
      if (err is Map) return err['message']?.toString();
      if (err is String && err.isNotEmpty) return err;
      final m = d['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    if (d is String && d.isNotEmpty && !d.trimLeft().startsWith('<')) {
      return d;
    }
    return null;
  }

  // ─── Innings & Wickets ──────────────────────────────────────────────────

  /// The innings rows for a match, oldest-first.
  ///
  /// Deliveries carry an innings *number*; `match_wickets` is keyed by the
  /// innings *uuid*. This is the only way to get from one to the other.
  Future<List<MatchInningsDto>> listInnings(String matchId) async {
    try {
      final rows = await _supabase
          .from(_matchInnings)
          .select()
          .eq('match_id', matchId)
          .order('innings_number', ascending: true);
      return rows.map(MatchInningsDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<MatchWicketDto>> listWickets(String inningsId) async {
    try {
      final rows = await _supabase
          .from(_wickets)
          .select()
          .eq('innings_id', inningsId)
          .order('fall_of_wicket_number', ascending: true);
      return rows.map(MatchWicketDto.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Scorer Lease ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> acquireScorerLease({
    required String matchId,
    required String deviceId,
  }) async {
    try {
      final res = await _supabase.rpc<dynamic>(
        'acquire_scorer_lease',
        params: {
          'p_match_id': matchId,
          'p_device_id': deviceId,
        },
      );
      return res is Map ? Map<String, dynamic>.from(res) : {'acquired': false};
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<Map<String, dynamic>> heartbeatScorerLease({
    required String matchId,
    required String deviceId,
  }) async {
    try {
      final res = await _supabase.rpc<dynamic>(
        'heartbeat_scorer_lease',
        params: {
          'p_match_id': matchId,
          'p_device_id': deviceId,
        },
      );
      return res is Map ? Map<String, dynamic>.from(res) : {'valid': false};
    } on PostgrestException catch (e) {
      throw _rpcException(e);
    }
  }

  Future<Map<String, dynamic>?> getScorerLease(String matchId) async {
    try {
      final row = await _supabase
          .from(_scorerLeases)
          .select()
          .eq('match_id', matchId)
          .maybeSingle();
      return row;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Tag the auth-required guard on inserts that don't go through an RPC.
  /// Currently only used internally — kept to avoid unused-warning churn
  /// if a future helper needs it.
  // ignore: unused_element
  String _ensureAuthed() => _requireUid();
}

/// The two halves of a successful `record-ball` reply.
class RecordBallResult {
  const RecordBallResult({required this.ball, this.innings});
  final BallDto ball;
  final MatchInningsStateDto? innings;
}
