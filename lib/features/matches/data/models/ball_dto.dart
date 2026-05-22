import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';

part 'ball_dto.freezed.dart';
part 'ball_dto.g.dart';

/// Wire-format `balls` row.
@freezed
abstract class BallDto with _$BallDto {
  const factory BallDto({
    @JsonKey(name: 'ball_id') required String ballId,
    @JsonKey(name: 'innings_id') required String inningsId,
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'over_number') required int overNumber,
    @JsonKey(name: 'ball_number') required int ballNumber,
    @JsonKey(name: 'legal_ball_number') required int legalBallNumber,
    @JsonKey(name: 'bowler_id') required String bowlerId,
    @JsonKey(name: 'striker_id') required String strikerId,
    @JsonKey(name: 'non_striker_id') required String nonStrikerId,
    @JsonKey(name: 'runs_scored') @Default(0) int runsScored,
    @JsonKey(name: 'extra_runs') @Default(0) int extraRuns,
    @JsonKey(name: 'extra_type') String? extraType,
    @JsonKey(name: 'total_runs') @Default(0) int totalRuns,
    @JsonKey(name: 'is_four') @Default(false) bool isFour,
    @JsonKey(name: 'is_six') @Default(false) bool isSix,
    @JsonKey(name: 'is_wicket') @Default(false) bool isWicket,
    @JsonKey(name: 'wicket_type') String? wicketType,
    @JsonKey(name: 'dismissed_player_id') String? dismissedPlayerId,
  }) = _BallDto;

  const BallDto._();

  factory BallDto.fromJson(Map<String, dynamic> json) =>
      _$BallDtoFromJson(json);

  Ball toEntity() => Ball(
        id: BallId(ballId),
        inningsId: InningsId(inningsId),
        matchId: MatchId(matchId),
        overNumber: overNumber,
        ballNumber: ballNumber,
        legalBallNumber: legalBallNumber,
        bowlerId: bowlerId,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        runsScored: runsScored,
        extraRuns: extraRuns,
        totalRuns: totalRuns,
        extraType: ExtraType.fromWire(extraType),
        isFour: isFour,
        isSix: isSix,
        isWicket: isWicket,
        wicketType: WicketType.fromWire(wicketType),
        dismissedPlayerId: dismissedPlayerId,
      );
}
