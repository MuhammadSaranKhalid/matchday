import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/entities/profile.dart';

part 'profile_dto.freezed.dart';
part 'profile_dto.g.dart';

/// Wire-format `profiles` row. `location` and `player_profile` are jsonb blobs,
/// decoded into a plain map and unpacked in [toEntity].
@freezed
abstract class ProfileDto with _$ProfileDto {
  const factory ProfileDto({
    @JsonKey(name: 'user_id') required String userId,
    String? username,
    @JsonKey(name: 'display_name') String? displayName,
    Map<String, dynamic>? location,
    @JsonKey(name: 'player_profile') Map<String, dynamic>? playerProfile,
  }) = _ProfileDto;

  const ProfileDto._();

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  Profile toEntity() => Profile(
        userId: ProfileUserId(userId),
        username: username,
        displayName: displayName,
        city: location?['city'] as String?,
        playerProfile: playerProfileFromMap(playerProfile),
      );

  /// jsonb → domain. Returns null when no attribute was set. Public + static so
  /// all `player_profile` wire knowledge lives on the DTO (see [playerProfileToMap]).
  static PlayerProfile? playerProfileFromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    final profile = PlayerProfile(
      role: PlayerRole.fromWire(m['role'] as String?),
      battingStyle: BattingStyle.fromWire(m['batting_style'] as String?),
      bowlingStyle: BowlingStyle.fromWire(m['bowling_style'] as String?),
      preferredBall: BallType.fromWire(m['preferred_ball'] as String?),
    );
    return profile.hasAny ? profile : null;
  }

  /// domain → jsonb. Omits unset attributes; returns null for an empty profile.
  static Map<String, dynamic>? playerProfileToMap(PlayerProfile? p) {
    if (p == null || !p.hasAny) return null;
    return {
      if (p.role != null) 'role': p.role!.wire,
      if (p.battingStyle != null) 'batting_style': p.battingStyle!.wire,
      if (p.bowlingStyle != null) 'bowling_style': p.bowlingStyle!.wire,
      if (p.preferredBall != null) 'preferred_ball': p.preferredBall!.wire,
    };
  }
}
