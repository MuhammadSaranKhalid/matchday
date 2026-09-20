/// A team. Colours are stored as hex strings for the crest avatar.
///
/// Authority never comes from [createdBy]. It lives on active membership role
/// rows (`team_member_roles`). [createdBy] is immutable history only.
class Team {
  const Team({
    required this.id,
    required this.createdBy,
    required this.name,
    required this.type,
    required this.privacy,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.homeGround,
    this.foundedYear,
    this.primaryColor,
    this.secondaryColor,
    this.tagline,
    this.logoUrl,
    this.logoMonogram,
    this.crestKind = CrestKind.monogram,
    this.isVerified = false,
    this.status = TeamStatus.active,
    this.maxSquadSize = 25,
  });

  final TeamId id;

  /// Historical creator. Empty only for an anonymised older team whose
  /// creator account was deleted (`created_by` is ON DELETE SET NULL).
  final String createdBy;
  final String name;
  final TeamType type;
  final TeamPrivacy privacy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? homeGround;
  final int? foundedYear;
  final String? primaryColor;
  final String? secondaryColor;
  final String? tagline;
  final String? logoUrl;
  final String? logoMonogram;
  final CrestKind crestKind;
  final bool isVerified;
  final TeamStatus status;
  final int maxSquadSize;

  bool get isArchived => status == TeamStatus.archived;
  bool get isActive => status == TeamStatus.active;
  bool get isReadOnly => !isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          other.id == id &&
          other.createdBy == createdBy &&
          other.name == name &&
          other.type == type &&
          other.privacy == privacy &&
          other.description == description &&
          other.homeGround == homeGround &&
          other.foundedYear == foundedYear &&
          other.primaryColor == primaryColor &&
          other.secondaryColor == secondaryColor &&
          other.tagline == tagline &&
          other.logoUrl == logoUrl &&
          other.logoMonogram == logoMonogram &&
          other.crestKind == crestKind &&
          other.isVerified == isVerified &&
          other.status == status &&
          other.maxSquadSize == maxSquadSize &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        createdBy,
        name,
        type,
        privacy,
        description,
        homeGround,
        foundedYear,
        primaryColor,
        secondaryColor,
        tagline,
        logoUrl,
        logoMonogram,
        crestKind,
        isVerified,
        status,
        maxSquadSize,
        createdAt,
        updatedAt,
      );
}

class TeamId {
  const TeamId(this.value);
  final String value;
  @override
  bool operator ==(Object other) => other is TeamId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

enum TeamType {
  club('club'),
  village('village'),
  casual('casual'),
  corporate('corporate'),
  school('school'),
  university('university');

  const TeamType(this.wire);
  final String wire;

  static TeamType fromWire(String? wire) =>
      values.where((t) => t.wire == wire).firstOrNull ?? TeamType.club;
}

enum TeamStatus {
  active('active'),
  disbanded('disbanded'),
  archived('archived');

  const TeamStatus(this.wire);
  final String wire;

  static TeamStatus fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull ?? TeamStatus.active;
}

enum TeamPrivacy {
  public('public'),
  private('private');

  const TeamPrivacy(this.wire);
  final String wire;

  static TeamPrivacy fromWire(String? wire) =>
      values.where((p) => p.wire == wire).firstOrNull ?? TeamPrivacy.public;
}

enum CrestKind {
  monogram,
  initials,
  shield,
  upload;

  static CrestKind fromWire(String? value) =>
      values.where((kind) => kind.name == value).firstOrNull ?? monogram;
}
