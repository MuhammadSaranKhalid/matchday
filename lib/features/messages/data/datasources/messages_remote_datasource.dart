import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:typed_data';

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

  /// One-shot inbox fetch via the native `list_my_chats` RPC (fallback: edge fn).
  Future<List<ChatDto>> listMyChats() async {
    try {
      final res = await _supabase.rpc<dynamic>('list_my_chats');
      if (res is List) {
        return res
            .map((row) =>
                ChatDto.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList();
      }
      final fnRes = await _supabase.functions.invoke('list-my-chats');
      final data = fnRes.data;
      final rows = data is Map ? data['chats'] : data;
      if (rows is! List) {
        throw ServerException('list-my-chats returned an unexpected payload');
      }
      return rows
          .map((row) =>
              ChatDto.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, statusCode: int.tryParse(e.code ?? ''));
    } on FunctionException catch (e) {
      throw _functionException(e);
    }
  }

  /// Finds or creates a canonical DM chat container between the authenticated
  /// user and [targetUserId].
  Future<String> getOrCreateDmChat(String targetUserId) async {
    try {
      final res = await _supabase.rpc<String>(
        'get_or_create_dm_chat',
        params: {'p_target_user_id': targetUserId},
      );
      return res;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, statusCode: int.tryParse(e.code ?? ''));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get or create DM: $e');
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

  static const _messageSelect =
      'message_id, chat_id, sender_id, body, message_type, payload, reply_to_id, created_at, edited_at, deleted_at, '
      'sender:profiles(display_name)';

  /// Initial-load + load-more page size for thread pagination (ticket #35).
  /// Matches WhatsApp/Slack — fast first paint without too many round-trips
  /// when the user scrolls back through history.
  static const _pageSize = 50;

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

  /// One-shot list of the LATEST [_pageSize] non-deleted messages in a chat,
  /// oldest first. Used by [watchMessages] for the initial fetch and by
  /// [_resyncThread] on reconnect. Older messages load on demand via
  /// [loadOlderMessages].
  Future<List<MessageDto>> listMessages(String chatId) =>
      _listMessagesPage(chatId, limit: _pageSize);

  /// Internal: fetch one keyset page of messages, returning them in
  /// chronological (asc) order. When [beforeCreatedAt] + [beforeMessageId]
  /// are null, returns the LATEST page; when provided, returns the page
  /// older than the cursor `(created_at, message_id)`.
  ///
  /// The DB query orders DESC + LIMIT so we get the latest-of-the-older
  /// rows; we then reverse before returning so callers always see
  /// chronological order regardless of cursor direction.
  Future<List<MessageDto>> _listMessagesPage(
    String chatId, {
    required int limit,
    String? beforeCreatedAt,
    String? beforeMessageId,
  }) async {
    final uid = _supabase.requireUid();
    try {
      var q = _supabase
          .from(_messages)
          .select(_messageSelect)
          .eq('chat_id', chatId)
          .filter('deleted_at', 'is', null);

      if (beforeCreatedAt != null && beforeMessageId != null) {
        // Compound keyset: (created_at, message_id) < (cursor_at, cursor_id).
        // The nested `and(...)` is PostgREST syntax for tie-breaking on the
        // boundary instant — without it, two messages sharing a microsecond
        // could overlap or be skipped across page boundaries (ticket #35).
        q = q.or(
          'created_at.lt.$beforeCreatedAt,'
          'and(created_at.eq.$beforeCreatedAt,message_id.lt.$beforeMessageId)',
        );
      }

      final rows = await q
          .order('created_at', ascending: false)
          .order('message_id', ascending: false)
          .limit(limit);
      // Reverse so the caller sees chronological (asc) order — keeps the
      // day-divider logic in `_Conversation._buildItems` simple.
      return rows.reversed
          .map((row) => _dtoFromRow(Map<String, dynamic>.from(row), uid))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Load the next page of older messages for [chatId] and prepend to the
  /// in-memory list. Returns the number of messages loaded; `0` means
  /// end-of-thread, a value `< _pageSize` also means end-of-thread (no
  /// more pages exist after this one). Ticket #35.
  Future<int> loadOlderMessages(String chatId) async {
    final state = _threads[chatId];
    if (state == null || state.controller.isClosed) return 0;
    if (state.loadingOlder || !state.hasMore) return 0;
    if (state.current.isEmpty) return 0;

    state.loadingOlder = true;
    try {
      // Oldest currently-loaded message is the keyset cursor.
      final oldest = state.current.first;
      final older = await _listMessagesPage(
        chatId,
        limit: _pageSize,
        beforeCreatedAt: oldest.createdAt,
        beforeMessageId: oldest.messageId,
      );

      if (older.isEmpty) {
        state.hasMore = false;
        return 0;
      }

      // If the page came back smaller than asked, this was the last page.
      if (older.length < _pageSize) {
        state.hasMore = false;
      }

      // Prepend to the in-memory list. Dedup on message_id — the new page
      // shouldn't overlap (keyset cursor is strict <), but if a realtime
      // insert raced in during the await we don't want a duplicate.
      final existing = state.current.map((m) => m.messageId).toSet();
      final toPrepend = older.where((m) => !existing.contains(m.messageId));
      state.current = [...toPrepend, ...state.current];

      // Also keep the sender-names cache fresh — older pages may include
      // members who haven't messaged in the latest 50.
      for (final m in older) {
        if (m.senderId != null) {
          state.senderNames[m.senderId!] = m.senderDisplayName;
        }
      }

      if (!state.controller.isClosed) {
        state.controller.add(List.unmodifiable(state.current));
      }
      // NOTE: older messages are NOT written to the cache. Cache is sized
      // for cold-start of the LATEST page only; paginated history is
      // network-only (ticket #35 design decision).
      return older.length;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } finally {
      state.loadingOlder = false;
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
      // Initial page that came back full implies older history may exist;
      // a partial first page means we already have everything (ticket #35).
      hasMore: initial.length == _pageSize,
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
      // Reconnect = reset to the latest page. Any older messages the user
      // had paginated in are dropped from the in-memory view; they can
      // re-load them by scrolling up again. Pragmatic — preserving deep
      // pagination across reconnect would require a more invasive refetch
      // and the user is unlikely to be deep in history right after a drop.
      final fresh = await listMessages(chatId);
      state.current = fresh;
      state.hasMore = fresh.length == _pageSize;
      state.loadingOlder = false;
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
    String messageType = 'text',
    Map<String, dynamic>? payload,
    String? replyToId,
  }) async {
    final uid = _supabase.requireUid();
    try {
      final insertData = <String, dynamic>{
        'chat_id': chatId,
        'sender_id': uid,
        'body': body,
        'message_type': messageType,
      };
      if (payload != null) insertData['payload'] = payload;
      if (replyToId != null) insertData['reply_to_id'] = replyToId;

      final row = await _supabase
          .from(_messages)
          .insert(insertData)
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

  /// Upload an image to Supabase Storage and return its public URL.
  Future<String> uploadChatImage({
    required Uint8List bytes,
    required String extension,
  }) async {
    final uid = _supabase.requireUid();
    final cleanExt = extension.toLowerCase().replaceAll('.', '');
    final mimeType = switch (cleanExt) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
    final filename = 'chat_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';
    final path = '$uid/$filename';
    try {
      await _supabase.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );
      return _supabase.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      throw ServerException('Failed to upload image: $e');
    }
  }

  /// Soft-delete a message (sets deleted_at = now()).
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final uid = _supabase.requireUid();
    try {
      await _supabase
          .from(_messages)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('message_id', messageId)
          .eq('sender_id', uid);

      final thread = _threads[chatId];
      if (thread != null && !thread.controller.isClosed) {
        thread.current = thread.current
            .map((m) => m.messageId == messageId
                ? m.copyWith(deletedAt: DateTime.now().toUtc().toIso8601String())
                : m)
            .toList();
        thread.controller.add(List.unmodifiable(thread.current));
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Stamp `chat_members.last_read_at = now()` for (chat, me) via the
  /// `mark_chat_read` RPC (migration 20260608120000, ticket #39).
  ///
  /// History: this used to be a direct PostgREST UPDATE. The WITH CHECK
  /// clause added in migration 20260607120000 intermittently rejected the
  /// row via a fragile self-referential subselect, and PostgREST silently
  /// returns 200 for 0-rows-affected — so `last_read_at` stayed NULL
  /// across all chats and the unread badge never cleared. The RPC is
  /// `SECURITY DEFINER` so it bypasses the buggy RLS check, uses
  /// server-side `now()` (no device-clock skew), and `RETURNING` gives us
  /// a positive success signal (NULL → not-a-member).
  ///
  /// Patches the inbox + cache locally after success so the badge clears
  /// without waiting for any broadcast (there isn't one for read-marker
  /// changes).
  Future<void> markRead(String chatId) async {
    try {
      // RPC returns timestamptz (ISO 8601 string over the wire) or NULL.
      final stamped = await _supabase.rpc<String?>(
        'mark_chat_read',
        params: {'p_chat_id': chatId},
      );
      // RPC returns the new last_read_at, or NULL if the caller wasn't an
      // active member of the chat. NULL is treated as a no-op — calling
      // markRead on a chat we can't actually read is a programming error,
      // not a recoverable runtime condition, so we skip the inbox patch
      // and return cleanly instead of inventing a "fake-success" badge
      // clear that would diverge from the server state.
      if (stamped == null) return;
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
    required this.hasMore,
  });

  final StreamController<List<MessageDto>> controller;
  List<MessageDto> current;

  /// sender_id → display_name (or null when the profile is deleted).
  /// Populated on initial fetch and updated on cache-miss fetches.
  final Map<String, String?> senderNames;

  /// Whether older messages MAY exist server-side. Starts based on whether
  /// the initial page filled to `_pageSize`; flipped to false when a
  /// `loadOlderMessages` call returns < `_pageSize` rows. Ticket #35.
  bool hasMore;

  /// In-flight guard for `loadOlderMessages` — concurrent triggers from
  /// the scroll listener are coalesced to a single network round-trip.
  bool loadingOlder = false;
}
