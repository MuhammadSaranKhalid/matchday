import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';

part 'team_member_dto.freezed.dart';
part 'team_member_dto.g.dart';

/// Wire-format `team_members` row.
///
/// The table holds two real FK columns — `user_id` (claimed players) and
/// `unclaimed_id` (placeholders) — with an XOR check constraint enforcing
/// exactly one is set. The DTO carries both as nullable strings; [toEntity]
/// resolves the polymorphic [TeamMember.playerId] + [TeamMember.playerType]
/// pair at the boundary.
@freezed
abstract class TeamMemberDto with _$TeamMemberDto {
  const factory TeamMemberDto({
    @JsonKey(name: 'membership_id') required String membershipId,
    @JsonKey(name: 'team_id') required String teamId,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'unclaimed_id') String? unclaimedId,
    @JsonKey(name: 'jersey_number') int? jerseyNumber,
    @Default('player') String role,
    // Nullable since 2026-09-06: ON DELETE SET NULL, so the roster row
    // survives the person who added it deleting their account.
    @JsonKey(name: 'added_by') String? addedBy,
    @JsonKey(name: 'joined_at') required String joinedAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _TeamMemberDto;

  const TeamMemberDto._();

  factory TeamMemberDto.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberDtoFromJson(json);

  TeamMember toEntity() {
    // XOR check on the DB side guarantees exactly one is set, but be
    // defensive at the boundary (renaming a column or a partial select
    // shouldn't crash the app).
    final isClaimed = userId != null;
    final pid = userId ?? unclaimedId ?? '';
    return TeamMember(
      id: MembershipId(membershipId),
      teamId: TeamId(teamId),
      playerId: pid,
      playerType: isClaimed ? PlayerType.claimed : PlayerType.unclaimed,
      role: MemberRole.fromWire(role),
      addedBy: addedBy,
      jerseyNumber: jerseyNumber,
      joinedAt: DateTime.parse(joinedAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
