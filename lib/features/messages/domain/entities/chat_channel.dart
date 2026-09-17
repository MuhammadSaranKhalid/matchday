import 'package:equatable/equatable.dart';

enum ChatChannelKind {
  direct('direct'),
  group('group'),
  broadcast('broadcast');

  const ChatChannelKind(this.wire);
  final String wire;

  static ChatChannelKind fromWire(String wire) => values.firstWhere(
        (k) => k.wire == wire,
        orElse: () => ChatChannelKind.group,
      );
}

enum ChatChannelContext {
  none('none'),
  team('team'),
  match('match'),
  tournament('tournament'),
  club('club');

  const ChatChannelContext(this.wire);
  final String wire;

  static ChatChannelContext fromWire(String wire) => values.firstWhere(
        (c) => c.wire == wire,
        orElse: () => ChatChannelContext.none,
      );
}

/// The universal conversation container entity in Match Day Chat Architecture.
class ChatChannel extends Equatable {
  const ChatChannel({
    required this.id,
    required this.channelKey,
    required this.kind,
    required this.contextType,
    required this.name,
    this.description,
    this.avatarUrl,
    this.teamId,
    this.matchId,
    this.tournamentId,
    this.clubId,
    this.lastMessageSeq,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastMessageSenderId,
    this.lastMessageFromMe = false,
    this.unreadCount = 0,
    this.isAccepted = true,
    this.isPinned = false,
    this.isArchived = false,
    this.isMuted = false,
    this.dmOtherUserId,
    this.dmOtherUserName,
    this.dmOtherUserUsername,
    this.dmOtherUserAvatarUrl,
    this.dmOtherMemberStatus,
    this.youFollow = false,
    this.theyFollowYou = false,
    this.teamName,
    this.teamLogoUrl,
    this.teamLogoMonogram,
    this.teamPrimaryColorHex,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String channelKey;
  final ChatChannelKind kind;
  final ChatChannelContext contextType;
  final String name;
  final String? description;
  final String? avatarUrl;

  final String? teamId;
  final String? matchId;
  final String? tournamentId;
  final String? clubId;

  final int? lastMessageSeq;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final String? lastMessageSenderId;
  final bool lastMessageFromMe;
  final int unreadCount;

  final bool isAccepted;
  final bool isPinned;
  final bool isArchived;
  final bool isMuted;

  // Direct Message counterpart metadata
  final String? dmOtherUserId;
  final String? dmOtherUserName;
  final String? dmOtherUserUsername;
  final String? dmOtherUserAvatarUrl;
  final String? dmOtherMemberStatus;
  final bool youFollow;
  final bool theyFollowYou;

  // Entity-specific presentation data
  final String? teamName;
  final String? teamLogoUrl;
  final String? teamLogoMonogram;
  final String? teamPrimaryColorHex;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isUnread => unreadCount > 0;
  bool get isEmpty => lastMessageAt == null;
  bool get isDm => kind == ChatChannelKind.direct;
  bool get isTeam => contextType == ChatChannelContext.team;
  bool get isMatch => contextType == ChatChannelContext.match;
  bool get isGroup => kind == ChatChannelKind.group && contextType == ChatChannelContext.none;

  /// Incoming message request waiting for recipient approval
  bool get isRequest => isDm && !isAccepted && !lastMessageFromMe && !youFollow;

  /// Outgoing message request waiting for recipient approval
  bool get isPendingOutgoingRequest =>
      isDm &&
      ((!isAccepted && lastMessageFromMe && !theyFollowYou) ||
       (isAccepted && dmOtherMemberStatus == 'pending' && !theyFollowYou));

  String get displayName {
    if (isDm) {
      if (dmOtherUserName != null && dmOtherUserName!.trim().isNotEmpty) {
        return dmOtherUserName!.trim();
      }
      if (dmOtherUserUsername != null && dmOtherUserUsername!.trim().isNotEmpty) {
        return '@${dmOtherUserUsername!.trim()}';
      }
      if (name.trim().isNotEmpty && name.trim().toLowerCase() != 'direct message') {
        return name.trim();
      }
      return 'Direct Message';
    }
    if (isTeam && teamName != null) {
      return teamName!;
    }
    return name;
  }

  String get displayAvatarUrl => isDm ? (dmOtherUserAvatarUrl ?? '') : (teamLogoUrl ?? avatarUrl ?? '');

  String get displayMonogram {
    if (isDm) {
      final n = displayName;
      return n.isNotEmpty ? n[0].toUpperCase() : '?';
    }
    if (isMatch) {
      return 'VS';
    }
    return teamLogoMonogram?.toUpperCase() ?? (name.isNotEmpty ? name[0].toUpperCase() : '?');
  }

  @override
  List<Object?> get props => [
        id,
        channelKey,
        kind,
        contextType,
        name,
        description,
        avatarUrl,
        teamId,
        matchId,
        tournamentId,
        clubId,
        lastMessageSeq,
        lastMessageAt,
        lastMessagePreview,
        lastMessageSenderId,
        lastMessageFromMe,
        unreadCount,
        isAccepted,
        isPinned,
        isArchived,
        isMuted,
        dmOtherUserId,
        dmOtherUserName,
        dmOtherUserUsername,
        dmOtherUserAvatarUrl,
        dmOtherMemberStatus,
        youFollow,
        theyFollowYou,
        teamName,
        teamLogoUrl,
        teamLogoMonogram,
        teamPrimaryColorHex,
        createdAt,
        updatedAt,
      ];
}
