import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/player_profile.dart';

part 'player_profile_dto.freezed.dart';
part 'player_profile_dto.g.dart';

/// Wire-format `player_profiles` row (one per user, keyed by `user_id`). The
/// style fields are Postgres enums (serialized as their label strings) and
/// `preferred_ball_types` is a `ball_type[]`.
@freezed
abstract class PlayerProfileDto with _$PlayerProfileDto {
  const factory PlayerProfileDto({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'batting_style') String? battingStyle,
    @JsonKey(name: 'bowling_style') String? bowlingStyle,
    @JsonKey(name: 'player_role') String? playerRole,
    @JsonKey(name: 'preferred_ball_types')
    @Default(<String>[]) List<String> preferredBallTypes,
    @JsonKey(name: 'years_playing') int? yearsPlaying,
  }) = _PlayerProfileDto;

  const PlayerProfileDto._();

  factory PlayerProfileDto.fromJson(Map<String, dynamic> json) =>
      _$PlayerProfileDtoFromJson(json);

  /// Row → domain. Returns null when the row carries no usable attribute.
  PlayerProfile? toEntity() {
    final profile = PlayerProfile(
      role: PlayerRole.fromWire(playerRole),
      battingStyle: BattingStyle.fromWire(battingStyle),
      bowlingStyle: BowlingStyle.fromWire(bowlingStyle),
      preferredBallTypes: preferredBallTypes
          .map(BallType.fromWire)
          .whereType<BallType>()
          .toList(),
      yearsPlaying: yearsPlaying,
    );
    return profile.hasAny ? profile : null;
  }

  /// domain → write payload for `player_profiles` (without `user_id`, which the
  /// data source supplies). Unset attributes are omitted so they stay null.
  static Map<String, dynamic> toWritePayload(PlayerProfile p) => {
        if (p.role != null) 'player_role': p.role!.wire,
        if (p.battingStyle != null) 'batting_style': p.battingStyle!.wire,
        if (p.bowlingStyle != null) 'bowling_style': p.bowlingStyle!.wire,
        'preferred_ball_types':
            p.preferredBallTypes.map((b) => b.wire).toList(),
        if (p.yearsPlaying != null) 'years_playing': p.yearsPlaying,
      };
}
