import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/chat_dto.dart';
import '../models/message_dto.dart';

/// Talks to Supabase for the chat inbox (list-my-chats edge function +
/// broadcast subscription for live unread updates). Returns DTOs / throws
/// raw exceptions per CLAUDE.md Rule 2.
class MessagesRemoteDataSource {
  MessagesRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

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

  /// Streams the chat inbox. Yields an initial fetch, then re-fetches and
  /// re-yields on each `chat_updated` broadcast on `user:<uid>:notifications`
  /// (fired by the `broadcast_new_message` trigger in migration 0802 on every
  /// message insert).
  ///
  /// Re-fetching the full inbox per event is wasteful but simple — the trigger
  /// payload carries enough to patch in-memory, but for v1 chat counts the
  /// round-trip is cheap and the code is straightforward. Revisit when inboxes
  /// grow.
  Stream<List<ChatDto>> watchMyChats() async* {
    final uid = _requireUid();

    var current = await listMyChats();
    yield current;

    final controller = StreamController<List<ChatDto>>();
    final channel = _supabase.channel(
      'user:$uid:notifications',
      opts: const RealtimeChannelConfig(self: true, private: true),
    );

    channel
        .onBroadcast(
          event: 'chat_updated',
          callback: (_) async {
            try {
              current = await listMyChats();
              if (!controller.isClosed) {
                controller.add(List.unmodifiable(current));
              }
            } catch (e) {
              if (!controller.isClosed) {
                controller.addError(ServerException(e.toString()));
              }
            }
          },
        )
        .subscribe();

    yield* controller.stream.asBroadcastStream(
      onCancel: (_) async {
        await _supabase.removeChannel(channel);
        await controller.close();
      },
    );
  }

  // ─── Thread / messages ────────────────────────────────────────────────

  static const _messages = 'messages';
  static const _chatMembers = 'chat_members';

  /// Selects the message columns plus an embedded sender profile for the
  /// display-name join. Used by every read path (list, broadcast re-fetch,
  /// send-and-return) so the shape going into [_dtoFromRow] is consistent.
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
    final uid = _requireUid();
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

  /// Streams messages in a chat. Yields the initial list, then re-emits with
  /// each broadcast `new_message` event on `chat:<chat_id>:messages`. The
  /// broadcast payload only carries the message row (no sender join), so
  /// each event re-fetches the inserted row with the embedded profile — one
  /// extra round-trip per incoming message in exchange for clean dedup +
  /// consistent display-name handling.
  Stream<List<MessageDto>> watchMessages(String chatId) async* {
    final uid = _requireUid();

    var current = await listMessages(chatId);
    yield current;

    final controller = StreamController<List<MessageDto>>();
    final channel = _supabase.channel(
      'chat:$chatId:messages',
      opts: const RealtimeChannelConfig(self: true, private: true),
    );

    channel
        .onBroadcast(
          event: 'new_message',
          callback: (payload) async {
            final data =
                (payload['payload'] as Map<String, dynamic>?) ?? payload;
            final id = data['message_id'] as String?;
            if (id == null) return;
            if (current.any((m) => m.messageId == id)) return; // dedup
            try {
              final row = await _supabase
                  .from(_messages)
                  .select(_messageSelect)
                  .eq('message_id', id)
                  .single();
              final dto = _dtoFromRow(Map<String, dynamic>.from(row), uid);
              current = [...current, dto];
              if (!controller.isClosed) {
                controller.add(List.unmodifiable(current));
              }
            } catch (e) {
              if (!controller.isClosed) {
                controller.addError(ServerException(e.toString()));
              }
            }
          },
        )
        .subscribe();

    yield* controller.stream.asBroadcastStream(
      onCancel: (_) async {
        await _supabase.removeChannel(channel);
        await controller.close();
      },
    );
  }

  /// Insert a message authored by the current user, returning the row with
  /// sender_display_name resolved + from_me=true.
  Future<MessageDto> sendMessage({
    required String chatId,
    required String body,
  }) async {
    final uid = _requireUid();
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
      return _dtoFromRow(Map<String, dynamic>.from(row), uid);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Stamp `chat_members.last_read_at = now()` for (chat, me). Allowed by
  /// the `chat_members_update_self_or_admin` policy.
  Future<void> markRead(String chatId) async {
    final uid = _requireUid();
    try {
      await _supabase
          .from(_chatMembers)
          .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('chat_id', chatId)
          .eq('user_id', uid);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  /// Translate a [FunctionException] from the edge function into the
  /// appropriate raw exception. Mirrors the pattern in matches_remote_datasource.
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
