import 'dart:async';
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/supabase/current_user_x.dart';
import '../models/chat_dto.dart';
import '../models/message_dto.dart';
import 'messages_local_datasource.dart';

/// Talks to Supabase for the chat inbox + threads, AND writes through to the
/// local cache after every in-memory mutation (patch on broadcast / own-send
/// / reconnect resync). Per CLAUDE.md Rule 2 returns DTOs / throws raw
/// exceptions.
///
/// Cache writes are fire-and-forget — failures stay inside the data layer
/// and are not propagated to the UI. The cache is a cold-start optimisation,
/// not a source of truth; a failed cache write means the next cold-start
/// renders the previous cached value until the network fetch overlays.
///
/// Per-stream state lives on the class (`_inboxController` + `_inboxCurrent`
/// for the inbox; `_threads[chatId]` for per-chat threads). Riverpod's
/// keepAlive on the inbox + thread family providers means each `watch*`
/// method is called at most once per session per scope, so the state model
/// is single-owner. The `onCancel` callback clears state defensively.
class MessagesRemoteDataSource {
  MessagesRemoteDataSource(this._supabase, this._local);
  final SupabaseClient _supabase;
  final MessagesLocalDataSource _local;

  // ─── Inbox state ──────────────────────────────────────────────────────
  StreamController<List<ChatDto>>? _inboxController;
  List<ChatDto>? _inboxCurrent;

  /// Guard against a thundering herd of `_resyncInbox` calls when a burst of
  /// `chat_updated` broadcasts arrives for one or more unknown chats in the
  /// same microtask batch. Without this, N broadcasts in flight = N
  /// concurrent edge-fn round-trips (ticket #28).
  bool _inboxResyncing = false;

  // ─── Per-thread state (keyed by chatId) ───────────────────────────────
  final Map<String, _ThreadState> _threads = {};

  // ═══════════════════════════════════════════════════════════════════════
  // Inbox
  // ═══════════════════════════════════════════════════════════════════════

  /// One-shot inbox fetch via the `list-my-chats` edge function.
  Future<List<ChatDto>> listMyChats() async {
    try {
      final res = await _supabase.functions.invoke('list-my-chats');
      final data = res.data;
      final rows = data is Map ? data['chats'] : data;
      if (rows is! List) {
        throw ServerException('list-my-chats returned an unexpected payload');
      }
      return rows
          .map((row) =>
              ChatDto.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on FunctionException catch (e) {
      throw _functionException(e);
    }
  }

  /// Streams the inbox. Yields the initial fetch, then patches in-memory on
  /// each `chat_updated` broadcast from `user:<uid>:notifications` (fired by
  /// migration 0802's `broadcast_new_message` trigger; the sender is
  /// excluded by that trigger, so own-sends go via `_patchInboxForOwnSend`).
  ///
  /// On reconnect (channel re-subscribes after a network drop), do a full
  /// re-fetch + bulk cache replace as a sync point — Supabase realtime is
  /// at-most-once, so events fired during disconnect would otherwise be lost.
  Stream<List<ChatDto>> watchMyChats() async* {
    final uid = _supabase.requireUid();

    final initial = await listMyChats();
    _inboxCurrent = initial;
    yield initial;

    // Initial bulk cache replace (covers users who just signed in or whose
    // cache went stale).
    _writeCacheBulkChats(initial);

    final controller = StreamController<List<ChatDto>>();
    _inboxController = controller;

    final channel = _supabase.channel(
      'user:$uid:notifications',
      opts: const RealtimeChannelConfig(self: true, private: true),
    );

    var subscribedOnce = false;
    channel
        .onBroadcast(
          event: 'chat_updated',
          callback: (payload) => _onChatUpdated(payload, uid),
        )
        .subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        if (subscribedOnce) {
          // Reconnect — full re-fetch as sync point.
          await _resyncInbox(uid);
        }
        subscribedOnce = true;
      }
    });

