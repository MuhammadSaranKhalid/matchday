import 'package:flutter/material.dart';

import '../../domain/scoring/scorecard.dart';

/// View-model struct for the completed-match screen (CLAUDE.md §5.3 pattern 3).
///
/// Everything here is derived from the delivery ledger by
/// [buildInningsCard] — there are no aggregate stats tables. The screen is a
/// passive renderer of this struct.
@immutable
class CompletedMatchView {
  const CompletedMatchView({
    required this.title,
    required this.sides,
    required this.tone,
    required this.sentence,
    required this.metaLine,
    required this.innings,
    required this.headline,
    required this.recordRows,
    this.tossLine,
    this.squadsLine,
    this.absenceNote,
  });

  final String title;

  /// Always two entries, batting order of the FIRST innings first — the order
  /// the result card prints them in.
  final List<CompletedSide> sides;

  final ResultTone tone;

  /// "Lions won by 6 wickets · 5 balls left". Never empty.
  final String sentence;

  /// "Sun 6 Sep · Gaddafi B · Friendly · T20".
  final String metaLine;

  /// One card per innings actually bowled. Empty for a walkover or an
  /// abandonment — which is exactly what makes the tab bar disappear.
  final List<InningsCard> innings;

  /// The record page's headline ("No match was played."), null when there is
  /// a ledger to show instead.
  final String? headline;

  /// "The fixture as agreed" rows on the record page.
  final List<({String label, String value})> recordRows;

  final String? tossLine;
  final String? squadsLine;

  /// Prose under [headline] explaining what happened instead of a match.
  final String? absenceNote;

  /// The screen's central branch. With no delivery there is nothing to tab
  /// through, so the tab bar does not render and the screen becomes a printed
  /// record instead of a scorecard with four empty tabs.
  bool get hasLedger => innings.any((i) => i.legalBalls > 0);
}

/// One side's row in the result card.
@immutable
class CompletedSide {
  const CompletedSide({
    required this.teamId,
    required this.sideLetter,
    required this.name,
    required this.short,
    required this.color,
    required this.isYou,
    required this.won,
    required this.batted,
    this.runs,
    this.wickets,
    this.oversLabel,
  });

  final String teamId;

  /// 'a' or 'b' — matches [InningsCard.battingTeamSide], so a table row can
  /// find its team's colour without positional guessing.
  final String sideLetter;

  final String name;
  final String short;
  final Color color;

  /// Marks the viewer's own side with a quiet mono YOU — never with colour.
  final bool isYou;

  /// Drives weight only: the winner is ink at 700, the other ink2 at 600.
  /// A tie lights neither.
  final bool won;

  /// False prints "Did not bat" where the score would go — a rain-shortened
  /// match must not imply a side was bowled out for nothing.
  final bool batted;

  final int? runs;
  final int? wickets;
  final String? oversLabel;

  String get scoreLabel =>
      batted && runs != null ? '$runs/${wickets ?? 0}' : '';
}

/// The single band of colour on the screen, spent once.
enum ResultTone {
  /// A side won — green band.
  won,

  /// Scores level — amber. Lights neither side, demotes neither.
  tied,

  /// No result / abandoned — paper, no colour at all.
  none,
}
