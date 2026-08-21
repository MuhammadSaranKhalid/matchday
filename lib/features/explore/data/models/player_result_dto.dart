import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/player_result.dart';

part 'player_result_dto.freezed.dart';
part 'player_result_dto.g.dart';

/// One row from `search-all`'s player group.
///
/// The function unions `profiles` and `unclaimed_players` into a single
/// shape, so this one DTO covers both; [playerType] discriminates.
@freezed
abstract class PlayerResultDto with _$PlayerResultDto {
  const factory PlayerResultDto({
    @JsonKey(name: 'player_type') required String playerType,
    required String id,
    required String name,
    String? username,
    @JsonKey(name: 'photo_url') String? photoUrl,
    String? city,
    @JsonKey(name: 'player_role') String? playerRole,
    @JsonKey(name: 'batting_style') String? battingStyle,
    @JsonKey(name: 'bowling_style') String? bowlingStyle,
    @JsonKey(name: 'team_context') String? teamContext,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'follower_count') @Default(0) int followerCount,
    @Default(0.0) double score,
  }) = _PlayerResultDto;

  const PlayerResultDto._();

  factory PlayerResultDto.fromJson(Map<String, dynamic> json) =>
      _$PlayerResultDtoFromJson(json);

  PlayerResult toEntity() => PlayerResult(
        id: id,
        // Unknown discriminators fall back to `unclaimed` rather than
        // throwing: a new server-side player kind should degrade to the more
        // conservative rendering (no handle, no follow), not crash the list.
        kind: playerType == 'profile' ? PlayerKind.profile : PlayerKind.unclaimed,
        name: name,
        score: score,
        username: username,
        photoUrl: photoUrl,
        city: city,
        playerRole: playerRole,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
        teamContext: teamContext,
        isVerified: isVerified,
        followerCount: followerCount,
      );
}
