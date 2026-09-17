import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat_channel.dart';
import '../entities/chat_message.dart';
import '../value_objects/message_body.dart';

/// Universal domain contract for the Match Day chat subsystem (Spec §6.4).
abstract interface class ChatRepository {
  /// Reactive stream of the user's active inbox channels, backed by Drift.
  Stream<List<ChatChannel>> watchInbox();

  /// Forces authoritative synchronization of the user's inbox list from Supabase into Drift.
  Future<Either<Failure, Unit>> refreshInbox();

  /// Reactive stream of chronological messages in [channelId], backed by Drift.
  Stream<List<ChatMessage>> watchMessages(
    String channelId, {
    int? beforeMessageSeq,
  });

  /// Sends a text message. Commits optimistically to Drift + Outbox in one transaction,
  /// causing immediate local echo before the background worker drains to the server.
  Future<Either<Failure, ChatMessage>> sendMessage(
    String channelId,
    MessageBody body, {
    String? replyToId,
  });

  /// Sends an image attachment message.
  Future<Either<Failure, ChatMessage>> sendImageMessage(
    String channelId, {
    required List<int> imageBytes,
    required String extension,
    String? caption,
    String? replyToId,
  });

  /// Edits an existing message with optimistic concurrency (version checking).
  Future<Either<Failure, ChatMessage>> editMessage(
    String messageId,
    int expectedVersion,
    String newBody,
  );

  /// Soft-deletes a message, replacing its content with a tombstone.
  Future<Either<Failure, Unit>> deleteMessage(String channelId, String messageId);

  /// Retries sending a previously failed message.
  Future<Either<Failure, Unit>> retryMessage(String messageId);

  /// Monotonically advances the user's read horizon for [channelId].
  /// If [throughMessageSeq] is omitted, marks all messages up to the latest known sequence as read.
  Future<Either<Failure, Unit>> markRead(String channelId, [int? throughMessageSeq]);

  /// Monotonically acknowledges delivery of messages up to [throughMessageSeq].
  Future<Either<Failure, Unit>> markDelivered(String channelId, int throughMessageSeq);

  /// Closes real-time channel subscription when the user leaves a conversation.
  void closeChannel(String channelId);

  /// Sets or unsets an emoji reaction on a message.
  Future<Either<Failure, Unit>> setReaction(
    String messageId,
    String reaction,
    bool selected,
  );

  /// Resolves or creates the canonical direct message channel with [targetUserId].
  Future<Either<Failure, String>> getOrCreateDmChat(String targetUserId);

  /// Accepts an incoming direct message request.
  Future<Either<Failure, Unit>> acceptDirectRequest(String channelId);

  /// Declines an incoming direct message request.
  Future<Either<Failure, Unit>> declineDirectRequest(String channelId);

  /// Loads the next page of older message history from Supabase into Drift.
  Future<Either<Failure, int>> loadOlderMessages(String channelId);

  /// Reads the local composer draft for [channelId].
  Future<String?> readDraft(String channelId);

  /// Persists the local composer draft for [channelId].
  Future<void> saveDraft(String channelId, String body);

  /// Deletes the local composer draft for [channelId].
  Future<void> deleteDraft(String channelId);

  /// Streams ephemeral typing indicators for [channelId] via Ably.
  Stream<bool> watchTyping(String channelId);

  /// Broadcasts typing activity for the current user in [channelId].
  Future<void> setTyping(String channelId, bool isTyping);
}
