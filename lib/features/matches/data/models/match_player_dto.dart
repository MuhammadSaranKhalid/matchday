import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/match_player.dart';

part 'match_player_dto.freezed.dart';
part 'match_player_dto.g.dart';

/// Wire-format `match_players` row. The XOR on (`profile_id`,
/// `unclaimed_id`) is enforced by the table; this DTO mirrors it as two
/// nullable columns and lets the entity's assert catch any drift.
@freezed
abstract class MatchPlayerDto with _$MatchPlayerDto {
  const factory MatchPlayerDto({
    @JsonKey(name: 'match_player_id') required String matchPlayerId,
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'team_side') required String teamSide,
    @JsonKey(name: 'profile_id') String? profileId,
    @JsonKey(name: 'unclaimed_id') String? unclaimedId,
    @JsonKey(name: 'batting_order') int? battingOrder,
    @JsonKey(name: 'jersey_number') int? jerseyNumber,
    @JsonKey(name: 'is_captain') @Default(false) bool isCaptain,
    @JsonKey(name: 'is_keeper') @Default(false) bool isKeeper,
    @JsonKey(name: 'is_substitute') @Default(false) bool isSubstitute,
  }) = _MatchPlayerDto;

  const MatchPlayerDto._();

  factory MatchPlayerDto.fromJson(Map<String, dynamic> json) =>
      _$MatchPlayerDtoFromJson(json);

  MatchPlayer toEntity() => MatchPlayer(
        id: MatchPlayerId(matchPlayerId),
        matchId: MatchId(matchId),
        teamSide: MatchTeamSide.fromWire(teamSide),
        profileId: profileId,
        unclaimedId: unclaimedId,
        battingOrder: battingOrder,
        jerseyNumber: jerseyNumber,
        isCaptain: isCaptain,
        isKeeper: isKeeper,
        isSubstitute: isSubstitute,
      );
}
