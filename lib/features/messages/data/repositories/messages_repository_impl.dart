import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart' show TeamId;
import '../../domain/entities/chat.dart';
import '../../domain/entities/chat_channel.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/messages_repository.dart';
import '../../domain/value_objects/message_body.dart';

/// Legacy bridge adapter wrapping the target local-first [ChatRepository].
/// Preserves backward compatibility while directing all traffic through the
/// new universal channel architecture, Drift v10 schema, and Outbox.
class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._chatRepo);

  final ChatRepository _chatRepo;

  @override
  Stream<List<Chat>> watchMyChats() {
    return _chatRepo.watchInbox().map((channels) => channels.map(_chatFromChannel).toList());
  }

  @override
  Stream<List<Message>> watchMessages(ChatId chatId) {
    return _chatRepo.watchMessages(chatId.value).map((messages) => messages.map(_messageFromChatMessage).toList());
  }

  @override
  Future<Either<Failure, int>> loadOlderMessages(ChatId chatId) {
    return _chatRepo.loadOlderMessages(chatId.value);
  }

  @override
  Future<Either<Failure, Message>> sendMessage(
    ChatId chatId,
    MessageBody body, {
    String? replyToId,
  }) async {
    final result = await _chatRepo.sendMessage(chatId.value, body, replyToId: replyToId);
    return result.map(_messageFromChatMessage);
  }

  @override
  Future<Either<Failure, Message>> sendImageMessage(
    ChatId chatId, {
    required List<int> imageBytes,
    required String extension,
    String? caption,
    String? replyToId,
  }) async {
    final result = await _chatRepo.sendImageMessage(
      chatId.value,
      imageBytes: imageBytes,
      extension: extension,
      caption: caption,
      replyToId: replyToId,
    );
    return result.map(_messageFromChatMessage);
  }

  @override
  Future<Either<Failure, Unit>> deleteMessage(ChatId chatId, MessageId messageId) {
    return _chatRepo.deleteMessage(chatId.value, messageId.value);
  }

  @override
  Future<Either<Failure, Unit>> markRead(ChatId chatId, {int? throughMessageSeq}) {
    return _chatRepo.markRead(chatId.value, throughMessageSeq);
  }

  @override
  Future<Either<Failure, ChatId>> getOrCreateDmChat(String targetUserId) async {
    final result = await _chatRepo.getOrCreateDmChat(targetUserId);
    return result.map(ChatId.new);
  }

  @override
  Future<Either<Failure, Unit>> acceptDmRequest(ChatId chatId) {
    return _chatRepo.acceptDirectRequest(chatId.value);
  }

  @override
  Future<Either<Failure, Unit>> declineDmRequest(ChatId chatId) {
    return _chatRepo.declineDirectRequest(chatId.value);
  }

  @override
  Future<String?> readDraft(ChatId chatId) => _chatRepo.readDraft(chatId.value);

  @override
  Future<void> saveDraft(ChatId chatId, String body) =>
      _chatRepo.saveDraft(chatId.value, body);

  @override
  Future<void> deleteDraft(ChatId chatId) => _chatRepo.deleteDraft(chatId.value);

  @override
  Stream<bool> watchTyping(ChatId chatId) => _chatRepo.watchTyping(chatId.value);

  @override
  Future<void> setTyping(ChatId chatId, bool isTyping) =>
      _chatRepo.setTyping(chatId.value, isTyping);

  // ─── Mappers ─────────────────────────────────────────────────────────────

  Chat _chatFromChannel(ChatChannel c) {
    return Chat(
      id: ChatId(c.id),
      kind: c.isDm
          ? ChatKind.dm
          : (c.isMatch
              ? ChatKind.match
              : (c.isTeam ? ChatKind.team : ChatKind.group)),
      name: c.name,
      teamId: c.teamId != null ? TeamId(c.teamId!) : null,
      unreadCount: c.unreadCount,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
      lastMessageAt: c.lastMessageAt,
      lastMessagePreview: c.lastMessagePreview,
      lastMessageSenderId: c.lastMessageSenderId,
      lastMessageFromMe: c.lastMessageFromMe,
      teamLogoUrl: c.teamLogoUrl,
      teamLogoMonogram: c.teamLogoMonogram,
      teamPrimaryColorHex: c.teamPrimaryColorHex,
      dmOtherUserId: c.dmOtherUserId,
      dmOtherUserName: c.dmOtherUserName,
      dmOtherUserUsername: c.dmOtherUserUsername,
      dmOtherUserAvatarUrl: c.dmOtherUserAvatarUrl,
      youFollow: c.youFollow,
      theyFollowYou: c.theyFollowYou,
      isAccepted: c.isAccepted,
    );
  }

  Message _messageFromChatMessage(ChatMessage m) {
    return Message(
      id: MessageId(m.id),
      messageSeq: m.messageSeq,
      chatId: ChatId(m.channelId),
      senderId: m.senderId,
      senderDisplayName: m.senderDisplayName,
      body: m.body ?? '',
      createdAt: m.createdAt,
      fromMe: m.fromMe,
      messageType: m.messageType,
      mediaUrl: m.mediaUrl,
      replyToId: m.replyToId,
      replyToBody: m.replyToBody,
      replyToAuthor: m.replyToAuthor,
      editedAt: m.editedAt,
      deletedAt: m.deletedAt,
      deliveryStatus: m.deliveryStatus,
      reactions: m.reactions,
    );
  }
}
