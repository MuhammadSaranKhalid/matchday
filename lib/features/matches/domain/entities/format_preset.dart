import 'package:equatable/equatable.dart';

import 'match.dart';

/// A selectable match format from the backend `format_presets` catalog.
///
/// The catalog is the source of truth for the setup picker. When a match is
/// created, the chosen [format] is snapshotted into `matches.format` (the
/// scoring engine only ever reads that snapshot — editing the catalog never
/// changes a match already created).
class FormatPreset extends Equatable {
  const FormatPreset({
    required this.id,
    required this.label,
    required this.format,
    this.defaultScoringMode = ScoringMode.liveBallByBall,
  });

  final String id;
  final String label;
  final MatchFormat format;
  final ScoringMode defaultScoringMode;

  /// True for the primary 2×2 grid cards: T10, T20, 50 Over.
  bool get isFeatured => id == 't10' || id == 't20' || id == 'over_50';

  /// Human-friendly brief summary, e.g. "20 overs".
  String get shortDescription =>
      format.oversPerInnings > 0 ? '${format.oversPerInnings} overs' : label;

  /// Coherent maximum overs per bowler derived from total innings overs.
  static int defaultBowlerLimit(int overs) {
    if (overs <= 0) return 0;
    if (overs <= 6) return 2;
    if (overs <= 8) return 2;
    if (overs <= 10) return 2;
    if (overs <= 20) return 4;
    if (overs <= 30) return 6;
    if (overs <= 40) return 8;
    if (overs <= 45) return 9;
    if (overs <= 50) return 10;
    return (overs / 5).ceil().clamp(1, overs);
  }

  @override
  List<Object?> get props => [id, label, format, defaultScoringMode];
}

/// How a format is meant to be scored. Mirrors the deployed `scoring_mode` enum.
enum ScoringMode {
  liveBallByBall('live_ball_by_ball'),
  postMatchScorecard('post_match_scorecard');

  const ScoringMode(this.wire);
  final String wire;

  static ScoringMode fromWire(String? w) =>
      values.where((m) => m.wire == w).firstOrNull ??
      ScoringMode.liveBallByBall;
}
