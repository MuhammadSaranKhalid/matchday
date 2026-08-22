import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/match_wicket.dart';

part 'match_wicket_dto.freezed.dart';
part 'match_wicket_dto.g.dart';

@freezed
abstract class MatchWicketDto with _$MatchWicketDto {
  const factory MatchWicketDto({
    @JsonKey(name: 'wicket_id') required String wicketId,
    @JsonKey(name: 'delivery_id') required String deliveryId,
    @JsonKey(name: 'innings_id') required String inningsId,
    @JsonKey(name: 'player_out_id') required String playerOutId,
    @JsonKey(name: 'dismissal_kind') required String dismissalKind,
    @JsonKey(name: 'is_bowler_credited') @Default(true) bool isBowlerCredited,
    @JsonKey(name: 'credited_bowler_id') String? creditedBowlerId,
    @JsonKey(name: 'primary_fielder_id') String? primaryFielderId,
    @JsonKey(name: 'assisted_fielder_id') String? assistedFielderId,
    @JsonKey(name: 'fall_of_wicket_score') required int fallOfWicketScore,
    @JsonKey(name: 'fall_of_wicket_number') required int fallOfWicketNumber,
    @JsonKey(name: 'fall_of_wicket_overs') required double fallOfWicketOvers,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _MatchWicketDto;

  const MatchWicketDto._();

  factory MatchWicketDto.fromJson(Map<String, dynamic> json) =>
      _$MatchWicketDtoFromJson(json);

  MatchWicket toEntity() => MatchWicket(
        wicketId: wicketId,
        deliveryId: deliveryId,
        inningsId: inningsId,
        playerOutId: playerOutId,
        dismissalKind: dismissalKind,
        isBowlerCredited: isBowlerCredited,
        creditedBowlerId: creditedBowlerId,
        primaryFielderId: primaryFielderId,
        assistedFielderId: assistedFielderId,
        fallOfWicketScore: fallOfWicketScore,
        fallOfWicketNumber: fallOfWicketNumber,
        fallOfWicketOvers: fallOfWicketOvers,
        createdAt: DateTime.parse(createdAt),
      );
}
