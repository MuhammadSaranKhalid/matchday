import 'package:equatable/equatable.dart';

/// Read model used by Flutter when rendering a channel participant.
///
/// IMPORTANT: this is NOT another persisted participant/member model.
/// Every field comes from the single Drift row in `LocalChannelMembers` for
/// `(channelId, userId)`.
///
/// [channelRole] is the role inside CHAT CHANNEL membership (for example
/// member/admin/moderator/owner depending on the chat policy). It must not be
/// confused with Matchday's TEAM roster/authority roles such as manager,
/// captain or player, which live in the teams domain.
class ChatParticipant extends Equatable {
  const ChatParticipant({
    required this.channelId,
    required this.userId,
    required this.displayName,
    this.username,
    this.avatarUrl,
    required this.channelRole,
    required this.membershipStatus,
    this.lastReadMessageSeq,
    this.lastDeliveredMessageSeq,
  });

  final String channelId;
  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;

  /// Projection of `LocalChannelMembers.role` / server `channel_members.role`.
  final String channelRole;

  /// Projection of `LocalChannelMembers.status`.
  final String membershipStatus;

  final int? lastReadMessageSeq;
  final int? lastDeliveredMessageSeq;

  bool get isActive => membershipStatus == 'active';
  bool get isPending => membershipStatus == 'pending';

  @override
  List<Object?> get props => [
        channelId,
        userId,
        displayName,
        username,
        avatarUrl,
        channelRole,
        membershipStatus,
        lastReadMessageSeq,
        lastDeliveredMessageSeq,
      ];
}
