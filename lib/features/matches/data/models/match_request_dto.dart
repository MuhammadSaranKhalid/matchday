import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_request.dart';

part 'match_request_dto.freezed.dart';
part 'match_request_dto.g.dart';

/// Wire-format `match_requests` row. The proposed / countered `format`
/// columns are jsonb blobs with the same shape as `matches.format`.
@freezed
abstract class MatchRequestDto with _$MatchRequestDto {
  const factory MatchRequestDto({
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'from_team_id') required String fromTeamId,
    @JsonKey(name: 'to_team_id') String? toTeamId,
    @JsonKey(name: 'requested_by') required String requestedBy,
    @JsonKey(name: 'proposed_start_time') String? proposedStartTime,
    @JsonKey(name: 'proposed_venue') String? proposedVenue,
    @JsonKey(name: 'proposed_format') Map<String, dynamic>? proposedFormat,
    String? message,
    @JsonKey(name: 'players_per_side') @Default(11) int playersPerSide,
    @JsonKey(name: 'from_team_xi') @Default(<String>[]) List<String> fromTeamXi,
    @JsonKey(name: 'from_team_keeper_id') String? fromTeamKeeperId,
    @JsonKey(name: 'countered_start_time') String? counteredStartTime,
    @JsonKey(name: 'countered_venue') String? counteredVenue,
    @JsonKey(name: 'countered_format') Map<String, dynamic>? counteredFormat,
    @JsonKey(name: 'countered_players_per_side') int? counteredPlayersPerSide,
    @Default('pending') String status,
    @JsonKey(name: 'decided_by') String? decidedBy,
    @JsonKey(name: 'decided_at') String? decidedAt,
    @JsonKey(name: 'decision_note') String? decisionNote,
    @JsonKey(name: 'decision_reason') String? decisionReason,
    @JsonKey(name: 'match_id') String? matchId,
    @JsonKey(name: 'share_code') String? shareCode,
    @JsonKey(name: 'code_expires_at') String? codeExpiresAt,
    @JsonKey(name: 'proposal_expires_at') String? proposalExpiresAt,
    @JsonKey(name: 'counter_expires_at') String? counterExpiresAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _MatchRequestDto;

  const MatchRequestDto._();

  factory MatchRequestDto.fromJson(Map<String, dynamic> json) =>
      _$MatchRequestDtoFromJson(json);

  MatchRequest toEntity() {
    MatchFormat? format(Map<String, dynamic>? m) {
      if (m == null) return null;
      return MatchFormat(
        oversPerInnings: (m['overs_per_innings'] as num?)?.toInt() ?? 20,
        playersPerTeam: (m['players_per_team'] as num?)?.toInt() ?? 11,
        ballType: MatchBallType.fromWire(m['ball_type'] as String?),
        maxOversPerBowler:
            (m['max_overs_per_bowler'] as num?)?.toInt() ?? 4,
        ballsPerOver: (m['balls_per_over'] as num?)?.toInt() ?? 6,
        inningsPerSide: (m['innings_per_side'] as num?)?.toInt() ?? 1,
        wicketsToAllOut: (m['wickets_to_all_out'] as num?)?.toInt(),
      );
    }

    DateTime? parse(String? s) =>
        s == null ? null : DateTime.tryParse(s);

    return MatchRequest(
      id: MatchRequestId(requestId),
      fromTeamId: TeamId(fromTeamId),
      toTeamId: toTeamId == null ? null : TeamId(toTeamId!),
      requestedBy: requestedBy,
      proposedStartTime: parse(proposedStartTime),
      proposedVenue: proposedVenue,
      proposedFormat: format(proposedFormat),
      message: message,
      playersPerSide: playersPerSide,
      fromTeamXi: fromTeamXi,
      fromTeamKeeperId: fromTeamKeeperId,
      counteredStartTime: parse(counteredStartTime),
      counteredVenue: counteredVenue,
      counteredFormat: format(counteredFormat),
      counteredPlayersPerSide: counteredPlayersPerSide,
      status: MatchRequestStatus.fromWire(status),
      decidedBy: decidedBy,
      decidedAt: parse(decidedAt),
      decisionNote: decisionNote,
      decisionReason: decisionReason == null
          ? null
          : DeclineReason.fromWire(decisionReason),
      matchId: matchId == null ? null : MatchId(matchId!),
      shareCode: shareCode,
      codeExpiresAt: parse(codeExpiresAt),
      proposalExpiresAt: parse(proposalExpiresAt),
      counterExpiresAt: parse(counterExpiresAt),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  /// Inverse: serialise a [MatchFormat] into the jsonb shape the RPCs expect.
  static Map<String, dynamic> formatToJson(MatchFormat f) => {
        'overs_per_innings': f.oversPerInnings,
        'players_per_team': f.playersPerTeam,
        'ball_type': f.ballType.wire,
        'max_overs_per_bowler': f.maxOversPerBowler,
        'balls_per_over': f.ballsPerOver,
        'innings_per_side': f.inningsPerSide,
        if (f.wicketsToAllOut != null) 'wickets_to_all_out': f.wicketsToAllOut,
      };
}
