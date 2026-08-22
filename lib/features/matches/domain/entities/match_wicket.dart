import 'package:equatable/equatable.dart';

/// Represents a dismissal event in a match.
///
/// Backed by the `match_wickets` table. Decoupled from deliveries to carry rich
/// metadata about fielders, bowler credit, and fall of wicket tracking.
class MatchWicket extends Equatable {
  const MatchWicket({
    required this.wicketId,
    required this.deliveryId,
    required this.inningsId,
    required this.playerOutId,
    required this.dismissalKind,
    this.isBowlerCredited = true,
    this.creditedBowlerId,
    this.primaryFielderId,
    this.assistedFielderId,
    required this.fallOfWicketScore,
    required this.fallOfWicketNumber,
    required this.fallOfWicketOvers,
    required this.createdAt,
  });

  final String wicketId;
  final String deliveryId;
  final String inningsId;
  final String playerOutId;
  final String dismissalKind;
  final bool isBowlerCredited;
  final String? creditedBowlerId;
  final String? primaryFielderId;
  final String? assistedFielderId;
  final int fallOfWicketScore;
  final int fallOfWicketNumber;
  final double fallOfWicketOvers;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        wicketId,
        deliveryId,
        inningsId,
        playerOutId,
        dismissalKind,
        isBowlerCredited,
        creditedBowlerId,
        primaryFielderId,
        assistedFielderId,
        fallOfWicketScore,
        fallOfWicketNumber,
        fallOfWicketOvers,
        createdAt,
      ];
}
