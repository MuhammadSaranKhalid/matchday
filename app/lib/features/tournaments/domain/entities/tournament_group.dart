import 'package:equatable/equatable.dart';

/// Group container within a tournament stage (e.g. Group A, Pool 1).
class TournamentGroup extends Equatable {
  const TournamentGroup({
    required this.groupId,
    required this.stageId,
    required this.tournamentId,
    required this.sequence,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String groupId;
  final String stageId;
  final String tournamentId;
  final int sequence;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        groupId,
        stageId,
        tournamentId,
        sequence,
        name,
        createdAt,
        updatedAt,
      ];
}
