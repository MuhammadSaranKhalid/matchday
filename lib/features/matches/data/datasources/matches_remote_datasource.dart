import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/log/ck_log.dart';
import '../models/ball_dto.dart';
import '../models/match_dto.dart';
import '../models/match_innings_state_dto.dart';
import '../models/match_player_dto.dart';

/// Talks to Supabase for the match-lifecycle tables — `matches`,
/// `match_players`, `match_innings_state`, and `balls` — plus the match-start
/// and scoring RPCs / `record-ball` edge function. Returns DTOs / RPC result
/// types, throws raw exceptions. RLS + SECURITY DEFINER RPCs scope
/// reads/writes.
///
/// The format catalog and the challenge handshake are NOT here — they're
/// separate concerns with their own data sources:
/// [FormatPresetsRemoteDataSource] and [MatchRequestsRemoteDataSource].
class MatchesRemoteDataSource {
  MatchesRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

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
      '*, profile:profiles!profile_id(display_name, username, profile_photo_url), '
      'unclaimed:unclaimed_players!unclaimed_id(display_name)';
  static const _matchInningsState = 'match_innings_state';
  static const _balls = 'match_deliveries';

  // ─── Realtime resilience knobs ──────────────────────────────────────────
  // See [watchMatch] for why these exist. Tuned for the match-start flow,
  // where a stalled screen means two captains standing on a pitch waiting.

  /// How far back Supabase is asked to replay on (re)subscribe. Long enough
  /// to cover a dropped socket, short enough to stay inside the ~72h that
  /// `realtime.messages` retains.
  static const _replayWindow = Duration(minutes: 10);

  /// Server-side maximum is 25.
  static const _replayLimit = 25;

  /// Snapshot cadence. The backstop that makes a dead socket slow, not fatal.
  static const _pollInterval = Duration(seconds: 15);

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  /// Broadcast payloads arrive wrapped as `{event, payload: {...}}` from
  /// `realtime.send()`, but bare from some paths. Accept both.
  static Map<String, dynamic> _unwrapBroadcast(Map<String, dynamic> payload) =>
      (payload['payload'] as Map<String, dynamic>?) ?? payload;

