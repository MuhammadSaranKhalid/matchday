import 'package:equatable/equatable.dart';

/// Screen-ready structs for the Match Start stages.
///
/// These are the §5.3 "view-model struct" shape: passive data composed from
/// several providers (match + match_players + rosters + teams) so the stage
/// widgets render fields instead of performing joins inside `build()`.

/// One tappable name in the openers picker.
class MatchStartLineupCandidate extends Equatable {
  const MatchStartLineupCandidate({
    required this.refId,
    required this.name,
    this.photoUrl,
    this.jersey,
  });

  /// The player ref id — what the controller stores as the picked opener.
  final String refId;
  final String name;

  /// Avatar URL, or null when the player has none. Unclaimed placeholders
  /// always fall back to their monogram.
  final String? photoUrl;

  final int? jersey;

  @override
  List<Object?> get props => [refId, name, photoUrl, jersey];
}

/// Everything the Ready stage prints, already resolved to display strings.
class MatchStartReadyView extends Equatable {
  const MatchStartReadyView({
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.tossLine,
    required this.formatLine,
    this.strikerName,
    this.nonStrikerName,
  });

  final String battingTeamName;
  final String bowlingTeamName;

  /// e.g. `Kings XI · chose to bat`. Empty before the toss is recorded.
  final String tossLine;

  /// e.g. `T20 · 11-a-side · leather ball`.
  final String formatLine;

  /// Locked openers, resolved to names. Null until they are submitted.
  final String? strikerName;
  final String? nonStrikerName;

  @override
  List<Object?> get props => [
        battingTeamName,
        bowlingTeamName,
        tossLine,
        formatLine,
        strikerName,
        nonStrikerName,
      ];
}
