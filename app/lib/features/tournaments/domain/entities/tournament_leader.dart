import 'package:meta/meta.dart';

/// One row of a tournament leaderboard (artboards 10, 11, 15).
///
/// Batting and bowling share a shape because the canvas draws them with one
/// component — "Stats is one segmented switch over two identical
/// leaderboards" — so the row carries a headline figure and a secondary rate
/// and lets the caller label them.
@immutable
class TournamentLeader {
  const TournamentLeader({
    required this.playerKey,
    required this.displayName,
    required this.isUnclaimed,
    required this.primaryValue,
    required this.rateValue,
    this.teamName,
    this.teamMonogram,
    this.innings = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.highScore = 0,
    this.runsConceded = 0,
    this.bestWickets = 0,
    this.bestRuns = 0,
  });

  /// Stable across the cup: `u:<user_id>` for a claimed player, `x:<id>` for
  /// an unclaimed guest, so two guests with the same name never merge.
  final String playerKey;
  final String displayName;

  /// A guest on somebody's roster. The canvas marks them with an asterisk and
  /// a footnote rather than hiding them — they scored the runs.
  final bool isUnclaimed;

  final String? teamName;
  final String? teamMonogram;

  /// Runs for a batter, wickets for a bowler — the column the list sorts on.
  final int primaryValue;

  /// Strike rate for a batter, economy for a bowler.
  final double rateValue;

  final int innings;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final int highScore;
  final int runsConceded;
  final int bestWickets;
  final int bestRuns;

  /// "5/14" — the bowler's best haul in a single innings.
  String get bestFigures => '$bestWickets/$bestRuns';

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
      other is TournamentLeader &&
          other.playerKey == playerKey &&
          other.primaryValue == primaryValue &&
          other.rateValue == rateValue;

  @override
  int get hashCode => Object.hash(playerKey, primaryValue, rateValue);
}

/// Both leaderboards for one cup, fetched together so "Leading the cup"
/// (artboard 10) is a single await.
@immutable
class TournamentLeaderboards {
  const TournamentLeaderboards({
    this.batting = const [],
    this.bowling = const [],
  });

  final List<TournamentLeader> batting;
  final List<TournamentLeader> bowling;

  TournamentLeader? get orangeCap => batting.isEmpty ? null : batting.first;
  TournamentLeader? get purpleCap => bowling.isEmpty ? null : bowling.first;

  /// The single best innings haul in the cup — "Naseem Shah · 5/14"
  /// (artboard 15). Most wickets first, then fewest runs for that haul.
  TournamentLeader? get bestBowlingFigures {
    if (bowling.isEmpty) return null;
    final ranked = [...bowling]..sort((a, b) {
        final byWickets = b.bestWickets.compareTo(a.bestWickets);
        if (byWickets != 0) return byWickets;
        return a.bestRuns.compareTo(b.bestRuns);
      });
    final best = ranked.first;
    return best.bestWickets == 0 ? null : best;
  }

  bool get isEmpty => batting.isEmpty && bowling.isEmpty;
}
