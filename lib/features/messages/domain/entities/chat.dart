import '../../../teams/domain/entities/team.dart' show TeamId;

/// A chat — the addressable container for a conversation (Teams, DMs, Matches, Groups).
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
    this.dmOtherUserId,
    this.dmOtherUserName,
    this.dmOtherUserUsername,
    this.dmOtherUserAvatarUrl,
    this.youFollow = false,
    this.theyFollowYou = false,
  });

  final ChatId id;
  final ChatKind kind;
  final String name;
  final TeamId? teamId;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Crest display fields for team chats.
  final String? teamLogoUrl;
  final String? teamLogoMonogram;
  final String? teamPrimaryColorHex;

  /// DM recipient metadata.
  final String? dmOtherUserId;
  final String? dmOtherUserName;
  final String? dmOtherUserUsername;
  final String? dmOtherUserAvatarUrl;
  final bool youFollow;
  final bool theyFollowYou;

  /// Time of the most recent non-deleted message.
  final DateTime? lastMessageAt;

  /// Body of the latest non-deleted message.
  final String? lastMessagePreview;

  /// Sender id of the latest message.
  final String? lastMessageSenderId;

  /// True when the latest message was sent by the current user.
  final bool lastMessageFromMe;

  bool get isUnread => unreadCount > 0;
  bool get isEmpty => lastMessageAt == null;
  bool get isDm => kind == ChatKind.dm;
  bool get isTeam => kind == ChatKind.team;

  String get displayName {
    if (isDm) {
      if (dmOtherUserName != null && dmOtherUserName!.trim().isNotEmpty) {
        return dmOtherUserName!.trim();
      }
      if (dmOtherUserUsername != null && dmOtherUserUsername!.trim().isNotEmpty) {
        return '@${dmOtherUserUsername!.trim()}';
      }
      return 'Direct Message';
    }
    return name;
  }

  String get displayAvatarUrl => isDm ? (dmOtherUserAvatarUrl ?? '') : (teamLogoUrl ?? '');

  String get displayMonogram {
    if (isDm) {
      final n = displayName;
      return n.isNotEmpty ? n[0].toUpperCase() : '?';
    }
    return teamLogoMonogram?.toUpperCase() ?? '?';
  }

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
      other.dmOtherUserId == dmOtherUserId &&
      other.dmOtherUserName == dmOtherUserName &&
      other.dmOtherUserUsername == dmOtherUserUsername &&
      other.dmOtherUserAvatarUrl == dmOtherUserAvatarUrl &&
      other.youFollow == youFollow &&
      other.theyFollowYou == theyFollowYou &&
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
        dmOtherUserId,
        dmOtherUserName,
        dmOtherUserUsername,
        dmOtherUserAvatarUrl,
        youFollow,
        theyFollowYou,
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

/// Mirrors the `public.chat_type` Postgres enum.
enum ChatKind {
  team('team'),
  dm('dm'),
  match('match'),
  group('group');

  const ChatKind(this.wire);
  final String wire;

  static ChatKind fromWire(String wire) => values.firstWhere(
        (k) => k.wire == wire,
        orElse: () => ChatKind.team,
      );
}
