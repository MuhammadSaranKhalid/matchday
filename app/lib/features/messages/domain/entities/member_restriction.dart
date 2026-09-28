import 'package:equatable/equatable.dart';

class MemberRestriction extends Equatable {
  const MemberRestriction({
    required this.restrictionId,
    required this.channelId,
    required this.userId,
    required this.permission,
    required this.startsAt,
    this.expiresAt,
  });

  final String restrictionId;
  final String channelId;
  final String userId;
  final String permission;
  final DateTime startsAt;
  final DateTime? expiresAt;

  bool get isActive {
    final now = DateTime.now();
    if (startsAt.isAfter(now)) return false;
    if (expiresAt != null && expiresAt!.isBefore(now)) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        restrictionId,
        channelId,
        userId,
        permission,
        startsAt,
        expiresAt,
      ];
}
