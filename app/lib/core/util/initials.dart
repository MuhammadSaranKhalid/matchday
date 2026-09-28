/// Monogram derivation for person avatars.
///
/// Lived in duplicate inside `scoring_board.dart` and `sheet_kit.dart`, which
/// meant the bowler badge and the bowler *picker* could disagree about the
/// same player's initials. One copy, one answer.
///
/// The team-side equivalent is `teamMonogram` in the teams feature — it stays
/// separate because a team's monogram can be overridden by
/// `teams.logo_monogram`, which has no player analogue.
library;

/// Up to two uppercase letters for [name]: first initials of the first two
/// words, or the first two characters of a single-word name.
///
/// Returns `'?'` for an empty or whitespace-only name so a badge never
/// renders blank. Callers should prefer passing a real fallback name.
String personInitials(String name) {
  final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final w = words.first;
    return w.substring(0, w.length.clamp(0, 2)).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}
