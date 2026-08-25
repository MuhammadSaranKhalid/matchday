import 'package:flutter/material.dart';

/// Pre-rendered data for the side panel's live-match card.
///
/// Artboard **B** of the Side Panel design: a live match is not a chip, it is a
/// `redSoft` card pinned directly under identity, above `YOURS`. This is a
/// passive view-model struct (CLAUDE.md §5.3 pattern 3) — every field is
/// already formatted for the row that draws it.
@immutable
class LivePanelMatch {
  const LivePanelMatch({
    required this.matchId,
    required this.oversLabel,
    required this.battingShort,
    required this.battingColor,
    required this.battingName,
    required this.battingScore,
    required this.opponentShort,
    required this.opponentColor,
    required this.opponentName,
    required this.opponentScore,
    this.targetLine,
  });

  final String matchId;

  /// `14.2` — legal balls faced rendered as overs.
  final String oversLabel;

  final String battingShort;
  final Color battingColor;
  final String battingName;

  /// `142/6`.
  final String battingScore;

  final String opponentShort;
  final Color opponentColor;
  final String opponentName;

  /// The side that has finished batting — `154`, or `—` in the first innings.
  final String opponentScore;

  /// `Need 13 off 34` while chasing, `5.4 overs left` in a limited-overs first
  /// innings. Null when neither applies (unlimited overs, first innings) — the
  /// card then keeps its chevron row without a label.
  final String? targetLine;
}
