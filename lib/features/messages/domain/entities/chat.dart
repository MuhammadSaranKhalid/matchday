import '../../../teams/domain/entities/team.dart' show TeamId;

/// A chat — the addressable container for a conversation. The chat itself
/// doesn't carry a name, crest, or member roster; those are derived from the
/// joined [teamId] via the teams feature (per CLAUDE.md §6.6 — the messages
/// screen ref.watches teams' presentation providers for crest + colour).
///
/// In v1, every chat is a team chat (one per team, schema enforces
/// `chat_type = 'team'`). When the schema grows DMs / tournament chats,
/// [kind] gains values and [teamId] becomes nullable in practice.
///
/// Sort key for the inbox is [lastMessageAt] desc, nulls last — matches the
/// `chats_last_message_at` index. Empty new chats settle at the bottom.
class Chat {
  const Chat({
    required this.id,
    required this.kind,
    required this.name,
    required this.teamId,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastMessageSenderId,
    this.lastMessageFromMe = false,
    this.teamLogoUrl,
    this.teamLogoMonogram,
    this.teamPrimaryColorHex,
  });

  final ChatId id;
  final ChatKind kind;
  final String name;
  final TeamId? teamId;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Crest display fields, denormalised onto the chat at fetch time so the
  /// inbox renders without a cross-feature lookup per row. Source: the
  /// joined `teams` row in the `list-my-chats` edge function. Null for
  /// future non-team chats.
  final String? teamLogoUrl;
  final String? teamLogoMonogram;
  final String? teamPrimaryColorHex;

  /// Time of the most recent non-deleted message in this chat, or null if the
  /// chat has no messages yet. Maintained server-side by the
  /// `bump_chat_last_message_at` trigger.
  final DateTime? lastMessageAt;

  /// Body of the latest non-deleted message, untruncated. The screen
  /// truncates for display.
  final String? lastMessagePreview;

  /// Sender id of the latest message — raw String because the column is
  /// nullable (profile may be deleted) and avoids a wrapper for a value the
  /// presentation never needs to compare against a strongly-typed id.
  final String? lastMessageSenderId;

  /// True when the latest message was sent by the current user. Set by the
  /// repository at fetch time so the screen can render a "You: …" prefix
  /// without re-checking auth.
  final bool lastMessageFromMe;

  bool get isUnread => unreadCount > 0;
  bool get isEmpty => lastMessageAt == null;

  @override
  bool operator ==(Object other) =>
      other is Chat &&
      other.id == id &&
      other.kind == kind &&
      other.name == name &&
      other.teamId == teamId &&
      other.unreadCount == unreadCount &&
      other.lastMessageAt == lastMessageAt &&
      other.lastMessagePreview == lastMessagePreview &&
      other.lastMessageSenderId == lastMessageSenderId &&
      other.lastMessageFromMe == lastMessageFromMe &&
      other.teamLogoUrl == teamLogoUrl &&
      other.teamLogoMonogram == teamLogoMonogram &&
      other.teamPrimaryColorHex == teamPrimaryColorHex &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        name,
        teamId,
        unreadCount,
        lastMessageAt,
        lastMessagePreview,
        lastMessageSenderId,
        lastMessageFromMe,
        teamLogoUrl,
        teamLogoMonogram,
        teamPrimaryColorHex,
        createdAt,
        updatedAt,
      );
}

class ChatId {
  const ChatId(this.value);
  final String value;

  @override
  bool operator ==(Object other) => other is ChatId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Mirrors the `public.chat_type` Postgres enum. Only `team` exists in v1.
enum ChatKind {
  team('team');

  const ChatKind(this.wire);
  final String wire;

  static ChatKind fromWire(String wire) => values.firstWhere(
        (k) => k.wire == wire,
        orElse: () => ChatKind.team,
      );
}
