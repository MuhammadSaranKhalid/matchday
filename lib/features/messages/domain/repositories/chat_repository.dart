import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat_channel.dart';
import '../entities/chat_draft.dart';
import '../entities/chat_message.dart';
import '../entities/chat_participant.dart';
import '../entities/chat_sync_state.dart';
import '../value_objects/message_body.dart';

/// Single domain contract for the Matchday chat subsystem.
///
/// The legacy MessagesRepository bridge is intentionally removed. Flutter
/// presentation consumes ChatChannel / ChatMessage directly.
abstract interface class ChatRepository {
  Stream<List<ChatChannel>> watchInbox();
  Future<Either<Failure, Unit>> refreshInbox();

  Stream<List<ChatMessage>> watchMessages(
    String channelId, {
    int? beforeMessageSeq,
  });

  Stream<List<ChatParticipant>> watchParticipants(String channelId);
  Stream<ChatSyncState> watchSyncState(String channelId);

  Future<Either<Failure, ChatMessage>> sendMessage(
    String channelId,
    MessageBody body, {
    String? replyToId,
  });

  Future<Either<Failure, ChatMessage>> sendImageMessage(
    String channelId, {
    required List<int> imageBytes,
    required String extension,
    String? caption,
    String? replyToId,
  });

  Future<Either<Failure, ChatMessage>> editMessage(
    String messageId,
    int expectedVersion,
    String newBody,
  );

  Future<Either<Failure, Unit>> deleteMessage(
    String channelId,
    String messageId,
  );

  Future<Either<Failure, Unit>> retryMessage(String messageId);

  Future<Either<Failure, Unit>> markRead(
    String channelId, [
    int? throughMessageSeq,
  ]);

  Future<Either<Failure, Unit>> markDelivered(
    String channelId,
    int throughMessageSeq,
  );

  void closeChannel(String channelId);

  Future<Either<Failure, Unit>> setReaction(
    String messageId,
    String reaction,
    bool selected,
  );

  Future<Either<Failure, String>> getOrCreateDmChat(String targetUserId);

  Future<Either<Failure, String>> createGroupChat({
    required String title,
    required List<String> memberUserIds,
    String? description,
    String? avatarUrl,
  });

  Future<Either<Failure, Unit>> acceptDirectRequest(String channelId);
  Future<Either<Failure, Unit>> declineDirectRequest(String channelId);

  Future<Either<Failure, int>> loadOlderMessages(String channelId);

  Future<ChatDraft?> readDraftState(String channelId);
  Future<void> saveDraftState(String channelId, ChatDraft draft);
  Future<void> deleteDraft(String channelId);

  Stream<Set<String>> watchTypingUsers(String channelId);
  Future<void> setTyping(String channelId, bool isTyping);

  Stream<Set<String>> watchPresence(String channelId);

  /// Turns a private Supabase Storage object path into a temporary HTTP URL.
  Future<Either<Failure, String>> resolveMediaUrl(String storagePath);
}