    yield* controller.stream.asBroadcastStream(
      onCancel: (_) async {
        if (identical(_inboxController, controller)) {
          _inboxController = null;
          _inboxCurrent = null;
        }
        await _supabase.removeChannel(channel);
        await controller.close();
      },
    );
  }

  void _onChatUpdated(Map<String, dynamic> payload, String uid) {
    final data =
        (payload['payload'] as Map<String, dynamic>?) ?? payload;
    final chatId = data['chat_id'] as String?;
    if (chatId == null) return;

    final current = _inboxCurrent;
    final controller = _inboxController;
    if (current == null || controller == null || controller.isClosed) return;

    final idx = current.indexWhere((c) => c.chatId == chatId);
    if (idx == -1) {
      // Unknown chat — likely a new team I just got added to. Fall back to
      // a full re-fetch which will surface the new chat AND any I haven't
      // seen yet. Guarded so a burst of broadcasts for the same unknown
      // chat triggers at most one re-fetch (ticket #28).
      if (!_inboxResyncing) {
        _inboxResyncing = true;
        unawaited(
          _resyncInbox(uid).whenComplete(() => _inboxResyncing = false),
        );
      }
      return;
    }

    final old = current[idx];
    final patched = old.copyWith(
      lastMessageAt: data['created_at'] as String?,
      lastMessageBody: data['body_preview'] as String?,
      lastMessageSenderId: data['sender_id'] as String?,
      // Trigger excludes the sender, so any chat_updated we receive is from
      // someone else — increment unread.
      lastMessageFromMe: false,
      unreadCount: old.unreadCount + 1,
    );

    final next = [...current.take(idx), patched, ...current.skip(idx + 1)]
      ..sort(_byLastMessageDesc);
    _inboxCurrent = next;
    controller.add(List.unmodifiable(next));

    _writeCacheChat(patched);
  }

  Future<void> _resyncInbox(String uid) async {
    try {
      final fresh = await listMyChats();
      _inboxCurrent = fresh;
      final controller = _inboxController;
      if (controller != null && !controller.isClosed) {
        controller.add(List.unmodifiable(fresh));
      }
      _writeCacheBulkChats(fresh);
    } on SocketException catch (e) {
      _surfaceInboxError(NetworkException(e.message));
    } catch (e) {
      _surfaceInboxError(ServerException(e.toString()));
    }
  }

  void _surfaceInboxError(Exception ex) {
    final controller = _inboxController;
    if (controller != null && !controller.isClosed) {
      controller.addError(ex);
    }
  }

  /// After my own `sendMessage` succeeds, patch the inbox locally. The
  /// `chat_updated` trigger excludes the sender so no broadcast arrives;
  /// without this the sender's inbox would not bump until someone else
  /// posts in the same chat.
  void _patchInboxForOwnSend(MessageDto sent) {
    final current = _inboxCurrent;
    final controller = _inboxController;
    if (current == null || controller == null || controller.isClosed) return;

    final idx = current.indexWhere((c) => c.chatId == sent.chatId);
    if (idx == -1) return;

    // Truncate to 160 chars to match the trigger's `body_preview` shape.
    final preview = sent.body.length > 160
        ? sent.body.substring(0, 160)
        : sent.body;
    final old = current[idx];
    final patched = old.copyWith(
      lastMessageAt: sent.createdAt,
      lastMessageBody: preview,
      lastMessageSenderId: sent.senderId,
      lastMessageFromMe: true,
      // unreadCount unchanged — sender doesn't generate unread for self.
    );

    final next = [...current.take(idx), patched, ...current.skip(idx + 1)]
      ..sort(_byLastMessageDesc);
    _inboxCurrent = next;
    controller.add(List.unmodifiable(next));

    _writeCacheChat(patched);
  }

  /// markRead patches both stores: clears the unread badge locally without
  /// waiting for the next broadcast.
  void _patchInboxForMarkRead(String chatId) {
    final current = _inboxCurrent;
    final controller = _inboxController;
    if (current == null || controller == null || controller.isClosed) return;

    final idx = current.indexWhere((c) => c.chatId == chatId);
    if (idx == -1 || current[idx].unreadCount == 0) return;

    final patched = current[idx].copyWith(unreadCount: 0);
    // last_message_at unchanged, so sort order is preserved.
    final next = [...current.take(idx), patched, ...current.skip(idx + 1)];
    _inboxCurrent = next;
    controller.add(List.unmodifiable(next));

    _writeCacheChat(patched);
  }

  static int _byLastMessageDesc(ChatDto a, ChatDto b) {
    final ta = a.lastMessageAt;
    final tb = b.lastMessageAt;
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    return tb.compareTo(ta);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Thread
  // ═══════════════════════════════════════════════════════════════════════

  static const _messages = 'messages';
  static const _chatMembers = 'chat_members';

  static const _messageSelect =
      'message_id, chat_id, sender_id, body, created_at, edited_at, deleted_at, '
      'sender:profiles(display_name)';

  /// Flatten the nested `sender.display_name` into a top-level
  /// `sender_display_name` field and stamp `from_me` against the current
  /// user — both expected by [MessageDto].
  MessageDto _dtoFromRow(Map<String, dynamic> row, String uid) {
    final flat = Map<String, dynamic>.from(row);
    final sender = flat['sender'];
    if (sender is Map) {
      flat['sender_display_name'] = sender['display_name'];
    }
    flat['from_me'] = flat['sender_id'] == uid;
    return MessageDto.fromJson(flat);
  }

  /// One-shot list of all non-deleted messages in a chat, oldest first.
  Future<List<MessageDto>> listMessages(String chatId) async {
    final uid = _supabase.requireUid();
    try {
      final rows = await _supabase
          .from(_messages)
          .select(_messageSelect)
          .eq('chat_id', chatId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: true);
      return rows
          .map((row) => _dtoFromRow(Map<String, dynamic>.from(row), uid))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Streams messages in a chat. Yields the initial list, then patches
  /// in-memory on each `new_message` broadcast. The broadcast payload
  /// includes the full body + sender_id but NOT the sender's display name —
  /// we cache display names from the initial fetch and look up on broadcast;
  /// unknown senders fall back to a single-row fetch with the profile embed.
  ///
  /// On reconnect, full re-fetch + bulk cache replace as a sync point.
  Stream<List<MessageDto>> watchMessages(String chatId) async* {
    final uid = _supabase.requireUid();

    final initial = await listMessages(chatId);

    // Build sender-name cache from the initial fetch.
    final senderNames = <String, String?>{};
    for (final m in initial) {
      if (m.senderId != null) {
        senderNames[m.senderId!] = m.senderDisplayName;
      }
    }

    yield initial;
    _writeCacheBulkMessages(chatId, initial);

    final controller = StreamController<List<MessageDto>>();
    final state = _ThreadState(
      controller: controller,
      current: initial,
      senderNames: senderNames,
    );
    _threads[chatId] = state;

    final channel = _supabase.channel(
      'chat:$chatId:messages',
      opts: const RealtimeChannelConfig(self: true, private: true),
    );

    var subscribedOnce = false;
    channel
        .onBroadcast(
          event: 'new_message',
          // `unawaited` makes the fire-and-forget dispatch explicit —
          // `_onNewMessage` is async and may await a cache-miss row fetch.
          // Errors inside `_onNewMessage` are caught and surfaced via the
          // controller; nothing escapes here (ticket #28).
          callback: (payload) =>
              unawaited(_onNewMessage(chatId, payload, uid)),
        )
        .subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        if (subscribedOnce) {
          await _resyncThread(chatId, uid);
        }
        subscribedOnce = true;
      }
    });

    yield* controller.stream.asBroadcastStream(
      onCancel: (_) async {
        if (identical(_threads[chatId]?.controller, controller)) {
          _threads.remove(chatId);
        }
        await _supabase.removeChannel(channel);
        await controller.close();
      },
    );
  }

  Future<void> _onNewMessage(
    String chatId,
    Map<String, dynamic> payload,
    String uid,
  ) async {
    final state = _threads[chatId];
    if (state == null || state.controller.isClosed) return;

    final data =
        (payload['payload'] as Map<String, dynamic>?) ?? payload;
    final messageId = data['message_id'] as String?;
    if (messageId == null) return;

    // Dedup — covers the own-send case where `sendMessage` already appended
    // the row before the broadcast echoes back.
    if (state.current.any((m) => m.messageId == messageId)) return;

    final senderId = data['sender_id'] as String?;
    final body = data['body'] as String?;
    final createdAt = data['created_at'] as String?;
    if (body == null || createdAt == null) return;

    MessageDto dto;
    if (senderId != null && state.senderNames.containsKey(senderId)) {
      // Cache hit — build directly from broadcast payload, zero round-trips.
      dto = MessageDto(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        senderDisplayName: state.senderNames[senderId],
        body: body,
        createdAt: createdAt,
        fromMe: senderId == uid,
      );
    } else {
      // Cache miss (new sender — someone just joined the team) — fall back
      // to a single-row fetch with the profile embed.
      try {
        final row = await _supabase
            .from(_messages)
            .select(_messageSelect)
            .eq('message_id', messageId)
            .filter('deleted_at', 'is', null)
            .maybeSingle();
        if (row == null) return;
        dto = _dtoFromRow(Map<String, dynamic>.from(row), uid);
        if (dto.senderId != null) {
          state.senderNames[dto.senderId!] = dto.senderDisplayName;
        }
      } on SocketException catch (e) {
        if (!state.controller.isClosed) {
          state.controller.addError(NetworkException(e.message));
        }
        return;
      } catch (e) {
        if (!state.controller.isClosed) {
          state.controller.addError(ServerException(e.toString()));
        }
        return;
      }
    }

    // Re-check dedup AFTER the await — two concurrent broadcasts for the
    // same message_id could both have passed the initial dedup check
    // because `state.current` hadn't been mutated yet. Also re-check that
    // the state + controller are still alive (the screen may have been
    // closed while we awaited the cache-miss fetch). Ticket #28.
    if (state.controller.isClosed) return;
    if (state.current.any((m) => m.messageId == messageId)) return;

    state.current = [...state.current, dto];
    if (!state.controller.isClosed) {
      state.controller.add(List.unmodifiable(state.current));
    }
    _writeCacheMessage(dto);
  }

  Future<void> _resyncThread(String chatId, String uid) async {
    final state = _threads[chatId];
    if (state == null) return;
    try {
      final fresh = await listMessages(chatId);
      state.current = fresh;
      state.senderNames.clear();
      for (final m in fresh) {
        if (m.senderId != null) {
          state.senderNames[m.senderId!] = m.senderDisplayName;
        }
      }
      if (!state.controller.isClosed) {
        state.controller.add(List.unmodifiable(fresh));
      }
      _writeCacheBulkMessages(chatId, fresh);
    } on SocketException catch (e) {
      if (!state.controller.isClosed) {
        state.controller.addError(NetworkException(e.message));
      }
    } catch (e) {
      if (!state.controller.isClosed) {
        state.controller.addError(ServerException(e.toString()));
      }
    }
  }

  /// Insert a message authored by the current user, returning the row with
  /// sender_display_name resolved + from_me=true. Patches the inbox + cache
  /// AND appends to the open thread + cache (the broadcast echo for our own
  /// message arrives shortly after and is deduped by message_id).
  Future<MessageDto> sendMessage({
    required String chatId,
    required String body,
  }) async {
    final uid = _supabase.requireUid();
    try {
      final row = await _supabase
          .from(_messages)
          .insert({
            'chat_id': chatId,
            'sender_id': uid,
            'body': body,
          })
          .select(_messageSelect)
          .single();
      final dto = _dtoFromRow(Map<String, dynamic>.from(row), uid);

      // (1) Append to the open thread immediately so the user sees their
      // own message without waiting for the broadcast echo.
      final thread = _threads[chatId];
      if (thread != null &&
          !thread.controller.isClosed &&
          !thread.current.any((m) => m.messageId == dto.messageId)) {
        thread.current = [...thread.current, dto];
        thread.controller.add(List.unmodifiable(thread.current));
        if (dto.senderId != null) {
          thread.senderNames[dto.senderId!] = dto.senderDisplayName;
        }
      }
      _writeCacheMessage(dto);

      // (2) Patch the inbox (trigger excludes the sender from chat_updated).
      _patchInboxForOwnSend(dto);

      return dto;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Stamp `chat_members.last_read_at = now()` for (chat, me). Allowed by
  /// the `chat_members_update_self_or_admin` policy. Patches the inbox +
  /// cache locally so the unread badge clears without waiting for any
  /// broadcast (there isn't one for read-marker changes).
  Future<void> markRead(String chatId) async {
    final uid = _supabase.requireUid();
    try {
      await _supabase
          .from(_chatMembers)
          .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
          // Composite-PK row targeting — NOT a redundant auth filter; the
          // chat_members PK is (chat_id, user_id) and we need both to hit
          // exactly the one row.
          .eq('chat_id', chatId)
          .eq('user_id', uid);
      _patchInboxForMarkRead(chatId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Cache write helpers — fire-and-forget; failures stay inside the data
  // layer so a transient cache issue never breaks the UI.
  // ═══════════════════════════════════════════════════════════════════════

  void _writeCacheChat(ChatDto dto) {
    unawaited(_local.upsertChat(dto.toEntity()).catchError((Object _) {}));
  }

  void _writeCacheBulkChats(List<ChatDto> dtos) {
    unawaited(
      _local
          .replaceChats(dtos.map((d) => d.toEntity()).toList())
          .catchError((Object _) {}),
    );
  }

  void _writeCacheMessage(MessageDto dto) {
    unawaited(_local.upsertMessage(dto.toEntity()).catchError((Object _) {}));
  }

  void _writeCacheBulkMessages(String chatId, List<MessageDto> dtos) {
    unawaited(
      _local
          .replaceMessages(chatId, dtos.map((d) => d.toEntity()).toList())
          .catchError((Object _) {}),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Misc
  // ═══════════════════════════════════════════════════════════════════════

  Exception _functionException(FunctionException e) {
    String? msg;
    final d = e.details;
    if (d is Map && d['error'] is Map) {
      msg = (d['error'] as Map)['message']?.toString();
    }
    switch (e.status) {
      case 401:
      case 403:
        return UnauthorizedException(msg ?? 'Not authorised');
      default:
        return ServerException(msg ?? 'list-my-chats failed');
    }
  }
}

class _ThreadState {
  _ThreadState({
    required this.controller,
    required this.current,
    required this.senderNames,
  });

  final StreamController<List<MessageDto>> controller;
  List<MessageDto> current;

  /// sender_id → display_name (or null when the profile is deleted).
  /// Populated on initial fetch and updated on cache-miss fetches.
  final Map<String, String?> senderNames;
}
