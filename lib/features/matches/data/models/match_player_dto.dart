import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/match_player.dart';

part 'match_player_dto.freezed.dart';
part 'match_player_dto.g.dart';

/// Wire-format `match_players` row. The XOR on (`profile_id`,
/// `unclaimed_id`) is enforced by the table; this DTO mirrors it as two
/// nullable columns and lets the entity's assert catch any drift.
///
/// [profile] / [unclaimed] are the embedded PostgREST joins that resolve
/// whichever side of the XOR is set into a name + avatar. Exactly one is
/// populated on a well-formed row — except when the referenced profile is
/// suspended or deleted, which RLS filters out of the embed; [displayName]
/// degrades to a placeholder rather than a blank row in that case.
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
    modified['match_player_id'] = (modified['match_player_id'] ?? modified['id'] ?? '').toString();
    modified['match_id'] = (modified['match_id'] ?? '').toString();
    modified['team_side'] = (modified['team_side'] ?? 'team_a').toString();
    if (modified['profile_id'] == null && modified['user_id'] != null) {
      modified['profile_id'] = modified['user_id'];
    }
    final role = modified['role'] as String?;
    if (role != null) {
      if (role == 'captain') modified['is_captain'] = true;
      if (role == 'wicket_keeper') modified['is_keeper'] = true;
    }
    if (modified.containsKey('is_in_playing_xi') && !modified.containsKey('is_substitute')) {
      modified['is_substitute'] = modified['is_in_playing_xi'] == false;
    }
    if (modified['display_name'] != null && modified['profile'] == null && modified['unclaimed'] == null) {
      modified['unclaimed'] = {'display_name': modified['display_name']};
    }
    return _$MatchPlayerDtoFromJson(modified);
  }

  Map<String, dynamic> toJson() => _$MatchPlayerDtoToJson(this as _MatchPlayerDto);

  /// Best available human-readable name, in descending order of quality.
  /// Never empty — a nameless row in the XI would render as a blank tile in
  /// the bowler/batter pickers, which is worse than a placeholder.
  String get displayName {
    final source = profile ?? unclaimed;
    final name = (source?['display_name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final username = (profile?['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    return unclaimedId != null ? 'Offline player' : 'Player';
  }

  /// Avatar URL into the public `avatars` bucket. Always null for unclaimed
  /// placeholders — they have no photo column, by design: the person has not
  /// joined yet. Their monogram stands in until they claim the profile, at
  /// which point `cascade_unclaimed_claim` rewrites this row to a
  /// `profile_id` and the photo appears on past matches too.
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
