import 'package:meta/meta.dart';

/// The organiser, with the only evidence of trustworthiness that means
/// anything: how many cups they have actually run, and since when
/// (artboard 09).
@immutable
class TournamentOrganizer {
  const TournamentOrganizer({
    required this.userId,
    required this.displayName,
    required this.cupsRun,
    this.username,
    this.avatarUrl,
    this.city,
    this.firstCupYear,
    this.completedCups = 0,
  });

  final String userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String? city;

  /// Every non-draft cup they have created, this one included.
  final int cupsRun;
  final int? firstCupYear;
  final int completedCups;

  /// "11 cups run since 2023 · Lahore" — and honest when there is no record:
  /// a first-time organiser is not hidden, they are simply new.
  String get credibilityLine {
    final parts = <String>[];
    if (cupsRun <= 1) {
      parts.add('First cup on matchday');
    } else {
      final since = firstCupYear;
      parts.add(
        '$cupsRun cups run${since == null ? '' : ' since $since'}',
      );
    }
    if (city case final c? when c.isNotEmpty) parts.add(c);
    return parts.join(' · ');
  }

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
      other is TournamentOrganizer &&
          other.userId == userId &&
          other.cupsRun == cupsRun;

  @override
  int get hashCode => Object.hash(userId, cupsRun);
}
