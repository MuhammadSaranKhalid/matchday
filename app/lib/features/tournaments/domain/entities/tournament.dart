import 'package:meta/meta.dart';

/// Supported tournament types.
enum TournamentType {
  knockout('knockout', 'Knockout', 'Single elimination bracket tree'),
  roundRobin('round_robin', 'Round Robin', 'Every team plays every other team once'),
  league('league', 'League', 'Points table with qualification playoffs'),
  groupKnockout('group_knockout', 'Group + Knockout', 'Group stages feeding knockout tree'),
  doubleElimination('double_elimination', 'Double Elimination', 'Winners & Losers bracket');

  const TournamentType(this.wire, this.label, this.description);
  final String wire;
  final String label;
  final String description;

  static TournamentType fromWire(String? wire) =>
      values.where((t) => t.wire == wire).firstOrNull ?? TournamentType.knockout;
}

/// Tournament lifecycle status.
enum TournamentStatus {
  draft('draft', 'Draft'),
  registration('registration', 'Registration Open'),
  upcoming('upcoming', 'Upcoming'),
  live('live', 'Live'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  abandoned('abandoned', 'Abandoned');

  const TournamentStatus(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentStatus fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ?? TournamentStatus.draft;
}

/// Tournament privacy setting.
enum TournamentPrivacy {
  public('public', 'Public'),
  private('private', 'Private (Invite only)');

  const TournamentPrivacy(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentPrivacy fromWire(String? wire) =>
      values.where((p) => p.wire == wire).firstOrNull ?? TournamentPrivacy.public;
}

/// A cricket venue used in a tournament.
@immutable
class TournamentVenue {
  const TournamentVenue({
    required this.name,
    this.city,
  });

  final String name;
  final String? city;

  factory TournamentVenue.fromJson(Map<String, dynamic> json) => TournamentVenue(
        name: json['name'] as String? ?? 'Main Ground',
        city: json['city'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (city != null) 'city': city,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentVenue && other.name == name && other.city == city;

  @override
  int get hashCode => Object.hash(name, city);
}

/// Master Tournament domain entity. Pure Dart, zero Flutter dependencies.
@immutable
class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.type,
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
    this.city,
    this.latitude,
    this.longitude,
    this.prizeDetails,
    this.entryFee,
    this.minTeams,
    this.maxTeams,
    this.awards = const {},
    this.approvedTeamsCount = 0,
  });

  final String id;
  final String name;
  final TournamentType type;
  final TournamentStatus status;
  final TournamentPrivacy privacy;
  final String? createdBy;
  final List<String> organizers;
  final List<TournamentVenue> venues;
  final String? bannerImageUrl;
  final String? logoUrl;
  final String? description;
  final Map<String, dynamic> format;
  final Map<String, dynamic> rules;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? prizeDetails;
  final double? entryFee;
  final int? minTeams;
  final int? maxTeams;
  final Map<String, dynamic> awards;
  final int approvedTeamsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isOrganizedBy(String userId) =>
      createdBy == userId || organizers.contains(userId);

  int get maxOvers => (format['max_overs'] as num?)?.toInt() ?? 20;
  String get ballType => (format['ball_type'] as String?) ?? 'Leather (Red)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tournament &&
          other.id == id &&
          other.name == name &&
          other.type == type &&
          other.status == status &&
          other.privacy == privacy &&
          other.createdBy == createdBy &&
          other.bannerImageUrl == bannerImageUrl &&
          other.logoUrl == logoUrl &&
          other.description == description &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.registrationDeadline == registrationDeadline &&
          other.city == city &&
          other.entryFee == entryFee &&
          other.minTeams == minTeams &&
          other.maxTeams == maxTeams &&
          other.approvedTeamsCount == approvedTeamsCount;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        status,
        privacy,
        createdBy,
        bannerImageUrl,
        logoUrl,
        startDate,
        endDate,
        city,
        entryFee,
        approvedTeamsCount,
      );
}
