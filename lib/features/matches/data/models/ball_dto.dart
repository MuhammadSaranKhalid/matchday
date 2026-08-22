import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';

part 'ball_dto.freezed.dart';
part 'ball_dto.g.dart';

/// Wire-format `balls` row. Mirrors the deployed schema — there is no
/// innings table; deliveries are keyed by `(match_id, innings_number, seq)`.
@freezed
abstract class BallDto with _$BallDto {
  const factory BallDto({
    @JsonKey(name: 'ball_id') required String ballId,
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'innings_number') required int inningsNumber,
    required int seq,
    @JsonKey(name: 'over_number') required int overNumber,
    @JsonKey(name: 'ball_in_over') required int ballInOver,
    @JsonKey(name: 'is_legal_delivery') @Default(true) bool isLegalDelivery,
    @JsonKey(name: 'ball_type') @Default('legal') String ballType,
    @JsonKey(name: 'runs_scored') @Default(0) int runsScored,
    @Default(0) int extras,
    @JsonKey(name: 'is_wicket') @Default(false) bool isWicket,
    @JsonKey(name: 'wicket_type') String? wicketType,
    @JsonKey(name: 'is_free_hit') @Default(false) bool isFreeHit,
    @JsonKey(name: 'batsman_id') String? batsmanId,
    @JsonKey(name: 'non_striker_id') String? nonStrikerId,
    @JsonKey(name: 'bowler_id') String? bowlerId,
    @JsonKey(name: 'fielder_id') String? fielderId,
    String? commentary,
  }) = _BallDto;

  const BallDto._();

  factory BallDto.fromJson(Map<String, dynamic> json) {
    final modified = Map<String, dynamic>.from(json);
    modified['ball_id'] = (modified['delivery_id'] ?? modified['ball_id'] ?? modified['id'] ?? '').toString();
    modified['runs_scored'] = (modified['runs_off_bat'] ?? modified['runs_scored'] ?? 0);
    modified['extras'] = (modified['extra_runs'] ?? modified['extras'] ?? 0);
    modified['ball_type'] = (modified['delivery_type'] ?? modified['ball_type'] ?? 'legal').toString();
    modified['batsman_id'] = modified['striker_id'] ?? modified['batsman_id'];
    return _$BallDtoFromJson(modified);
  }

  Ball toEntity() => Ball(
        id: BallId(ballId),
        matchId: MatchId(matchId),
        inningsNumber: inningsNumber,
        seq: seq,
        overNumber: overNumber,
        ballInOver: ballInOver,
        isLegalDelivery: isLegalDelivery,
        ballKind: BallKind.fromWire(ballType),
        runsScored: runsScored,
        extras: extras,
        isWicket: isWicket,
        isFreeHit: isFreeHit,
        wicketType: WicketType.fromWire(wicketType),
        batsmanId: batsmanId,
        nonStrikerId: nonStrikerId,
        bowlerId: bowlerId,
        fielderId: fielderId,
        commentary: commentary,
      );
}
