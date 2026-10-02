import 'package:equatable/equatable.dart';

/// Status of a participant within a specific stage.
enum TournamentStageEntryStatus {
  active('active', 'Active'),
  withdrawn('withdrawn', 'Withdrawn'),
  eliminated('eliminated', 'Eliminated'),
  disqualified('disqualified', 'Disqualified'),
  promoted('promoted', 'Promoted');

  const TournamentStageEntryStatus(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentStageEntryStatus fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentStageEntryStatus.active;
}

/// Participation record linking a TournamentEntry to a specific Stage and Group.
class TournamentStageEntry extends Equatable {
  const TournamentStageEntry({
    required this.stageEntryId,
    required this.stageId,
    required this.entryId,
    required this.tournamentId,
    this.groupId,
    this.seed,
    required this.status,
    this.sourceStageId,
    this.qualificationSource,
    required this.enteredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String stageEntryId;
  final String stageId;
  final String entryId;
  final String tournamentId;
  final String? groupId;
  final int? seed;
  final TournamentStageEntryStatus status;
  final String? sourceStageId;
  final String? qualificationSource;
  final DateTime enteredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        stageEntryId,
        stageId,
        entryId,
        tournamentId,
        groupId,
        seed,
        status,
        sourceStageId,
        qualificationSource,
        enteredAt,
        createdAt,
        updatedAt,
      ];
}
