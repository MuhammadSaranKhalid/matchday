import 'chat.dart' show ChatId;

/// One line in a chat ledger. Soft-delete semantics — [deletedAt] non-null
/// means the message was removed by its sender; the row stays so quotes /
/// replies still resolve.
///
/// [senderId] is nullable because the column `messages.sender_id` is
/// `ON DELETE SET NULL` against `profiles` — when a profile is deleted the
/// row persists with `sender_id = NULL`. The UI renders "Deleted user" in
/// that case.
///
/// [senderDisplayName] is joined at fetch time from `profiles.display_name`
/// so the thread can render "Imran: …" without a per-row lookup.
/// [fromMe] is computed server-side / at fetch time so the widget can render
/// own-vs-other styling without re-checking auth.
class Message {
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderDisplayName,
    required this.body,
    required this.createdAt,
    required this.fromMe,
    this.messageType = 'text',
    this.mediaUrl,
    this.replyToId,
    this.replyToBody,
    this.replyToAuthor,
    this.editedAt,
    this.deletedAt,
  });

  final MessageId id;
  final ChatId chatId;
  final String? senderId;
  final String? senderDisplayName;
  final String body;
  final DateTime createdAt;
  final bool fromMe;
  final String messageType;
  final String? mediaUrl;
  final String? replyToId;
  final String? replyToBody;
  final String? replyToAuthor;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;
  bool get isImage => messageType == 'image' || (mediaUrl != null && mediaUrl!.isNotEmpty);

  @override
  bool operator ==(Object other) =>
      other is Message &&
      other.id == id &&
      other.chatId == chatId &&
      other.senderId == senderId &&
      other.senderDisplayName == senderDisplayName &&
      other.body == body &&
      other.createdAt == createdAt &&
      other.editedAt == editedAt &&
      other.deletedAt == deletedAt &&
      other.fromMe == fromMe &&
      other.messageType == messageType &&
      other.mediaUrl == mediaUrl &&
      other.replyToId == replyToId &&
      other.replyToBody == replyToBody &&
      other.replyToAuthor == replyToAuthor;

  @override
  int get hashCode => Object.hash(
        id,
        chatId,
        senderId,
        senderDisplayName,
        body,
        createdAt,
        editedAt,
        deletedAt,
        fromMe,
        messageType,
        mediaUrl,
        replyToId,
        replyToBody,
        replyToAuthor,
      );
}

class MessageId {
  const MessageId(this.value);
  final String value;

  @override
  bool operator ==(Object other) =>
      other is MessageId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
