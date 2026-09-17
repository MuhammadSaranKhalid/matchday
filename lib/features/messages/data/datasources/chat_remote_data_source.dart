import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_channel_dto.dart';
import '../models/chat_message_dto.dart';

/// Remote data source communicating with Supabase Postgres RPCs and Storage.
/// Throws raw SDK exceptions per Clean Architecture boundary discipline.
class ChatRemoteDataSource {
  ChatRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;
  static const _uuid = Uuid();

  /// Lists all accessible chat channels for the current user via `list_my_chats`.
  Future<List<ChatChannelDto>> listMyChats() async {
    final res = await _supabase.rpc<dynamic>('list_my_chats');
    if (res is List) {
      return res
          .map((row) =>
              ChatChannelDto.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    }
    return const [];
  }

  /// Gets or creates a canonical 1:1 direct channel with [targetUserId].
  Future<String> getOrCreateDirectChannel(String targetUserId) async {
    final res = await _supabase.rpc<String>(
      'get_or_create_direct_channel',
      params: {'p_target_user_id': targetUserId},
    );
    return res;
  }

  /// Creates a multi-user group channel.
  Future<String> createGroupChannel({
    required String title,
    required List<String> memberUserIds,
    String? description,
    String? avatarUrl,
  }) async {
    final res = await _supabase.rpc<String>(
      'create_group_channel',
      params: {
        'p_title': title,
        'p_member_user_ids': memberUserIds,
        'p_description': description,
        'p_avatar_url': avatarUrl,
      },
    );
    return res;
  }

  /// Sends a message into a channel using the authoritative `send_channel_message` RPC.
  Future<ChatMessageDto> sendChannelMessage({
    required String messageId,
    required String channelId,
    String messageType = 'text',
    String? body,
    String? replyToMessageId,
    Map<String, dynamic>? payload,
  }) async {
    final res = await _supabase.rpc<dynamic>(
      'send_channel_message',
      params: {
        'p_message_id': messageId,
        'p_channel_id': channelId,
        'p_message_type': messageType,
        'p_body': body,
        'p_reply_to_message_id': replyToMessageId,
        'p_payload': payload ?? {},
      },
    );

    final map = Map<String, dynamic>.from(res as Map);
    return ChatMessageDto.fromJson(map);
  }

  /// Edits an existing message with optimistic concurrency control.
  Future<ChatMessageDto> editChannelMessage({
    required String messageId,
    required int expectedVersion,
    required String newBody,
    Map<String, dynamic>? payload,
  }) async {
    final res = await _supabase.rpc<dynamic>(
      'edit_channel_message',
      params: {
        'p_message_id': messageId,
        'p_expected_version': expectedVersion,
        'p_body': newBody,
        'p_payload': payload,
      },
    );

    final map = Map<String, dynamic>.from(res as Map);
    return ChatMessageDto.fromJson(map);
  }

  /// Soft-deletes a message via `delete_channel_message` RPC.
  Future<void> deleteChannelMessage(String messageId) async {
    await _supabase.rpc<dynamic>(
      'delete_channel_message',
      params: {'p_message_id': messageId},
    );
  }

  /// Sets or clears a reaction on a message via `set_message_reaction` RPC.
  Future<void> setMessageReaction({
    required String messageId,
    required String reaction,
    required bool selected,
  }) async {
    await _supabase.rpc<dynamic>(
      'set_message_reaction',
      params: {
        'p_message_id': messageId,
        'p_reaction': reaction,
        'p_selected': selected,
      },
    );
  }

  /// Monotonically advances the read horizon via `mark_channel_read` RPC.
  Future<void> markChannelRead({
    required String channelId,
    required int throughSeq,
  }) async {
    await _supabase.rpc<dynamic>(
      'mark_channel_read',
      params: {
        'p_channel_id': channelId,
        'p_through_message_seq': throughSeq,
      },
    );
  }

  /// Monotonically advances the delivery horizon via `mark_channel_delivered` RPC.
  Future<void> markChannelDelivered({
    required String channelId,
    required int throughSeq,
  }) async {
    await _supabase.rpc<dynamic>(
      'mark_channel_delivered',
      params: {
        'p_channel_id': channelId,
        'p_through_message_seq': throughSeq,
      },
    );
  }

  /// Accepts an incoming direct message invite/request.
  Future<void> acceptChannelInvite(String channelId) async {
    await _supabase.rpc<dynamic>(
      'accept_channel_invite',
      params: {'p_channel_id': channelId},
    );
  }

  /// Declines an incoming direct message invite/request.
  Future<void> declineChannelInvite(String channelId) async {
    await _supabase.rpc<dynamic>(
      'decline_channel_invite',
      params: {'p_channel_id': channelId},
    );
  }

  /// Fetches a bounded recent window of messages for initial channel bootstrap (Spec §5).
  Future<List<ChatMessageDto>> fetchRecentMessages(
    String channelId, {
    int limit = 50,
  }) async {
    final res = await _supabase
        .from('messages')
        .select(
          '*, sender:profiles!messages_sender_id_fkey(display_name), attachments:message_attachments(*), reactions:message_reactions(*)',
        )
        .eq('channel_id', channelId)
        .order('message_seq', ascending: false)
        .limit(limit);

    final list = _parseMessageDtos(res as List);
    // Reverse to chronological order (asc)
    return list.reversed.toList();
  }

  /// Fetches delta messages where `message_seq > afterSeq` with an explicit page limit (Spec §6).
  Future<List<ChatMessageDto>> fetchDeltaMessages(
    String channelId,
    int afterSeq, {
    int limit = 100,
  }) async {
    final res = await _supabase
        .from('messages')
        .select(
          '*, sender:profiles!messages_sender_id_fkey(display_name), attachments:message_attachments(*), reactions:message_reactions(*)',
        )
        .eq('channel_id', channelId)
        .gt('message_seq', afterSeq)
        .order('message_seq', ascending: true)
        .limit(limit);

    return _parseMessageDtos(res as List);
  }

  /// Fetches an older page of message history before [beforeSeq].
  Future<List<ChatMessageDto>> fetchOlderMessages(
    String channelId,
    int beforeSeq, {
    int limit = 50,
  }) async {
    final res = await _supabase
        .from('messages')
        .select(
          '*, sender:profiles!messages_sender_id_fkey(display_name), attachments:message_attachments(*), reactions:message_reactions(*)',
        )
        .eq('channel_id', channelId)
        .lt('message_seq', beforeSeq)
        .order('message_seq', ascending: false)
        .limit(limit);

    final list = _parseMessageDtos(res as List);
    // Reverse to chronological order (asc)
    return list.reversed.toList();
  }

  /// Uploads media attachment bytes to Supabase Storage private bucket and returns the storage path (Spec §26).
  Future<String> uploadMediaAttachment({
    required List<int> bytes,
    required String channelId,
    String? messageId,
    String? attachmentId,
    required String extension,
    required String mimeType,
  }) async {
    final msgId = messageId ?? _uuid.v4();
    final attId = attachmentId ?? _uuid.v4();
    final path = 'channels/$channelId/$msgId/$attId.$extension';

    await _supabase.storage.from('chat-media').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: mimeType),
        );

    return path;
  }

  /// Generates a temporary signed URL for authorized access to private chat media (Spec §26).
  Future<String> getMediaSignedUrl(String storagePath, {int expiresInSeconds = 3600}) {
    return _supabase.storage
        .from('chat-media')
        .createSignedUrl(storagePath, expiresInSeconds);
  }

  List<ChatMessageDto> _parseMessageDtos(List<dynamic> rows) {
    final currentUserId = _supabase.auth.currentUser?.id;

    return rows.map((r) {
      final map = Map<String, dynamic>.from(r as Map);
      // Flatten joined sender display_name
      final senderObj = map['sender'];
      if (senderObj is Map && senderObj['display_name'] != null) {
        map['sender_display_name'] = senderObj['display_name'];
      }
      map['from_me'] = currentUserId != null && map['sender_id'] == currentUserId;

      return ChatMessageDto.fromJson(map);
    }).toList();
  }
}
