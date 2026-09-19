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

/// Universal message entity consumed directly by presentation.
///
/// Sender identity is resolved from LocalChannelMembers when available. The
/// message's senderDisplayName remains a fallback snapshot for history.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    this.messageSeq,
    required this.channelId,
    this.senderId,
    this.senderDisplayName,
    this.senderUsername,
    this.senderAvatarUrl,
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
  final String? senderUsername;
  final String? senderAvatarUrl;

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
  bool get isPending => syncStatus == 'pending';
  bool get isSending => syncStatus == 'sending';
  bool get isFailed =>
      syncStatus == 'failed' || deliveryStatus == MessageDeliveryStatus.failed;

  bool get isImage =>
      messageType == 'image' ||
      attachments.any((a) => a.mimeType.startsWith('image/')) ||
      localMediaPath != null ||
      storageMediaPath != null;

  /// Local outbox/cache file, if it still exists on this device.
  String? get localMediaPath {
    if (attachments.isNotEmpty) {
      final value = attachments.first.localPath;
      if (value != null && value.isNotEmpty) return value;
    }

    final value = payload['local_path'];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Supabase Storage path or an already-resolved HTTP URL.
  String? get storageMediaPath {
    if (attachments.isNotEmpty) {
      final value = attachments.first.storagePath;
      if (value != null && value.isNotEmpty) return value;
    }

    final value = payload['media_url'];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Backward-compatible display reference. Widgets should prefer the
  /// explicit local/storage getters so private storage paths can be signed.
  String? get mediaUrl => localMediaPath ?? storageMediaPath;

  ChatMessage copyWith({
    String? senderDisplayName,
    String? senderUsername,
    String? senderAvatarUrl,
    String? replyToBody,
    String? replyToAuthor,
    MessageDeliveryStatus? deliveryStatus,
    String? syncStatus,
  }) {
    return ChatMessage(
      id: id,
      messageSeq: messageSeq,
      channelId: channelId,
      senderId: senderId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderUsername: senderUsername ?? this.senderUsername,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      messageType: messageType,
      body: body,
      payload: payload,
      replyToId: replyToId,
      replyToBody: replyToBody ?? this.replyToBody,
      replyToAuthor: replyToAuthor ?? this.replyToAuthor,
      version: version,
      createdAt: createdAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
      fromMe: fromMe,
      syncStatus: syncStatus ?? this.syncStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      reactions: reactions,
      attachments: attachments,
    );
  }

  /// Adds a locally resolved quoted-message preview without duplicating the
  /// relationship in storage.
  ChatMessage withReplyPreview({
    String? body,
    String? author,
  }) {
    return ChatMessage(
      id: id,
      messageSeq: messageSeq,
      channelId: channelId,
      senderId: senderId,
      senderDisplayName: senderDisplayName,
      senderUsername: senderUsername,
      senderAvatarUrl: senderAvatarUrl,
      messageType: messageType,
      body: this.body,
      payload: payload,
      replyToId: replyToId,
      replyToBody: body,
      replyToAuthor: author,
      version: version,
      createdAt: createdAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
      fromMe: fromMe,
      syncStatus: syncStatus,
      deliveryStatus: deliveryStatus,
      reactions: reactions,
      attachments: attachments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        messageSeq,
        channelId,
        senderId,
        senderDisplayName,
        senderUsername,
        senderAvatarUrl,
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
