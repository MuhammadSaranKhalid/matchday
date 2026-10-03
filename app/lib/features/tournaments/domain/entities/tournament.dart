import 'package:meta/meta.dart';

/// Supported tournament types.
enum TournamentType {
  knockout('knockout', 'Knockout', 'Single elimination bracket tree'),
  roundRobin(
    'round_robin',
    'Round Robin',
    'Every team plays every other team once',
  ),
  league('league', 'League', 'Points table with qualification playoffs'),
  groupKnockout(
    'group_knockout',
    'Group + Knockout',
    'Group stages feeding knockout tree',
  ),
  doubleElimination(
    'double_elimination',
    'Double Elimination',
    'Winners & Losers bracket',
  );

  const TournamentType(this.wire, this.label, this.description);
  final String wire;
  final String label;
  final String description;

  static TournamentType fromWire(String? wire) =>
      values.where((t) => t.wire == wire).firstOrNull ??
      TournamentType.knockout;
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

/// Canonical publication state.
enum TournamentPublicationState {
  draft('draft', 'Draft'),
  published('published', 'Published');

  const TournamentPublicationState(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentPublicationState fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentPublicationState.draft;
}

/// Canonical registration state.
enum TournamentRegistrationState {
  notOpen('not_open', 'Not Open'),
  open('open', 'Open'),
  closed('closed', 'Closed');

  const TournamentRegistrationState(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentRegistrationState fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentRegistrationState.notOpen;
}

/// Canonical entry set lock state.
enum TournamentEntryState {
  editable('editable', 'Editable'),
  locked('locked', 'Locked');

  const TournamentEntryState(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentEntryState fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentEntryState.editable;
}

/// Canonical competition execution state.
enum TournamentCompetitionState {
  notStarted('not_started', 'Not Started'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed');

  const TournamentCompetitionState(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentCompetitionState fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentCompetitionState.notStarted;
}

/// Canonical termination state.
enum TournamentTerminationState {
  none('none', 'None'),
  cancelled('cancelled', 'Cancelled'),
  abandoned('abandoned', 'Abandoned');

  const TournamentTerminationState(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentTerminationState fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ??
      TournamentTerminationState.none;
}

/// Tournament privacy setting.
enum TournamentPrivacy {
  public('public', 'Public'),
  private('private', 'Private (Invite only)');

  const TournamentPrivacy(this.wire, this.label);
  final String wire;
  final String label;

  static TournamentPrivacy fromWire(String? wire) =>
      values.where((p) => p.wire == wire).firstOrNull ??
      TournamentPrivacy.public;
}

/// A cricket venue used in a tournament.
@immutable
class TournamentVenue {
  const TournamentVenue({required this.name, this.city});

  final String name;
  final String? city;

  factory TournamentVenue.fromJson(Map<String, dynamic> json) =>
      TournamentVenue(
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
    required this.venues,
    required this.createdAt,
    required this.updatedAt,
    this.ownerUserId,
    this.createdBy,
    this.revision = 1,
    this.entryRevision = 1,
    this.publicationState = TournamentPublicationState.draft,
    this.registrationState = TournamentRegistrationState.notOpen,
    this.entryState = TournamentEntryState.editable,
    this.competitionState = TournamentCompetitionState.notStarted,
    this.terminationState = TournamentTerminationState.none,
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

  /// Canonical authority root for the tournament.
  final String? ownerUserId;

  /// Historical creator provenance (who originally inserted the record).
  final String? createdBy;

  /// General Tournament aggregate revision.
  ///
  /// This is distinct from [entryRevision].
  final int revision;

  /// Revision of the accepted competitive Entry Set.
  ///
  /// Incremented by PostgreSQL when the Tournament's active Entry Set changes.
  /// Used for optimistic concurrency on Entry-set commands such as withdrawal.
  final int entryRevision;

  final TournamentPublicationState publicationState;
  final TournamentRegistrationState registrationState;
  final TournamentEntryState entryState;
  final TournamentCompetitionState competitionState;
  final TournamentTerminationState terminationState;
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

  String get effectiveOwnerUserId => ownerUserId ?? createdBy ?? '';

  /// Deterministic projection from orthogonal lifecycle states onto legacy status.
  static TournamentStatus derivePublicStatus({
    required TournamentPublicationState publicationState,
    required TournamentRegistrationState registrationState,
    required TournamentEntryState entryState,
    required TournamentCompetitionState competitionState,
    required TournamentTerminationState terminationState,
  }) {
    if (terminationState == TournamentTerminationState.cancelled) {
      return TournamentStatus.cancelled;
    }
    if (terminationState == TournamentTerminationState.abandoned) {
      return TournamentStatus.abandoned;
    }
    if (publicationState == TournamentPublicationState.draft) {
      return TournamentStatus.draft;
    }
    if (competitionState == TournamentCompetitionState.completed) {
      return TournamentStatus.completed;
    }
    if (competitionState == TournamentCompetitionState.inProgress) {
      return TournamentStatus.live;
    }
    if (registrationState == TournamentRegistrationState.open) {
      return TournamentStatus.registration;
    }
    return TournamentStatus.upcoming;
  }

  TournamentStatus get projectedPublicStatus => derivePublicStatus(
    publicationState: publicationState,
    registrationState: registrationState,
    entryState: entryState,
    competitionState: competitionState,
    terminationState: terminationState,
  );

  /// Authority check: answers whether [userId] currently has root owner
  /// or delegated organizer authority over this tournament.
  /// Authority check: answers whether [userId] currently has root owner
  /// authority over this tournament. Delegated organizer authority is resolved
  /// via [tournament_memberships].
  ///
  /// Provenance ([createdBy]) answers who originated the row and does NOT
  /// grant present authority once [ownerUserId] is set.
  bool isOrganizedBy(String userId) =>
      ownerUserId != null ? ownerUserId == userId : createdBy == userId;

  /// Provenance helper: answers who originated this tournament row.
  /// Does NOT grant current authorization.
  bool wasCreatedBy(String userId) => createdBy == userId;

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
          other.revision == revision &&
          other.entryRevision == entryRevision &&
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
    revision,
    entryRevision,
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
