/// A team. [managers] holds owner + manager user ids (Phase 1: just the
/// owner). Colours are stored as hex strings for the crest avatar.
class Team {
  const Team({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.privacy,
    required this.managers,
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
  });

  final TeamId id;
  final String ownerId;
  final String name;
  final TeamType type;
  final TeamPrivacy privacy;
  final List<String> managers;
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

  bool isManagedBy(String userId) =>
      ownerId == userId || managers.contains(userId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          other.id == id &&
          other.ownerId == ownerId &&
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
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          _sameManagers(other.managers, managers);

  static bool _sameManagers(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id, ownerId, name, type, privacy, description, homeGround, city,
        foundedYear, primaryColor, secondaryColor, tagline, logoUrl,
        logoMonogram, createdAt, updatedAt, Object.hashAll(managers),
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

enum TeamPrivacy {
  public('public'),
  private('private');

  const TeamPrivacy(this.wire);
  final String wire;

  static TeamPrivacy fromWire(String? wire) =>
      values.where((p) => p.wire == wire).firstOrNull ?? TeamPrivacy.public;
}
