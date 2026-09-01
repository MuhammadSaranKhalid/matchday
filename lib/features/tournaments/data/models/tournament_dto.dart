import '../../domain/entities/tournament.dart';

/// Wire-format DTO for `public.tournaments` rows.
class TournamentDto {
  const TournamentDto({
    required this.tournamentId,
    required this.tournamentName,
    required this.tournamentType,
    required this.status,
    required this.privacy,
    required this.organizers,
    required this.venues,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.bannerImageUrl,
    this.logoUrl,
    this.description,
    this.format = const {},
    this.rules = const {},
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.location = const {},
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
  final String? createdBy;
  final List<String> organizers;
  final List<dynamic> venues;
  final String? bannerImageUrl;
  final String? logoUrl;
  final String? description;
  final Map<String, dynamic> format;
  final Map<String, dynamic> rules;
  final String? startDate;
  final String? endDate;
  final String? registrationDeadline;
  final Map<String, dynamic> location;
  final String? prizeDetails;
  final num? entryFee;
  final int? minTeams;
  final int? maxTeams;
  final Map<String, dynamic> awards;
  final int approvedTeamsCount;
  final String createdAt;
  final String updatedAt;

  factory TournamentDto.fromJson(Map<String, dynamic> json) {
    return TournamentDto(
      tournamentId: json['tournament_id'] as String,
      tournamentName: json['tournament_name'] as String? ?? 'Untitled Tournament',
      tournamentType: json['tournament_type'] as String? ?? 'knockout',
      status: json['status'] as String? ?? 'draft',
      privacy: json['privacy'] as String? ?? 'public',
      createdBy: json['created_by'] as String?,
      organizers: (json['organizers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      venues: json['venues'] as List<dynamic>? ?? const [],
      bannerImageUrl: json['banner_image_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      format: (json['format'] as Map<String, dynamic>?) ?? const {},
      rules: (json['rules'] as Map<String, dynamic>?) ?? const {},
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      registrationDeadline: json['registration_deadline'] as String?,
      location: (json['location'] as Map<String, dynamic>?) ?? const {},
      prizeDetails: json['prize_details'] as String?,
      entryFee: json['entry_fee'] as num?,
      minTeams: json['min_teams'] as int?,
      maxTeams: json['max_teams'] as int?,
      awards: (json['awards'] as Map<String, dynamic>?) ?? const {},
      approvedTeamsCount: (json['approved_teams_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Tournament toEntity() {
    DateTime? parseDate(String? d) => d == null ? null : DateTime.tryParse(d);

    final venueObjects = venues.map((v) {
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
      createdBy: createdBy,
      organizers: organizers,
      venues: venueObjects,
      bannerImageUrl: bannerImageUrl,
      logoUrl: logoUrl,
      description: description,
      format: format,
      rules: rules,
      startDate: parseDate(startDate),
      endDate: parseDate(endDate),
      registrationDeadline: parseDate(registrationDeadline),
      city: location['city'] as String?,
      latitude: (location['lat'] as num?)?.toDouble(),
      longitude: (location['lng'] as num?)?.toDouble(),
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
