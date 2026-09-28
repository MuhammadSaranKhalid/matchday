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

/// Universal conversation container consumed directly by presentation.
///
/// This replaces the legacy Chat adapter. The UI should not collapse
/// `kind + contextType` into a smaller enum because doing so loses the
/// difference between generic groups, teams, matches, tournaments and clubs.
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
    this.lastReadMessageSeq,
    this.lastDeliveredMessageSeq,
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

  /// Durable horizons for the current user's membership. These make unread
  /// boundaries stable while older history is paginated into the timeline.
  final int? lastReadMessageSeq;
  final int? lastDeliveredMessageSeq;

  final bool isAccepted;
  final bool isPinned;
  final bool isArchived;
  final bool isMuted;

  // DM counterpart metadata projected by list_my_chats for fast inbox paint.
  final String? dmOtherUserId;
  final String? dmOtherUserName;
  final String? dmOtherUserUsername;
  final String? dmOtherUserAvatarUrl;
  final String? dmOtherMemberStatus;
  final bool youFollow;
  final bool theyFollowYou;

  // Team presentation metadata projected by list_my_chats.
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
  bool get isTournament => contextType == ChatChannelContext.tournament;
  bool get isClub => contextType == ChatChannelContext.club;
  bool get isGroup =>
      kind == ChatChannelKind.group && contextType == ChatChannelContext.none;

  bool get isMultiParticipant => !isDm;

  /// Existing server contract still represents a DM request through the
  /// current membership projection. Keep this logic centralized in the domain
  /// entity until the server exposes an explicit request-state field.
  bool get isRequest =>
      isDm && !isAccepted && !lastMessageFromMe && !youFollow;

  bool get isPendingOutgoingRequest =>
      isDm &&
      ((!isAccepted && lastMessageFromMe && !theyFollowYou) ||
          (isAccepted &&
              dmOtherMemberStatus == 'pending' &&
              !theyFollowYou));

  String get displayName {
    if (isDm) {
      final name = dmOtherUserName?.trim();
      if (name != null && name.isNotEmpty) return name;

      final username = dmOtherUserUsername?.trim();
      if (username != null && username.isNotEmpty) return '@$username';

      final raw = this.name.trim();
      if (raw.isNotEmpty && raw.toLowerCase() != 'direct message') return raw;
      return 'Direct Message';
    }

    if (isTeam && teamName?.trim().isNotEmpty == true) {
      return teamName!.trim();
    }

    final raw = name.trim();
    if (raw.isNotEmpty) return raw;

    return switch (contextType) {
      ChatChannelContext.match => 'Match Room',
      ChatChannelContext.tournament => 'Tournament Chat',
      ChatChannelContext.club => 'Club Chat',
      ChatChannelContext.team => 'Team Chat',
      ChatChannelContext.none => 'Group Chat',
    };
  }

  String? get displayAvatarUrl {
    if (isDm) return dmOtherUserAvatarUrl;
    if (isTeam) return teamLogoUrl ?? avatarUrl;
    return avatarUrl;
  }

  String get displayMonogram {
    if (isDm) return _initials(displayName);
    if (isMatch) return 'VS';
    if (teamLogoMonogram?.trim().isNotEmpty == true) {
      return teamLogoMonogram!.trim().toUpperCase();
    }
    return _initials(displayName);
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0].toUpperCase()).join();
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
        lastReadMessageSeq,
        lastDeliveredMessageSeq,
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