  /// True when Supabase re-delivered this frame via Broadcast Replay rather
  /// than it arriving live. Diagnostic only — both are applied identically.
  static bool _wasReplayed(Map<String, dynamic> payload) {
    final meta = payload['meta'];
    return meta is Map && meta['replayed'] == true;
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
  Future<List<MatchDto>> list() async {
    try {
      final rows = await _supabase.rpc<List<dynamic>>('list_my_matches');
      return rows
          .map((row) =>
              MatchDto.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      // Fallback to edge function if RPC not present in older migrations
      try {
        final res = await _supabase.functions.invoke('list-my-matches');
        final data = res.data;
        final rows = data is Map ? data['matches'] : data;
        if (rows is! List) {
          throw ServerException(e.message);
        }
        return rows
            .map((row) =>
                MatchDto.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList();
      } catch (_) {
        throw _rpcException(e);
      }
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
    final sw = Stopwatch()..start();
    CkLog.write(CkLogChannel.rpc, '$name·call', data: params);
    try {
      await _supabase.rpc<void>(name, params: params);
      CkLog.write(CkLogChannel.rpc, '$name·ok', data: {'took': sw.elapsed});
    } on PostgrestException catch (e) {
      // The SQLSTATE is the part worth seeing — 42501 is an authorisation
      // problem, 23000 a rule violation, and they need different responses.
      CkLog.warn(CkLogChannel.rpc, '$name·fail', data: {
        'took': sw.elapsed,
        'code': e.code,
        'msg': e.message,
      });
      throw _rpcException(e);
    }
  }

  Future<void> recordMatchToss({
    required String matchId,
    required String wonBy,
    required String decision,
    String? face,
  }) =>
      _startRpc('record_match_toss', {
        'p_match_id': matchId,
        'p_won_by': wonBy,
        'p_decision': decision,
        if (face != null) 'p_face': face,
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
      if (hasEmitted && dto == last) {
        // Worth seeing: a dropped frame here is the dedup working, and its
        // absence is how you spot the socket delivering nothing at all.
        CkLog.write(CkLogChannel.realtime, 'dedup·drop',
            data: {'match': matchId, 'via': source});
        return;
      }
      hasEmitted = true;
      last = dto;
      CkLog.write(CkLogChannel.realtime, 'emit', data: {
        'match': matchId,
        'via': source,
        'phase': dto?.startPhase,
        'status': dto?.status,
      });
      if (!controller.isClosed) controller.add(dto);
    }

    Future<void> resnapshot(String reason) async {
      if (refreshing || controller.isClosed) return;
      refreshing = true;
      final sw = Stopwatch()..start();
      try {
        final dto = await getById(matchId);
        CkLog.write(CkLogChannel.realtime, 'snapshot',
            data: {'match': matchId, 'why': reason, 'took': sw.elapsed});
        emit(dto, 'snapshot·$reason');
      } catch (e, st) {
        // A failed refresh is never fatal — the next trigger retries. Only
        // surface an error if we have nothing at all to show yet.
        CkLog.warn(CkLogChannel.realtime, 'snapshot·fail',
            data: {'match': matchId, 'why': reason, 'took': sw.elapsed},
            error: e, stackTrace: st);
        if (!hasEmitted && !controller.isClosed) {
          controller.addError(
            ServerException('Could not load match $matchId'),
          );
        }
      } finally {
        refreshing = false;
      }
    }

    final channel = _supabase.channel(
      'match:$matchId:state',
      opts: RealtimeChannelConfig(
        self: true,
        private: true,
        replay: ReplayOption(
          since: DateTime.now()
              .subtract(_replayWindow)
              .millisecondsSinceEpoch,
          limit: _replayLimit,
        ),
      ),
    );

    CkLog.write(CkLogChannel.realtime, 'subscribe', data: {
      'match': matchId,
      'replay': '${_replayWindow.inMinutes}m/$_replayLimit',
    });

    channel
        .onBroadcast(
          event: 'match_state_updated',
          callback: (payload) {
            try {
              // `meta.replayed` marks a frame Supabase re-delivered rather
              // than one that arrived live — the difference between "the
              // socket is working" and "the socket dropped and recovered".
              final replayed = _wasReplayed(payload);
              CkLog.write(CkLogChannel.realtime, 'broadcast',
                  data: {'match': matchId, 'replayed': replayed});
              emit(
                MatchDto.fromJson(_unwrapBroadcast(payload)),
                replayed ? 'replay' : 'live',
              );
            } catch (e, st) {
              // Malformed frame — fall back to the row rather than erroring
              // out a stream the whole screen depends on.
              CkLog.warn(CkLogChannel.realtime, 'broadcast·bad',
                  data: {'match': matchId}, error: e, stackTrace: st);
              resnapshot('bad-frame');
            }
          },
        )
        .subscribe((status, error) {
          CkLog.write(CkLogChannel.realtime, 'channel',
              data: {'match': matchId, 'status': status.name, 'err': error});
          // Fires on the first connect AND on every reconnect.
          if (status == RealtimeSubscribeStatus.subscribed) {
            resnapshot('subscribed');
          }
        });

    // First paint. Not awaited: if the channel never reaches `subscribed`
    // (auth failure, dead socket) this is the only thing that paints.
    unawaited(resnapshot('open'));

    final poll = Timer.periodic(_pollInterval, (_) => resnapshot('poll'));

    controller.onCancel = () async {
      CkLog.write(CkLogChannel.realtime, 'close', data: {'match': matchId});
      poll.cancel();
      await _supabase.removeChannel(channel);
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
      if (hasEmitted && dto == last) {
        CkLog.write(CkLogChannel.realtime, 'dedup·drop',
            data: {'match': matchId, 'inns': inningsNumber, 'via': source});
        return;
      }
      hasEmitted = true;
      last = dto;
      CkLog.write(CkLogChannel.realtime, 'emit·inns', data: {
        'match': matchId,
        'inns': inningsNumber,
        'via': source,
        'striker': dto?.strikerId,
        'nonStriker': dto?.nonStrikerId,
        'ver': dto?.version,
      });
      if (!controller.isClosed) controller.add(dto);
    }

    Future<void> resnapshot(String reason) async {
      if (refreshing || controller.isClosed) return;
      refreshing = true;
      final sw = Stopwatch()..start();
      try {
        final dto = await getMatchInningsState(
          matchId: matchId,
          inningsNumber: inningsNumber,
        );
        CkLog.write(CkLogChannel.realtime, 'snapshot·inns', data: {
          'match': matchId,
          'inns': inningsNumber,
          'why': reason,
          'took': sw.elapsed,
        });
        emit(dto, 'snapshot·$reason');
      } catch (e, st) {
        CkLog.warn(CkLogChannel.realtime, 'snapshot·inns·fail',
            data: {'match': matchId, 'inns': inningsNumber, 'why': reason},
            error: e, stackTrace: st);
        if (!hasEmitted && !controller.isClosed) {
          controller.addError(
            ServerException('Could not load innings $inningsNumber'),
          );
        }
      } finally {
        refreshing = false;
      }
    }

    final channel = _supabase.channel(
      'match:$matchId:state',
      opts: RealtimeChannelConfig(
        self: true,
        private: true,
        replay: ReplayOption(
          since: DateTime.now()
              .subtract(_replayWindow)
              .millisecondsSinceEpoch,
          limit: _replayLimit,
        ),
      ),
    );

    channel
        .onBroadcast(
          event: 'innings_state_updated',
          callback: (payload) {
            try {
              final replayed = _wasReplayed(payload);
              final dto =
                  MatchInningsStateDto.fromJson(_unwrapBroadcast(payload));
              // The topic carries every innings; ignore the others.
              if (dto.inningsNumber != inningsNumber) {
                CkLog.write(CkLogChannel.realtime, 'broadcast·other', data: {
                  'match': matchId,
                  'want': inningsNumber,
                  'got': dto.inningsNumber,
                });
                return;
              }
              CkLog.write(CkLogChannel.realtime, 'broadcast·inns', data: {
                'match': matchId,
                'inns': inningsNumber,
                'replayed': replayed,
              });
              emit(dto, replayed ? 'replay' : 'live');
            } catch (e, st) {
              CkLog.warn(CkLogChannel.realtime, 'broadcast·inns·bad',
                  data: {'match': matchId}, error: e, stackTrace: st);
              resnapshot('bad-frame');
            }
          },
        )
        .subscribe((status, error) {
          CkLog.write(CkLogChannel.realtime, 'channel·inns', data: {
            'match': matchId,
            'inns': inningsNumber,
            'status': status.name,
            'err': error,
          });
          if (status == RealtimeSubscribeStatus.subscribed) {
            resnapshot('subscribed');
          }
        });

    unawaited(resnapshot('open'));

    final poll = Timer.periodic(_pollInterval, (_) => resnapshot('poll'));

    controller.onCancel = () async {
      CkLog.write(CkLogChannel.realtime, 'close·inns',
          data: {'match': matchId, 'inns': inningsNumber});
      poll.cancel();
      await _supabase.removeChannel(channel);
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
  Future<RecordBallResult> recordBall(Map<String, dynamic> params) async {
    final sw = Stopwatch()..start();
    CkLog.write(CkLogChannel.rpc, 'record-ball·call', data: {
      'match': params['p_match_id'],
      'inns': params['p_innings_number'],
      'runs': params['p_runs_scored'],
      'extras': params['p_extras'],
      'wicket': params['p_is_wicket'],
      'ver': params['p_expected_version'],
    });
    try {
      final res = await _supabase.functions.invoke('record-ball', body: params);
      final data = res.data;
      final ball = data is Map ? data['ball'] : null;
      if (ball is Map) {
        final innings = data is Map ? data['innings'] : null;
        CkLog.write(CkLogChannel.rpc, 'record-ball·ok', data: {
          'took': sw.elapsed,
          // Whether the reply carried the new score, or we still have to wait
          // for the broadcast. Worth seeing in a field log.
          'inline': innings is Map,
        });
        return RecordBallResult(
          ball: BallDto.fromJson(Map<String, dynamic>.from(ball)),
          innings: innings is Map
              ? MatchInningsStateDto.fromJson(
                  Map<String, dynamic>.from(innings))
              : null,
        );
      }
      // A 200 with the wrong shape — the function ran but returned something
      // unexpected. Log the body; the shape is the whole diagnosis.
      CkLog.warn(CkLogChannel.rpc, 'record-ball·shape', data: {
        'took': sw.elapsed,
        'body': data?.toString(),
      });
      throw ServerException('record-ball returned no ball row');
    } on FunctionException catch (e) {
      throw _functionException(e);
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

  /// Translate RPC PostgrestException codes into our own exceptions.
  /// Maps a failed RPC to our exception vocabulary.
  ///
  /// The match-start RPCs raise with deliberate SQLSTATEs and messages written
  /// for a developer reading a log, not for a captain standing on a pitch. The
  /// codes are stable, so they translate to sentences here rather than leaking
  /// `errcode` strings into a snackbar.
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

    CkLog.warn(CkLogChannel.rpc, 'record-ball·fail', data: {
      'status': e.status,
      'msg': msg,
      'details': e.details?.toString(),
    });

    switch (e.status) {
      case 409:
        return ConflictException(
          msg ?? 'Another scorer just updated this innings — refresh and retry',
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
