import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/follow.dart';

part 'follow_dto.freezed.dart';
part 'follow_dto.g.dart';

/// Wire-format mirror of the `public.follows` table row.
///
/// Column names from migration 0560:
///   follow_id, follower_id, target_type, target_id, status,
///   notifications_enabled, created_at
///
/// There is no `updated_at` on this table — follows are immutable once created
/// (only deleted or muted). [status] and [notificationsEnabled] can change via
/// an UPDATE but the DTO is reconstructed from a fresh SELECT in those cases.
@freezed
abstract class FollowDto with _$FollowDto {
  const factory FollowDto({
    @JsonKey(name: 'follow_id') required String followId,
    @JsonKey(name: 'follower_id') required String followerId,
    @JsonKey(name: 'target_type') required String targetType,
    @JsonKey(name: 'target_id') required String targetId,
    @Default('active') String status,
    @JsonKey(name: 'notifications_enabled')
    @Default(true)
    bool notificationsEnabled,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _FollowDto;

  // REQUIRED: private constructor allows the toEntity() custom method.
  const FollowDto._();

  factory FollowDto.fromJson(Map<String, dynamic> json) =>
      _$FollowDtoFromJson(json);

  /// Maps wire data to the domain [Follow] entity.
  ///
  /// [targetType] dispatches to the correct [FollowTarget] sealed subtype.
  /// Unknown target types fall through to [TournamentFollowTarget] (safest
  /// forward-compatible default — won't crash, won't match User/Team paths).
  Follow toEntity() => Follow(
        id: FollowId(followId),
        followerId: UserId(followerId),
        target: _parseTarget(),
        status: FollowStatus.fromWire(status),
        notificationsEnabled: notificationsEnabled,
        createdAt: DateTime.parse(createdAt),
      );

  FollowTarget _parseTarget() {
    switch (targetType) {
      case 'user':
        return UserFollowTarget(UserId(targetId));
      case 'team':
        return TeamFollowTarget(TeamId(targetId));
      default:
        // Covers 'tournament' and any future types added server-side.
        return TournamentFollowTarget(targetId);
    }
  }
}
