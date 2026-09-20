import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/cricket_player_profile.dart';

part 'cricket_player_profile_dto.freezed.dart';
part 'cricket_player_profile_dto.g.dart';

/// Wire-format `cricket_player_profiles` row.
///
/// The style fields are Postgres enums serialized as their label strings;
/// `preferred_ball_types` is a `ball_type[]`.
///
/// [sport_id] is always `'cricket'` — present on the wire to satisfy the
/// composite FK to `player_sports(user_id, sport_id)`.
@freezed
abstract class CricketPlayerProfileDto with _$CricketPlayerProfileDto {
  const factory CricketPlayerProfileDto({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'sport_id') @Default('cricket') String sportId,
    @JsonKey(name: 'batting_style') String? battingStyle,
    @JsonKey(name: 'bowling_style') String? bowlingStyle,
    @JsonKey(name: 'player_role') String? playerRole,
    @JsonKey(name: 'preferred_ball_types')
    @Default(<String>[])
    List<String> preferredBallTypes,
    @JsonKey(name: 'years_playing') int? yearsPlaying,
  }) = _CricketPlayerProfileDto;

  const CricketPlayerProfileDto._();

  factory CricketPlayerProfileDto.fromJson(Map<String, dynamic> json) =>
      _$CricketPlayerProfileDtoFromJson(json);

  /// Row → domain. Returns a [CricketPlayerProfile] regardless of whether any
  /// optional attributes were filled in — the row's existence confirms the
  /// Cricket player identity.
  CricketPlayerProfile toEntity() => CricketPlayerProfile(
        userId: CricketPlayerUserId(userId),
        role: PlayerRole.fromWire(playerRole),
        battingStyle: BattingStyle.fromWire(battingStyle),
        bowlingStyle: BowlingStyle.fromWire(bowlingStyle),
        preferredBallTypes: preferredBallTypes
            .map(BallType.fromWire)
            .whereType<BallType>()
            .toList(),
        yearsPlaying: yearsPlaying,
      );
}
