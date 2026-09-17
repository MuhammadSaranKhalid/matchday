import 'package:equatable/equatable.dart';

class ChannelMember extends Equatable {
  const ChannelMember({
    required this.channelId,
    required this.userId,
    this.role = 'member',
    this.status = 'active',
    this.joinedAt,
    this.leftAt,
    this.lastDeliveredMessageSeq,
    this.lastReadMessageSeq,
    this.notificationsMutedUntil,
    this.archivedAt,
    this.pinnedAt,
  });

  final String channelId;
  final String userId;
  final String role;
  final String status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final int? lastDeliveredMessageSeq;
  final int? lastReadMessageSeq;
  final DateTime? notificationsMutedUntil;
  final DateTime? archivedAt;
  final DateTime? pinnedAt;

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
  bool get isModerator => role == 'moderator' || role == 'admin' || role == 'owner';

  @override
  List<Object?> get props => [
        channelId,
        userId,
        role,
        status,
        joinedAt,
        leftAt,
        lastDeliveredMessageSeq,
        lastReadMessageSeq,
        notificationsMutedUntil,
        archivedAt,
        pinnedAt,
      ];
}
