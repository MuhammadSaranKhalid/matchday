import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/player_skills.dart';
import '../../domain/entities/unclaimed_player.dart';

part 'unclaimed_player_dto.freezed.dart';
part 'unclaimed_player_dto.g.dart';

/// Wire-format `unclaimed_players` row.
@freezed
abstract class UnclaimedPlayerDto with _$UnclaimedPlayerDto {
  const factory UnclaimedPlayerDto({
    @JsonKey(name: 'unclaimed_id') required String unclaimedId,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'added_by') required String addedBy,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'player_profile')
    @Default(<String, dynamic>{})
    Map<String, dynamic> playerProfile,
  }) = _UnclaimedPlayerDto;

  const UnclaimedPlayerDto._();

  factory UnclaimedPlayerDto.fromJson(Map<String, dynamic> json) =>
      _$UnclaimedPlayerDtoFromJson(json);

  UnclaimedPlayer toEntity() => UnclaimedPlayer(
        id: UnclaimedPlayerId(unclaimedId),
        displayName: displayName,
        addedBy: addedBy,
        phoneNumber: phoneNumber,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        playingRole: PlayingRole.fromWire(playerProfile['playing_role'] as String?),
        battingStyle:
            BattingStyle.fromWire(playerProfile['batting_style'] as String?),
        bowlingStyle:
            BowlingStyle.fromWire(playerProfile['bowling_style'] as String?),
      );
}
