import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';

part 'match_dto.freezed.dart';
part 'match_dto.g.dart';

/// Cricket-facing match aggregate.
///
/// The shared `matches` table is sport-neutral. Cricket-only values in this
/// DTO (`format`, toss, start phase, result, captain snapshots) are supplied by
/// the `cricket_match_details` security-invoker view, which joins
/// `matches` + `cricket_matches` and derives captains from
/// `cricket_match_players`.
///
/// Do not point this DTO back at `matches`.
@freezed
abstract class MatchDto with _$MatchDto {
  const factory MatchDto({
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'team_a_id') required String teamAId,
    @JsonKey(name: 'team_b_id') required String teamBId,
    @JsonKey(name: 'team_a_captain') String? teamACaptain,
    @JsonKey(name: 'team_b_captain') String? teamBCaptain,
    @JsonKey(name: 'setup_team_id') String? setupTeamId,
    required Map<String, dynamic> format,
    String? venue,
    @JsonKey(name: 'scheduled_start_time') String? scheduledStartTime,
    @JsonKey(name: 'actual_start_time') String? actualStartTime,
    Map<String, dynamic>? result,
    @Default('scheduled') String status,
    @JsonKey(name: 'match_type') @Default('friendly') String matchType,
    @JsonKey(name: 'toss_won_by') String? tossWonBy,
    @JsonKey(name: 'toss_decision') String? tossDecision,
    @JsonKey(name: 'toss_face') String? tossFace,
    @JsonKey(name: 'toss_recorded_by') String? tossRecordedBy,
    @JsonKey(name: 'start_phase') @Default('toss') String startPhase,
    @JsonKey(name: 'openers_submitted_by') String? openersSubmittedBy,
    @JsonKey(name: 'openers_submitted_at') String? openersSubmittedAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _MatchDto;

  const MatchDto._();

  factory MatchDto.fromJson(Map<String, dynamic> json) {
    final modified = Map<String, dynamic>.from(json);
    modified['match_id'] =
        (modified['match_id'] ?? modified['id'] ?? '').toString();
    modified['team_a_id'] = (modified['team_a_id'] ?? '').toString();
    modified['team_b_id'] = (modified['team_b_id'] ?? '').toString();
    modified['format'] =
        (modified['format'] as Map<String, dynamic>?) ??
        (modified['rules_config'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    modified['created_at'] =
        (modified['created_at'] ?? DateTime.now().toIso8601String()).toString();
    return _$MatchDtoFromJson(modified);
  }

  Map<String, dynamic> toJson() => _$MatchDtoToJson(this as _MatchDto);

  Match toEntity() => Match(
    id: MatchId(matchId),
    teamAId: TeamId(teamAId),
    teamBId: TeamId(teamBId),
    teamACaptain: teamACaptain,
    teamBCaptain: teamBCaptain,
    setupTeamId: setupTeamId == null ? null : TeamId(setupTeamId!),
    format: MatchFormat(
      oversPerInnings: (format['overs_per_innings'] as num?)?.toInt() ?? 0,
      playersPerTeam: (format['players_per_team'] as num?)?.toInt() ?? 11,
      ballType: MatchBallType.fromWire(format['ball_type'] as String?),
      maxOversPerBowler: (format['max_overs_per_bowler'] as num?)?.toInt() ?? 0,
      ballsPerOver: (format['balls_per_over'] as num?)?.toInt() ?? 6,
      inningsPerSide: (format['innings_per_side'] as num?)?.toInt() ?? 1,
      wicketsToAllOut: (format['wickets_to_all_out'] as num?)?.toInt(),
      endChangeBalls: (format['end_change_balls'] as num?)?.toInt(),
    ),
    // Deployed schema: matches.venue is a single text column. Split a
    // "<ground> · <city>" form if present so existing UI binds keep
    // working; otherwise the whole string lands in ground.
    venue:
        (venue == null || venue!.trim().isEmpty)
            ? null
            : () {
              final parts = venue!.split(' · ');
              return Venue(
                ground: parts.first.trim(),
                city:
                    parts.length > 1
                        ? parts.sublist(1).join(' · ').trim()
                        : null,
              );
            }(),
    scheduledStartTime:
        scheduledStartTime == null
            ? null
            : DateTime.tryParse(scheduledStartTime!),
    actualStartTime:
        actualStartTime == null ? null : DateTime.tryParse(actualStartTime!),
    resultDescription: result?['description'] as String?,
    status: MatchStatus.fromWire(status),
    matchType: MatchType.fromWire(matchType),
    tossWonBy: tossWonBy == null ? null : TeamId(tossWonBy!),
    tossDecision:
        tossDecision == null ? null : TossDecision.fromWire(tossDecision),
    tossFace: tossFace,
    tossRecordedBy: tossRecordedBy,
    startPhase: MatchStartPhase.fromWire(startPhase),
    openersSubmittedBy: openersSubmittedBy,
    openersSubmittedAt:
        openersSubmittedAt == null
            ? null
            : DateTime.tryParse(openersSubmittedAt!),
    // createdBy is nullable on the wire (matches.created_by is now
    // SET NULL on profile deletion) — anonymised matches still
    // render. Empty string preserves the entity's String contract.
    createdBy: createdBy ?? '',
    createdAt: DateTime.parse(createdAt),
  );
}
