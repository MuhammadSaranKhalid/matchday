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
/// `keepAlive: true`: backgrounding the app (or briefly removing the thread
/// widget from the tree during a navigation) shouldn't drop the broadcast
/// subscription. The family auto-disposes per chatId when no listener is
/// ever attached for that id, so memory stays bounded — only chats the user
/// actually opens hold a subscription, and they hold it for the session.
@Riverpod(keepAlive: true)
class MessageThread extends _$MessageThread {
  @override
  Stream<List<Message>> build(String chatId) =>
      ref.watch(messagesRepositoryProvider).watchMessages(ChatId(chatId));

  /// Validate via the [MessageBody] value object, then send. Returns the
  /// inserted message on success so the widget can react (clear input,
  /// scroll to bottom). On a validation failure the repo is never called.
  Future<Either<Failure, Message>> send(String raw) {
    return MessageBody.create(raw).fold(
      (failure) => Future.value(Left<Failure, Message>(failure)),
      (body) =>
          ref.read(messagesRepositoryProvider).sendMessage(ChatId(chatId), body),
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
}
