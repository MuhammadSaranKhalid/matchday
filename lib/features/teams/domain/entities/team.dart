/// A team. Colours are stored as hex strings for the crest avatar.
///
/// There is no `managers` list any more (2026-09-10). Team authority lives on
/// the roster as `TeamMember.role` — see [MemberRole] and
/// docs/team-roles-design.md. [createdBy] is HISTORY — who made this team —
/// and is never an authorization answer. "Who runs it?" is the `owner` role on
/// the roster; ask the permission set, or [TeamRelationship].
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
    this.city,
    this.foundedYear,
    this.primaryColor,
    this.secondaryColor,
    this.tagline,
    this.logoUrl,
    this.logoMonogram,
    this.crestKind = CrestKind.monogram,
    this.isVerified = false,
    this.status = TeamStatus.active,
  });

  final TeamId id;
  final String createdBy;
  final String name;
  final TeamType type;
  final TeamPrivacy privacy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? homeGround;
  final String? city;
  final int? foundedYear;
  final String? primaryColor;
  final String? secondaryColor;

  /// Short marketing line shown on the team page and scorecards.
  final String? tagline;

  /// Public URL of the team's uploaded logo. Null = render the monogram
  /// crest on [primaryColor].
  final String? logoUrl;

  /// 1–3 letter override for the crest monogram. Null = derive from [name]
  /// at render time.
  final String? logoMonogram;

  /// Generated logo style, stored in team_colors.crest_kind.
  final CrestKind crestKind;

  /// Mirrors `teams.is_verified`. Renders the tick beside the team name on
  /// the Pool board and anywhere else a crest carries its name.
  final bool isVerified;

  /// Mirrors `teams.status`. An archived team's page is a read-only record:
  /// nobody can post, join or follow it, and only the owner can restore it.
  final TeamStatus status;

  bool get isArchived => status == TeamStatus.archived;

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
          other.city == city &&
          other.foundedYear == foundedYear &&
          other.primaryColor == primaryColor &&
          other.secondaryColor == secondaryColor &&
          other.tagline == tagline &&
          other.logoUrl == logoUrl &&
          other.logoMonogram == logoMonogram &&
          other.crestKind == crestKind &&
          other.isVerified == isVerified &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.createdBy == createdBy;

  @override
  int get hashCode => Object.hash(
        id, createdBy, name, type, privacy, description, homeGround, city,
        foundedYear, primaryColor, secondaryColor, tagline, logoUrl,
        logoMonogram, crestKind, isVerified, status, createdAt, updatedAt,
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

/// Stable wire values shared by editing, persistence, and rendering.
enum CrestKind {
  monogram, initials, shield, upload;

  static CrestKind fromWire(String? value) =>
      values.where((kind) => kind.name == value).firstOrNull ?? monogram;
}
