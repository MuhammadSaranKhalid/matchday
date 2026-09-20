import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/match_player.dart';

part 'match_player_dto.freezed.dart';
part 'match_player_dto.g.dart';

/// Cricket-facing participant DTO after the Phase 3A physical split.
///
/// `match_players` contains only sport-neutral participant identity/snapshot
/// facts. All Cricket match state is read from the embedded one-to-one
/// `cricket_match_players` row.
///
/// There is intentionally no fallback to legacy `role`, `is_in_playing_xi`,
/// or `batting_order` columns: those columns no longer exist.
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
    @JsonKey(includeToJson: false) Map<String, dynamic>? profile,
    @JsonKey(includeToJson: false) Map<String, dynamic>? unclaimed,
  }) = _MatchPlayerDto;

  const MatchPlayerDto._();

  factory MatchPlayerDto.fromJson(Map<String, dynamic> json) {
    final modified = Map<String, dynamic>.from(json);

    modified['match_player_id'] =
        (modified['match_player_id'] ?? modified['id'] ?? '').toString();
    modified['match_id'] = (modified['match_id'] ?? '').toString();
    modified['team_side'] =
        (modified['team_side'] ?? 'team_a').toString();

    if (modified['profile_id'] == null && modified['user_id'] != null) {
      modified['profile_id'] = modified['user_id'];
    }

    final cricketRaw = modified['cricket'];
    Map<String, dynamic>? cricket;

    if (cricketRaw is Map) {
      cricket = Map<String, dynamic>.from(cricketRaw);
    } else if (cricketRaw is List && cricketRaw.isNotEmpty) {
      final first = cricketRaw.first;
      if (first is Map) {
        cricket = Map<String, dynamic>.from(first);
      }
    }

    if (cricket != null) {
      modified['batting_order'] = cricket['batting_order'];
      modified['is_captain'] = cricket['is_captain'] == true;
      modified['is_keeper'] = cricket['is_wicket_keeper'] == true;
      modified['is_substitute'] = cricket['is_substitute'] == true;
    }

    if (modified['display_name'] != null &&
        modified['profile'] == null &&
        modified['unclaimed'] == null) {
      modified['unclaimed'] = {
        'display_name': modified['display_name'],
      };
    }

    return _$MatchPlayerDtoFromJson(modified);
  }

  Map<String, dynamic> toJson() =>
      _$MatchPlayerDtoToJson(this as _MatchPlayerDto);

  String get displayName {
    final source = profile ?? unclaimed;

    final name = (source?['display_name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;

    final username = (profile?['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;

    return unclaimedId != null ? 'Offline player' : 'Player';
  }

  String? get photoUrl {
    final url = (profile?['profile_photo_url'] as String?)?.trim();
    return (url == null || url.isEmpty) ? null : url;
  }

  MatchPlayer toEntity() => MatchPlayer(
        id: MatchPlayerId(matchPlayerId),
        matchId: MatchId(matchId),
        teamSide: MatchTeamSide.fromWire(teamSide),
        profileId: profileId,
        unclaimedId: unclaimedId,
        displayName: displayName,
        photoUrl: photoUrl,
        battingOrder: battingOrder,
        jerseyNumber: jerseyNumber,
        isCaptain: isCaptain,
        isKeeper: isKeeper,
        isSubstitute: isSubstitute,
      );
}
