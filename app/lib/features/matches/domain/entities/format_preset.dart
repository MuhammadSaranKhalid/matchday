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
  });

  final String id;
  final String label;
  final MatchFormat format;

  /// True for the primary quick/frequent presets: T20, T10, 6 Over, 8 Over.
  bool get isFeatured =>
      id == 't20' || id == 't10' || id == 'quick_6' || id == 'quick_8';

  /// Human-friendly brief summary, e.g. "20 overs".
  String get shortDescription =>
      format.oversPerInnings > 0 ? '${format.oversPerInnings} overs' : label;

  /// Coherent maximum overs per bowler derived from total innings overs.
  static int defaultBowlerLimit(int overs) =>
      CricketFormatSelection.suggestedBowlerLimit(overs);

  @override
  List<Object?> get props => [id, label, format];
}

/// Pure Dart representation of format selection + match rules + playing conditions.
class CricketFormatSelection extends Equatable {
  const CricketFormatSelection({
    required this.formatCode,
    required this.overs,
    this.ballsPerOver = 6,
    this.ballType = MatchBallType.tape,
    this.playersPerSide = 11,
    required this.maxOversPerBowler,
    this.inningsPerSide = 1,
  });

  final String formatCode;
  final int overs;
  final int ballsPerOver;
  final MatchBallType ballType;
  final int playersPerSide;
  final int maxOversPerBowler;
  final int inningsPerSide;

  /// Suggested bowler limit based on total overs:
  /// Standard limited-overs cricket uses 1/5 of total overs:
  /// `(overs / 5).ceil().clamp(1, overs)`.
  static int suggestedBowlerLimit(int overs) {
    if (overs <= 0) return 0;
    return (overs / 5).ceil().clamp(1, overs);
  }

  /// Converts this selection into an engine-facing [MatchFormat].
  MatchFormat toMatchFormat() => MatchFormat(
    formatCode: formatCode,
    oversPerInnings: overs,
    playersPerTeam: playersPerSide,
    ballType: ballType,
    maxOversPerBowler: maxOversPerBowler,
    ballsPerOver: ballsPerOver,
    inningsPerSide: inningsPerSide,
  );

  CricketFormatSelection copyWith({
    String? formatCode,
    int? overs,
    int? ballsPerOver,
    MatchBallType? ballType,
    int? playersPerSide,
    int? maxOversPerBowler,
    int? inningsPerSide,
  }) => CricketFormatSelection(
    formatCode: formatCode ?? this.formatCode,
    overs: overs ?? this.overs,
    ballsPerOver: ballsPerOver ?? this.ballsPerOver,
    ballType: ballType ?? this.ballType,
    playersPerSide: playersPerSide ?? this.playersPerSide,
    maxOversPerBowler: maxOversPerBowler ?? this.maxOversPerBowler,
    inningsPerSide: inningsPerSide ?? this.inningsPerSide,
  );

  @override
  List<Object?> get props => [
    formatCode,
    overs,
    ballsPerOver,
    ballType,
    playersPerSide,
    maxOversPerBowler,
    inningsPerSide,
  ];
}
