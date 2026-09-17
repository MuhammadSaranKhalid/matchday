import 'package:equatable/equatable.dart';

import 'message_attachment.dart';
import 'message_reaction.dart';

enum MessageDeliveryStatus {
  pending,
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    this.messageSeq,
    required this.channelId,
    this.senderId,
    this.senderDisplayName,
    this.messageType = 'text',
    this.body,
    this.payload = const {},
    this.replyToId,
    this.replyToBody,
    this.replyToAuthor,
    this.version = 1,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    required this.fromMe,
    this.syncStatus = 'sent',
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.reactions = const [],
    this.attachments = const [],
  });

  final String id;
  final int? messageSeq;
  final String channelId;
  final String? senderId;
  final String? senderDisplayName;
  final String messageType;
  final String? body;
  final Map<String, dynamic> payload;
  final String? replyToId;
  final String? replyToBody;
  final String? replyToAuthor;
  final int version;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final bool fromMe;
  final String syncStatus;
  final MessageDeliveryStatus deliveryStatus;
  final List<MessageReaction> reactions;
  final List<MessageAttachment> attachments;

  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;
  bool get isImage =>
      messageType == 'image' ||
      attachments.any((a) => a.mimeType.startsWith('image/')) ||
      (payload['media_url'] != null) ||
      (payload['local_path'] != null);

  String? get mediaUrl =>
      attachments.isNotEmpty
          ? (attachments.first.storagePath ?? attachments.first.localPath)
          : payload['media_url'] as String? ?? payload['local_path'] as String?;

  bool get isPending => syncStatus == 'pending';
  bool get isSending => syncStatus == 'sending';
  bool get isFailed => syncStatus == 'failed' || deliveryStatus == MessageDeliveryStatus.failed;

  @override
  List<Object?> get props => [
        id,
        messageSeq,
        channelId,
        senderId,
        senderDisplayName,
        messageType,
        body,
        payload,
        replyToId,
        replyToBody,
        replyToAuthor,
        version,
        createdAt,
        editedAt,
        deletedAt,
        fromMe,
        syncStatus,
        deliveryStatus,
        reactions,
        attachments,
      ];
}
