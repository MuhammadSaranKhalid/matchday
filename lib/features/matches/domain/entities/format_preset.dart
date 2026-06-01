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
