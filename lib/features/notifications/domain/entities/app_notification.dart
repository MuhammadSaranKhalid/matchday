/// One in-app notification. Mirrors the deployed `public.notifications`
/// table 1:1; the `payload` jsonb carries per-type extra context (e.g.
/// `request_id` for match_request, `team_id` for team_invitation).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  final NotificationId id;
  final String recipientId;
  final NotificationType type;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        recipientId: recipientId,
        type: type,
        payload: payload,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  /// Where this notification belongs in the inbox. Derived client-side from
  /// the [type] — the deployed schema doesn't carry a tier column. Match the
  /// design's 3-tier model: now (REPLY NOW), week (THIS WEEK), fyi.
  NotificationTier get tier {
    switch (type) {
      case NotificationType.matchRequest:
      case NotificationType.matchStarting:
      case NotificationType.claimDecision:
        return NotificationTier.now;
      case NotificationType.matchRequestDecision:
      case NotificationType.matchUpcoming:
      case NotificationType.teamInvitation:
        return NotificationTier.week;
      case NotificationType.statMilestone:
      case NotificationType.postLike:
      case NotificationType.postComment:
      case NotificationType.commentReply:
      case NotificationType.mention:
      case NotificationType.teamPost:
      case NotificationType.tournamentPost:
      case NotificationType.follow:
        return NotificationTier.fyi;
    }
  }

  /// True for the small set of types that promote to the urgent (red bar)
  /// styling regardless of tier.
  bool get isUrgent =>
      type == NotificationType.matchRequest ||
      type == NotificationType.matchStarting;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification && other.id == id && other.isRead == isRead;

  @override
  int get hashCode => Object.hash(id, isRead);
}

class NotificationId {
  const NotificationId(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      other is NotificationId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

/// Mirrors the deployed `public.notification_type` enum.
enum NotificationType {
  follow('follow'),
  postLike('post_like'),
  postComment('post_comment'),
  commentReply('comment_reply'),
  mention('mention'),
  teamPost('team_post'),
  tournamentPost('tournament_post'),
  matchStarting('match_starting'),
  matchUpcoming('match_upcoming'),
  statMilestone('stat_milestone'),
  claimDecision('claim_decision'),
  teamInvitation('team_invitation'),
  matchRequest('match_request'),
  matchRequestDecision('match_request_decision');

  const NotificationType(this.wire);
  final String wire;
  static NotificationType fromWire(String? w) =>
      values.where((s) => s.wire == w).firstOrNull ?? NotificationType.follow;
}

/// Derived client-side; the design's three-tier inbox model.
enum NotificationTier {
  /// Reply now — needs immediate action.
  now,

  /// This week — soft deadline.
  week,

  /// FYI — celebrate, file away.
  fyi,
}

/// Platform the device token came from. Mirrors the loose `text` column in
/// `device_tokens.platform`.
enum DevicePlatform {
  ios('ios'),
  android('android');

  const DevicePlatform(this.wire);
  final String wire;
}
