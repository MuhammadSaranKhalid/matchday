/// Internal transfer object used only while hydrating LocalChannelMembers.
///
/// There is no participant table behind this DTO. `channelRole` and
/// `membershipStatus` are the server channel_members role/status values.
class ChatParticipantDto {
  const ChatParticipantDto({
    required this.channelId,
    required this.userId,
    required this.displayName,
    this.username,
    this.avatarUrl,
    required this.channelRole,
    required this.membershipStatus,
    this.lastReadMessageSeq,
    this.lastReadAt,
    this.lastDeliveredMessageSeq,
    this.lastDeliveredAt,
    required this.updatedAt,
  });

  final String channelId;
  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String channelRole;
  final String membershipStatus;
  final int? lastReadMessageSeq;
  final DateTime? lastReadAt;
  final int? lastDeliveredMessageSeq;
  final DateTime? lastDeliveredAt;
  final DateTime updatedAt;
}
