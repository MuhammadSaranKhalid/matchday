import 'package:equatable/equatable.dart';

/// Status of a tournament draw revision.
enum TournamentDrawRevisionStatus {
  draft('draft', 'Draft'),
  published('published', 'Published'),
  superseded('superseded', 'Superseded');

  const TournamentDrawRevisionStatus(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentDrawRevisionStatus fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentDrawRevisionStatus.draft;
}

/// Immutable record of a stage's draw plan revision.
class TournamentDrawRevision extends Equatable {
  const TournamentDrawRevision({
    required this.drawRevisionId,
    required this.stageId,
    required this.tournamentId,
    required this.revisionNumber,
    required this.status,
    required this.basedOnEntryRevision,
    this.planSnapshot = const {},
    this.revisionReason,
    this.createdBy,
    required this.createdAt,
    this.publishedBy,
    this.publishedAt,
  });

  final String drawRevisionId;
  final String stageId;
  final String tournamentId;
  final int revisionNumber;
  final TournamentDrawRevisionStatus status;
  final int basedOnEntryRevision;
  final Map<String, dynamic> planSnapshot;
  final String? revisionReason;
  final String? createdBy;
  final DateTime createdAt;
  final String? publishedBy;
  final DateTime? publishedAt;

  @override
  List<Object?> get props => [
        drawRevisionId,
        stageId,
        tournamentId,
        revisionNumber,
        status,
        basedOnEntryRevision,
        planSnapshot,
        revisionReason,
        createdBy,
        createdAt,
        publishedBy,
        publishedAt,
      ];
}
