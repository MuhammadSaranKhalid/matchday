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
