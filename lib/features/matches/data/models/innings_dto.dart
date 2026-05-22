import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';

part 'innings_dto.freezed.dart';
part 'innings_dto.g.dart';

/// Wire-format `innings` row.
@freezed
abstract class InningsDto with _$InningsDto {
  const factory InningsDto({
    @JsonKey(name: 'innings_id') required String inningsId,
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'innings_number') required int inningsNumber,
    @JsonKey(name: 'batting_team_id') required String battingTeamId,
    @JsonKey(name: 'bowling_team_id') required String bowlingTeamId,
    @JsonKey(name: 'total_runs') @Default(0) int totalRuns,
    @JsonKey(name: 'total_wickets') @Default(0) int totalWickets,
    @JsonKey(name: 'total_overs') @Default(0) num totalOvers,
    @JsonKey(name: 'total_balls_faced') @Default(0) int totalBallsFaced,
    int? target,
    @Default('in_progress') String status,
    @JsonKey(name: 'current_striker_id') String? currentStrikerId,
    @JsonKey(name: 'current_non_striker_id') String? currentNonStrikerId,
    @JsonKey(name: 'current_bowler_id') String? currentBowlerId,
  }) = _InningsDto;

  const InningsDto._();

  factory InningsDto.fromJson(Map<String, dynamic> json) =>
      _$InningsDtoFromJson(json);

  Innings toEntity() => Innings(
        id: InningsId(inningsId),
        matchId: MatchId(matchId),
        inningsNumber: inningsNumber,
        battingTeamId: TeamId(battingTeamId),
        bowlingTeamId: TeamId(bowlingTeamId),
        status: InningsStatus.fromWire(status),
        totalRuns: totalRuns,
        totalWickets: totalWickets,
        totalOvers: totalOvers.toDouble(),
        totalBallsFaced: totalBallsFaced,
        target: target,
        currentStrikerId: currentStrikerId,
        currentNonStrikerId: currentNonStrikerId,
        currentBowlerId: currentBowlerId,
      );
}
