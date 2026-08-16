import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';
import '../../domain/value_objects/message_body.dart';
import '../providers/messages_providers.dart';

part 'message_thread_controller.g.dart';

/// Streams the messages in a chat and exposes the write actions.
///
/// Per the controller-action-returns convention used in matches/, action
/// methods return `Future<Either<Failure, T>>` and the widget folds the
/// result. The state stream itself carries the message list — no submit
/// error slot.
///
/// Family argument is a plain `String chatId` (Riverpod serialises args for
/// the provider key; raw strings stringify cleanly). Internally we wrap in
/// `ChatId(...)` before crossing the repository boundary.
///
/// Autodispose (bare `@riverpod`), matching every other family-based
/// controller/provider in the codebase (`liveMatch`, `team`, `roster`,
/// `authorPosts`, etc.). When the user leaves a thread the subscription
/// drops; on re-entry the cache emits instantly so first paint is unchanged
/// and the realtime channel reconnects in the background.
///
/// Why not `keepAlive`: the previous keepAlive posture made this the only
/// family in the codebase that retained per-key state for the session — a
/// user who opened 40 chats would hold 40 buffered message lists + 40 live
/// `StreamSubscription`s simultaneously. The brief realtime re-handshake on
/// re-entry is cheap; the memory savings are not (#47).
@riverpod
class MessageThread extends _$MessageThread {
  @override
  Stream<List<Message>> build(String chatId) =>
      ref.watch(messagesRepositoryProvider).watchMessages(ChatId(chatId));

  /// Validate via the [MessageBody] value object, then send. Returns the
  /// inserted message on success so the widget can react (clear input,
  /// scroll to bottom). On a validation failure the repo is never called.
  Future<Either<Failure, Message>> send(String raw, {String? replyToId}) {
    return MessageBody.create(raw).fold(
      (failure) => Future.value(Left<Failure, Message>(failure)),
      (body) => ref.read(messagesRepositoryProvider).sendMessage(
            ChatId(chatId),
            body,
            replyToId: replyToId,
          ),
    );
  }

  /// Send an image message with optional caption and quote reply.
  Future<Either<Failure, Message>> sendImage({
    required List<int> imageBytes,
    required String extension,
    String? caption,
    String? replyToId,
  }) {
    return ref.read(messagesRepositoryProvider).sendImageMessage(
          ChatId(chatId),
          imageBytes: imageBytes,
          extension: extension,
          caption: caption,
          replyToId: replyToId,
        );
  }

  /// Soft delete a message.
  Future<Either<Failure, Unit>> deleteMessage(String messageId) {
    return ref.read(messagesRepositoryProvider).deleteMessage(
          ChatId(chatId),
          MessageId(messageId),
        );
  }

  /// Load the next page of older messages (ticket #35). Returns the number
  /// loaded — `0` or `< 50` means we hit the end of the thread; callers
  /// use this to stop firing the scroll trigger.
  Future<Either<Failure, int>> loadOlder() =>
      ref.read(messagesRepositoryProvider).loadOlderMessages(ChatId(chatId));

  /// Stamp `chat_members.last_read_at`. On success, invalidate the inbox
  /// list so its unread badges re-emit reactively (server doesn't broadcast
  /// `chat_updated` for read-marker changes — they only fire on message
  /// insert).
  Future<Either<Failure, Unit>> markRead() async {
    final result =
        await ref.read(messagesRepositoryProvider).markRead(ChatId(chatId));
    if (result.isRight()) {
      ref.invalidate(myChatsProvider);
    }
    return result;
  }

  /// Accept an incoming DM message request.
  Future<Either<Failure, Unit>> acceptRequest() async {
    final result = await ref
        .read(messagesRepositoryProvider)
        .acceptDmRequest(ChatId(chatId));
    if (result.isRight()) {
      ref.invalidate(myChatsProvider);
    }
    return result;
  }

  /// Decline an incoming DM message request.
  Future<Either<Failure, Unit>> declineRequest() async {
    final result = await ref
        .read(messagesRepositoryProvider)
        .declineDmRequest(ChatId(chatId));
    if (result.isRight()) {
      ref.invalidate(myChatsProvider);
    }
    return result;
  }
}


