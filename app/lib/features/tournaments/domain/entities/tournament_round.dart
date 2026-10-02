import 'package:equatable/equatable.dart';

/// Round grouping fixtures chronologically or logically within a stage/group.
class TournamentRound extends Equatable {
  const TournamentRound({
    required this.roundId,
    required this.stageId,
    required this.tournamentId,
    this.groupId,
    required this.roundNumber,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
  });

  final String roundId;
  final String stageId;
  final String tournamentId;
  final String? groupId;
  final int roundNumber;
  final String label;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        roundId,
        stageId,
        tournamentId,
        groupId,
        roundNumber,
        label,
        createdAt,
        updatedAt,
      ];
}
