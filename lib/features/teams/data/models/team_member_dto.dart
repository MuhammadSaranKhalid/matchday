import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';

part 'team_member_dto.freezed.dart';
part 'team_member_dto.g.dart';

/// Wire-format `team_members` row.
@freezed
abstract class TeamMemberDto with _$TeamMemberDto {
  const factory TeamMemberDto({
    @JsonKey(name: 'membership_id') required String membershipId,
    @JsonKey(name: 'team_id') required String teamId,
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'player_type') required String playerType,
    @JsonKey(name: 'jersey_number') int? jerseyNumber,
    @Default('player') String role,
    @JsonKey(name: 'added_by') required String addedBy,
    @JsonKey(name: 'joined_at') required String joinedAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _TeamMemberDto;

  const TeamMemberDto._();

  factory TeamMemberDto.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberDtoFromJson(json);

  TeamMember toEntity() => TeamMember(
        id: MembershipId(membershipId),
        teamId: TeamId(teamId),
        playerId: playerId,
        playerType: PlayerType.fromWire(playerType),
        role: MemberRole.fromWire(role),
        addedBy: addedBy,
        jerseyNumber: jerseyNumber,
        joinedAt: DateTime.parse(joinedAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
