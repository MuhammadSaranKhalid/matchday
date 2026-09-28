import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/value_objects/message_body.dart';
import '../providers/messages_providers.dart';

part 'message_thread_controller.g.dart';

/// Thread controller over the universal ChatRepository.
///
/// IMPORTANT LIFECYCLE RULE:
/// This provider intentionally does NOT watch the inbox/channel projection.
/// The previous implementation watched [myChatChannelsProvider] to decide
/// whether Presence should be enabled. Every local inbox mutation (read
/// horizon, participant hydration, unread count, request status, etc.) then
/// recomputed this provider. Riverpod disposed the old build, which called
/// closeChannel(), so the Ably channel repeatedly detached and re-attached.
///
/// Presence policy now belongs below the UI in ChatSyncCoordinator. The thread
/// owns one message stream for the lifetime of the route, and closing the route
/// is the only normal reason to close the realtime channel.
@riverpod
class MessageThread extends _$MessageThread {
  @override
  Stream<List<ChatMessage>> build(String chatId) {
    final repository = ref.read(chatRepositoryProvider);

    // Since this provider has no reactive inbox dependency, onDispose now means
    // what we actually want here: the thread provider itself is going away
    // (normally because the screen/route stopped listening).
    ref.onDispose(() {
      repository.closeChannel(chatId);
    });

    return repository.watchMessages(chatId);
  }

  Future<Either<Failure, ChatMessage>> send(
    String raw, {
    String? replyToId,
  }) {
    return MessageBody.create(raw).fold(
      (failure) => Future.value(Left(failure)),
      (body) => ref.read(chatRepositoryProvider).sendMessage(
            chatId,
            body,
            replyToId: replyToId,
          ),
    );
  }

  Future<Either<Failure, ChatMessage>> sendImage({
    required List<int> imageBytes,
    required String extension,
    String? caption,
    String? replyToId,
  }) =>
      ref.read(chatRepositoryProvider).sendImageMessage(
            chatId,
            imageBytes: imageBytes,
            extension: extension,
            caption: caption,
            replyToId: replyToId,
          );

  Future<Either<Failure, ChatMessage>> editMessage(
    ChatMessage message,
    String raw,
  ) {
    return MessageBody.create(raw).fold(
      (failure) => Future.value(Left(failure)),
      (body) => ref.read(chatRepositoryProvider).editMessage(
            message.id,
            message.version,
            body.value,
          ),
    );
  }

  Future<Either<Failure, Unit>> deleteMessage(String messageId) =>
      ref.read(chatRepositoryProvider).deleteMessage(chatId, messageId);

  Future<Either<Failure, Unit>> retryMessage(String messageId) =>
      ref.read(chatRepositoryProvider).retryMessage(messageId);

  Future<Either<Failure, int>> loadOlder() =>
      ref.read(chatRepositoryProvider).loadOlderMessages(chatId);

  /// Drift is already reactive. Do not invalidate the inbox provider after a
  /// successful receipt mutation; invalidating it was one of the triggers that
  /// caused the old thread provider to rebuild and detach Ably.
  Future<Either<Failure, Unit>> markRead({int? throughSeq}) =>
      ref.read(chatRepositoryProvider).markRead(chatId, throughSeq);

  /// Accepting a request updates LocalChannelMembers immediately. The
  /// repository/sync coordinator upgrades Presence on the existing open Ably
  /// channel without rebuilding this provider.
  Future<Either<Failure, Unit>> acceptRequest() =>
      ref.read(chatRepositoryProvider).acceptDirectRequest(chatId);

  Future<Either<Failure, Unit>> declineRequest() =>
      ref.read(chatRepositoryProvider).declineDirectRequest(chatId);
}
