import 'package:meta/meta.dart';

/// The roles a fixture can appoint (artboard 27j).
///
/// `scorer` is here so one screen can show the whole team sheet, but it is
/// assigned through `assignScorer` — it carries lifecycle rules the umpire
/// roles do not (a live match cannot change scorer without a handover).
enum OfficialRole {
  scorer('scorer', 'Official digital scorer'),
  umpireMain('umpire_main', 'Umpire 1'),
  umpireLeg('umpire_leg', 'Umpire 2'),
  umpireThird('umpire_third', 'Third umpire'),
  referee('referee', 'Match referee');

  const OfficialRole(this.wire, this.label);
  final String wire;
  final String label;

  bool get isUmpire =>
      this == umpireMain || this == umpireLeg || this == umpireThird;

  static OfficialRole? fromWire(String? wire) =>
      values.where((r) => r.wire == wire).firstOrNull;
}

/// Somebody appointed to a fixture (artboard 27j).
@immutable
class MatchOfficial {
  const MatchOfficial({
    required this.userId,
    required this.displayName,
    required this.role,
    this.username,
    this.avatarUrl,
    this.clubName,
    this.isNeutral = true,
    this.assignedAt,
  });

  final String userId;
  final String displayName;
  final OfficialRole role;
  final String? username;
  final String? avatarUrl;

  /// The club this person owns or manages — shown so the organiser can see the
  /// neutrality rule being satisfied rather than merely asserted.
  final String? clubName;

  /// False when they belong to one of the two sides in this fixture.
  final bool isNeutral;
  final DateTime? assignedAt;

  String get monogram {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return displayName.trim().padRight(2).substring(0, 2).trim().toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchOfficial && other.userId == userId && other.role == role;

  @override
  int get hashCode => Object.hash(userId, role);
}

/// Somebody who *could* be appointed (artboard 27j, "Assign umpire 2").
@immutable
class OfficialCandidate {
  const OfficialCandidate({
    required this.userId,
    required this.displayName,
    required this.isNeutral,
    required this.matchesOfficiated,
    this.username,
    this.avatarUrl,
    this.clubName,
    this.busyOn,
  });

  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String? clubName;

  /// False when they play for or manage one of the two sides.
  final bool isNeutral;
  final int matchesOfficiated;

  /// "Also on Match 6" — a clash inside four hours of this fixture. Shown, not
  /// enforced: a small cup often runs on one person, and the organiser knows
  /// their own ground better than a rule does.
  final String? busyOn;

  String get monogram {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return displayName.trim().padRight(2).substring(0, 2).trim().toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfficialCandidate && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}
