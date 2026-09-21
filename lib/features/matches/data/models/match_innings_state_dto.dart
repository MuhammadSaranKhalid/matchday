import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';

part 'match_innings_state_dto.freezed.dart';
part 'match_innings_state_dto.g.dart';

/// Coerce a wire number that may arrive as a JSON string.
///
/// `version` is a Postgres `bigint`, and this row reaches the client by two
/// different routes that serialise it differently:
///
///   * the realtime broadcast, built with `to_jsonb(new)` → a JSON **number**
///   * the `record-ball` reply, read over a direct postgres.js connection,
///     which renders bigint as a **string** to avoid JS precision loss
///
/// The DTO has to accept both. It did not, and the consequence was severe:
/// parsing the reply threw `type 'String' is not a subtype of type 'num?'`,
/// the repository turned that into a failure, and the delivery was rolled
/// back — so every ball would have looked like a failed write while the
/// server had in fact recorded it.
int intFromWire(Object? v) => switch (v) {
  null => 0,
  final int i => i,
  final num n => n.toInt(),
  final String s => int.tryParse(s) ?? 0,
  _ => 0,
};

/// Wire-format `match_innings_state` row. One row per
/// (match_id, innings_number). The on-field trio columns are
/// match_player_ids — translation back to a profile or unclaimed
/// placeholder happens via the MatchPlayer entity.
@freezed
abstract class MatchInningsStateDto with _$MatchInningsStateDto {
  const factory MatchInningsStateDto({
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'innings_number') required int inningsNumber,
    @JsonKey(name: 'striker_id') String? strikerId,
    @JsonKey(name: 'non_striker_id') String? nonStrikerId,
    @JsonKey(name: 'bowler_id') String? bowlerId,
    @JsonKey(name: 'legal_ball_count') @Default(0) int legalBallCount,
    @JsonKey(name: 'total_runs') @Default(0) int totalRuns,
    @JsonKey(name: 'total_wickets') @Default(0) int totalWickets,
    @JsonKey(name: 'total_extras') @Default(0) int totalExtras,
    @JsonKey(name: 'is_declared') @Default(false) bool isDeclared,
    @JsonKey(name: 'is_all_out') @Default(false) bool isAllOut,
    int? target,
    @JsonKey(fromJson: intFromWire) @Default(0) int version,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _MatchInningsStateDto;

  const MatchInningsStateDto._();

  factory MatchInningsStateDto.fromJson(Map<String, dynamic> json) {
    final modified = Map<String, dynamic>.from(json);
    modified['match_id'] =
        (modified['match_id'] ?? modified['id'] ?? '').toString();
    modified['updated_at'] =
        (modified['updated_at'] ?? DateTime.now().toIso8601String()).toString();
    return _$MatchInningsStateDtoFromJson(modified);
  }

  Map<String, dynamic> toJson() =>
      _$MatchInningsStateDtoToJson(this as _MatchInningsStateDto);

  MatchInningsState toEntity() => MatchInningsState(
    matchId: MatchId(matchId),
    inningsNumber: inningsNumber,
    strikerId: strikerId == null ? null : MatchPlayerId(strikerId!),
    nonStrikerId: nonStrikerId == null ? null : MatchPlayerId(nonStrikerId!),
    bowlerId: bowlerId == null ? null : MatchPlayerId(bowlerId!),
    legalBallCount: legalBallCount,
    totalRuns: totalRuns,
    totalWickets: totalWickets,
    totalExtras: totalExtras,
    isDeclared: isDeclared,
    isAllOut: isAllOut,
    target: target,
    version: version,
    updatedAt: DateTime.parse(updatedAt),
  );
}
