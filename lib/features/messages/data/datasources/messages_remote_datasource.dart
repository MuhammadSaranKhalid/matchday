import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/chat_dto.dart';

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
