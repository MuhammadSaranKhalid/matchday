import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_channel_dto.dart';
import '../models/chat_message_dto.dart';
import '../models/chat_participant_dto.dart';

/// Remote data source communicating with Supabase Postgres RPCs and Storage.
/// Throws raw SDK exceptions; repositories map them to domain Failures.
class ChatRemoteDataSource {
  ChatRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;
  static const _uuid = Uuid();

  Future<List<ChatChannelDto>> listMyChats() async {
    final res = await _supabase.rpc<dynamic>('list_my_chats');
    if (res is! List) return const [];

    return res
        .map(
          (row) => ChatChannelDto.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<String> getOrCreateDirectChannel(String targetUserId) {
    return _supabase.rpc<String>(
      'get_or_create_direct_channel',
      params: {'p_target_user_id': targetUserId},
    );
  }

  Future<String> createGroupChannel({
    required String title,
    required List<String> memberUserIds,
    String? description,
    String? avatarUrl,
  }) {
    return _supabase.rpc<String>(
      'create_group_channel',
      params: {
        'p_title': title,
        'p_member_user_ids': memberUserIds,
        'p_description': description,
        'p_avatar_url': avatarUrl,
      },
    );
  }

  /// Hydrates the participant projection in two bounded queries.
  ///
  /// There is no per-message profile lookup and no LocalChatParticipants
  /// table. The result is written into LocalChannelMembers.
  Future<List<ChatParticipantDto>> fetchChannelParticipants(
    String channelId,
  ) async {
    final memberRows = await _supabase
        .from('channel_members')
        .select(
          'channel_id,user_id,role,status,'
          'last_read_message_seq,last_read_at,'
          'last_delivered_message_seq,last_delivered_at',
        )
        .eq('channel_id', channelId)
        .inFilter('status', const ['active', 'pending']);

    final members = List<Map<String, dynamic>>.from(memberRows);
    final userIds = members
        .map((row) => row['user_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    if (userIds.isEmpty) return const [];

    final profileRows = await _supabase
        .from('profiles')
        .select('user_id,username,display_name,profile_photo_url')
        .inFilter('user_id', userIds);

    final profiles = <String, Map<String, dynamic>>{
      for (final row in List<Map<String, dynamic>>.from(profileRows))
        if (row['user_id'] is String) row['user_id'] as String: row,
    };

    final now = DateTime.now().toUtc();
    final out = <ChatParticipantDto>[];

    for (final member in members) {
      final userId = member['user_id'] as String?;
      if (userId == null) continue;

      final profile = profiles[userId];
      final displayName = _participantDisplayName(profile);

      out.add(
        ChatParticipantDto(
          channelId: channelId,
          userId: userId,
          displayName: displayName,
          username: profile?['username'] as String?,
          avatarUrl: profile?['profile_photo_url'] as String?,
          channelRole: member['role'] as String? ?? 'member',
          membershipStatus: member['status'] as String? ?? 'active',
          lastReadMessageSeq:
              (member['last_read_message_seq'] as num?)?.toInt(),
          lastReadAt: _tryDate(member['last_read_at']),
          lastDeliveredMessageSeq:
              (member['last_delivered_message_seq'] as num?)?.toInt(),
          lastDeliveredAt: _tryDate(member['last_delivered_at']),
          updatedAt: now,
        ),
      );
    }

    return out;
  }

  String _participantDisplayName(Map<String, dynamic>? profile) {
    final name = (profile?['display_name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;

    final username = (profile?['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return '@$username';

    return 'Deleted user';
  }

  DateTime? _tryDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

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

    return ChatMessageDto.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }

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

    return ChatMessageDto.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }

  Future<void> deleteChannelMessage(String messageId) async {
    await _supabase.rpc<dynamic>(
      'delete_channel_message',
      params: {'p_message_id': messageId},
    );
  }

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

  Future<void> markChannelRead({
    required String channelId,
    required int throughSeq,
  }) async {
    await _supabase.rpc<dynamic>(
      'mark_channel_read',
      params: {
        'p_channel_id': channelId,
        'p_through_seq': throughSeq,
      },
    );
  }

  Future<void> markChannelDelivered({
    required String channelId,
    required int throughSeq,
  }) async {
    await _supabase.rpc<dynamic>(
      'mark_channel_delivered',
      params: {
        'p_channel_id': channelId,
        'p_through_seq': throughSeq,
      },
    );
  }

  Future<void> acceptChannelInvite(String channelId) async {
    await _supabase.rpc<dynamic>(
      'accept_channel_invite',
      params: {'p_channel_id': channelId},
    );
  }

  Future<void> declineChannelInvite(String channelId) async {
    await _supabase.rpc<dynamic>(
      'decline_channel_invite',
      params: {'p_channel_id': channelId},
    );
  }

  Future<List<ChatMessageDto>> fetchRecentMessages(
    String channelId, {
    int limit = 50,
  }) async {
    final res = await _supabase
        .from('messages')
        .select(
          '*,sender:profiles!messages_sender_id_fkey(display_name),'
          'attachments:message_attachments(*),reactions:message_reactions(*)',
        )
        .eq('channel_id', channelId)
        .order('message_seq', ascending: false)
        .limit(limit);

    return _parseMessageDtos(res as List).reversed.toList();
  }

  Future<List<ChatMessageDto>> fetchDeltaMessages(
    String channelId,
    int afterSeq, {
    int limit = 100,
  }) async {
    final res = await _supabase
        .from('messages')
        .select(
          '*,sender:profiles!messages_sender_id_fkey(display_name),'
          'attachments:message_attachments(*),reactions:message_reactions(*)',
        )
        .eq('channel_id', channelId)
        .gt('message_seq', afterSeq)
        .order('message_seq', ascending: true)
        .limit(limit);

    return _parseMessageDtos(res as List);
  }

  Future<List<ChatMessageDto>> fetchOlderMessages(
    String channelId,
    int beforeSeq, {
    int limit = 50,
  }) async {
    final res = await _supabase
        .from('messages')
        .select(
          '*,sender:profiles!messages_sender_id_fkey(display_name),'
          'attachments:message_attachments(*),reactions:message_reactions(*)',
        )
        .eq('channel_id', channelId)
        .lt('message_seq', beforeSeq)
        .order('message_seq', ascending: false)
        .limit(limit);

    return _parseMessageDtos(res as List).reversed.toList();
  }

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

  Future<String> getMediaSignedUrl(
    String storagePath, {
    int expiresInSeconds = 3600,
  }) {
    return _supabase.storage
        .from('chat-media')
        .createSignedUrl(storagePath, expiresInSeconds);
  }

  Future<void> deleteStorageAttachment(String storagePath) async {
    try {
      await _supabase.storage.from('chat-media').remove([storagePath]);
    } catch (e) {
      debugPrint('[ChatRemoteDataSource] Storage cleanup failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchChannelChanges(
    String channelId, {
    int? afterChangeSeq,
    int limit = 100,
  }) async {
    var query = _supabase
        .from('chat_changes')
        .select('*')
        .eq('channel_id', channelId);

    if (afterChangeSeq != null && afterChangeSeq > 0) {
      query = query.gt('change_seq', afterChangeSeq);
    }

    final res = await query.order('change_seq', ascending: true).limit(limit);
    return List<Map<String, dynamic>>.from(res as List);
  }

  List<ChatMessageDto> _parseMessageDtos(List<dynamic> rows) {
    final currentUserId = _supabase.auth.currentUser?.id;

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final sender = map['sender'];
      if (sender is Map && sender['display_name'] != null) {
        map['sender_display_name'] = sender['display_name'];
      }
      map['from_me'] =
          currentUserId != null && map['sender_id'] == currentUserId;
      return ChatMessageDto.fromJson(map);
    }).toList();
  }
}
