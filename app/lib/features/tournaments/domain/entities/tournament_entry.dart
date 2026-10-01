import 'package:equatable/equatable.dart';

/// Canonical entry status in a tournament.
enum TournamentEntryStatus {
  active('active', 'Active'),
  withdrawn('withdrawn', 'Withdrawn'),
  disqualified('disqualified', 'Disqualified');

  const TournamentEntryStatus(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentEntryStatus fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentEntryStatus.active;
}

/// Canonical squad state for a tournament entry.
enum TournamentSquadState {
  editable('editable', 'Editable'),
  frozen('frozen', 'Frozen');

  const TournamentSquadState(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentSquadState fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentSquadState.editable;
}

/// Accepted competitive participant in a tournament.
class TournamentEntry extends Equatable {
  const TournamentEntry({
    required this.entryId,
    required this.tournamentId,
    required this.teamId,
    required this.status,
    required this.entrySource,
    required this.squadState,
    required this.createdAt,
    required this.updatedAt,
    this.registrationId,
    this.acceptedBy,
    this.acceptedAt,
    this.withdrawnAt,
    this.withdrawalReason,
    this.disqualifiedAt,
    this.disqualificationReason,
    this.squadFrozenAt,
    this.teamName,
    this.teamLogoUrl,
  });

  final String entryId;
  final String tournamentId;
  final String teamId;
  final TournamentEntryStatus status;
  final String entrySource;
  final TournamentSquadState squadState;
  final String? registrationId;
  final String? acceptedBy;
  final DateTime? acceptedAt;
  final DateTime? withdrawnAt;
  final String? withdrawalReason;
  final DateTime? disqualifiedAt;
  final String? disqualificationReason;
  final DateTime? squadFrozenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Enriched presentation fields
  final String? teamName;
  final String? teamLogoUrl;

  bool get isActive => status == TournamentEntryStatus.active;
  bool get isWithdrawn => status == TournamentEntryStatus.withdrawn;
  bool get isDisqualified => status == TournamentEntryStatus.disqualified;
  bool get isSquadFrozen => squadState == TournamentSquadState.frozen;

  @override
  List<Object?> get props => [
        entryId,
        tournamentId,
        teamId,
        status,
        entrySource,
        squadState,
        registrationId,
        acceptedBy,
        acceptedAt,
        withdrawnAt,
        withdrawalReason,
        disqualifiedAt,
        disqualificationReason,
        squadFrozenAt,
        createdAt,
        updatedAt,
      ];
}
