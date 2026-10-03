import '../../domain/entities/tournament.dart';

/// Wire-format DTO for `public.tournaments` rows.
class TournamentDto {
  const TournamentDto({
    required this.tournamentId,
    required this.tournamentName,
    required this.tournamentType,
    required this.status,
    required this.privacy,
    required this.venues,
    required this.createdAt,
    required this.updatedAt,
    this.ownerUserId,
    this.createdBy,
    this.revision = 1,
    this.entryRevision = 1,
    this.publicationState = 'draft',
    this.registrationState = 'not_open',
    this.entryState = 'editable',
    this.competitionState = 'not_started',
    this.terminationState = 'none',
    this.bannerImageUrl,
    this.logoUrl,
    this.description,
    this.format = const {},
    this.rules = const {},
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.prizeDetails,
    this.entryFee,
    this.minTeams,
    this.maxTeams,
    this.awards = const {},
    this.approvedTeamsCount = 0,
  });

  final String tournamentId;
  final String tournamentName;
  final String tournamentType;
  final String status;
  final String privacy;
  final String? ownerUserId;
  final String? createdBy;
  final int revision;
  final int entryRevision;
  final String publicationState;
  final String registrationState;
  final String entryState;
  final String competitionState;
  final String terminationState;
  final List<dynamic> venues;
  final String? bannerImageUrl;
  final String? logoUrl;
  final String? description;
  final Map<String, dynamic> format;
  final Map<String, dynamic> rules;
  final String? startDate;
  final String? endDate;
  final String? registrationDeadline;
  final String? prizeDetails;
  final num? entryFee;
  final int? minTeams;
  final int? maxTeams;
  final Map<String, dynamic> awards;
  final int approvedTeamsCount;
  final String createdAt;
  final String updatedAt;

  factory TournamentDto.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String?;
    final pub = json['publication_state'] as String? ?? 'draft';
    final reg = json['registration_state'] as String? ?? 'not_open';
    final comp = json['competition_state'] as String? ?? 'not_started';
    final term = json['termination_state'] as String? ?? 'none';
    final derivedStatus = rawStatus ?? _deriveStatus(pub, reg, comp, term);

    return TournamentDto(
      tournamentId: json['tournament_id'] as String,
      tournamentName:
          json['tournament_name'] as String? ?? 'Untitled Tournament',
      tournamentType: json['tournament_type'] as String? ?? 'knockout',
      status: derivedStatus,
      privacy: json['privacy'] as String? ?? 'public',
      ownerUserId:
          json['owner_user_id'] as String? ?? json['created_by'] as String?,
      createdBy: json['created_by'] as String?,
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      // entry_revision is canonical concurrency state.
      // Do not derive it from updated_at or from the general Tournament revision.
      entryRevision: (json['entry_revision'] as num).toInt(),
      publicationState: pub,
      registrationState: reg,
      entryState: json['entry_state'] as String? ?? 'editable',
      competitionState: comp,
      terminationState: term,
      venues: json['venues'] as List<dynamic>? ?? const [],
      bannerImageUrl: json['banner_image_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      format: (json['format'] as Map<String, dynamic>?) ?? const {},
      rules: (json['rules'] as Map<String, dynamic>?) ?? const {},
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      registrationDeadline: json['registration_deadline'] as String?,
      prizeDetails: json['prize_details'] as String?,
      entryFee: json['entry_fee'] as num?,
      minTeams: json['min_teams'] as int?,
      maxTeams: json['max_teams'] as int?,
      awards: (json['awards'] as Map<String, dynamic>?) ?? const {},
      approvedTeamsCount: (json['approved_teams_count'] as num?)?.toInt() ?? 0,
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  static String _deriveStatus(
    String pub,
    String reg,
    String comp,
    String term,
  ) {
    if (term == 'abandoned' || term == 'cancelled') return 'cancelled';
    if (comp == 'in_progress' || comp == 'paused') return 'live';
    if (comp == 'completed' || pub == 'archived') return 'completed';
    if (reg == 'open' || pub == 'published') return 'upcoming';
    return 'draft';
  }

  Tournament toEntity() {
    DateTime? parseDate(String? d) => d == null ? null : DateTime.tryParse(d);

    final venueObjects =
        venues.map((v) {
          if (v is Map<String, dynamic>) {
            return TournamentVenue.fromJson(v);
          }
          return TournamentVenue(name: v.toString());
        }).toList();

    return Tournament(
      id: tournamentId,
      name: tournamentName,
      type: TournamentType.fromWire(tournamentType),
      status: TournamentStatus.fromWire(status),
      privacy: TournamentPrivacy.fromWire(privacy),
      ownerUserId: ownerUserId,
      createdBy: createdBy,
      revision: revision,
      entryRevision: entryRevision,
      publicationState: TournamentPublicationState.fromWire(publicationState),
      registrationState: TournamentRegistrationState.fromWire(
        registrationState,
      ),
      entryState: TournamentEntryState.fromWire(entryState),
      competitionState: TournamentCompetitionState.fromWire(competitionState),
      terminationState: TournamentTerminationState.fromWire(terminationState),
      venues: venueObjects,
      bannerImageUrl: bannerImageUrl,
      logoUrl: logoUrl,
      description: description,
      format: format,
      rules: rules,
      startDate: parseDate(startDate),
      endDate: parseDate(endDate),
      registrationDeadline: parseDate(registrationDeadline),
      city: venueObjects.firstOrNull?.city,
      latitude: null,
      longitude: null,
      prizeDetails: prizeDetails,
      entryFee: entryFee?.toDouble(),
      minTeams: minTeams,
      maxTeams: maxTeams,
      awards: awards,
      approvedTeamsCount: approvedTeamsCount,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
