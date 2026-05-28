import 'package:flutter/material.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/match_role.dart';

/// View-model struct for the Pavilion → My Matches screen. A passive
/// composition of matches + teams + the current user, pre-rendered into
/// the fields the screen draws. Per CLAUDE.md §5.3 pattern 3.
///
/// v1 scope (per the locked Slice-A plan): no tournament tag (everything
/// tags `Friendly`), no scorer line, no MOM, no milestone styling, no
/// captain deadlines. Past scores are pulled from `innings` totals; if
/// innings are missing the score-line shows em-dashes.
@immutable
class MyMatchesView {
  const MyMatchesView({
    required this.confirmed,
    required this.past,
    required this.totalPastCount,
    required this.pendingRequestsCount,
  });

  const MyMatchesView.empty()
      : confirmed = const [],
        past = const [],
        totalPastCount = 0,
        pendingRequestsCount = 0;

  final List<MyMatchConfirmed> confirmed;
  final List<MyMatchPast> past;

  /// Total past matches the signed-in user has played, including the ones
  /// outside the visible window. Powers the "SEE ALL N MATCHES →" footer.
  final int totalPastCount;

  /// Inbound match requests awaiting reply. Drives the amber banner that
  /// links to the Notifications inbox.
  final int pendingRequestsCount;

  bool get isEmpty => confirmed.isEmpty && past.isEmpty;
}

/// Pre-rendered Confirmed card data.
@immutable
class MyMatchConfirmed {
  const MyMatchConfirmed({
    required this.id,
    required this.tag,
    required this.homeShort,
    required this.homeColor,
    required this.homeName,
    required this.awayShort,
    required this.awayColor,
    required this.awayName,
    required this.when,
    required this.venue,
    required this.role,
    required this.roleKind,
    required this.countdown,
    required this.urgent,
  });

  final String id;
  final String tag;
  final String homeShort;
  final Color homeColor;
  final String homeName;
  final String awayShort;
  final Color awayColor;
  final String awayName;
  final String when;
  final String venue;
  final String role;
  final MatchRoleKind roleKind;
  final String countdown;
  final bool urgent;
}

/// Pre-rendered Past row data.
@immutable
class MyMatchPast {
  const MyMatchPast({
    required this.id,
    required this.tag,
    required this.when,
    required this.homeShort,
    required this.homeColor,
    required this.homeName,
    required this.homeRuns,
    required this.homeWkts,
    required this.awayShort,
    required this.awayColor,
    required this.awayName,
    required this.awayRuns,
    required this.awayWkts,
    required this.homeWon,
    required this.result,
    required this.mine,
  });

  final String id;
  final String tag;
  final String when;
  final String homeShort;
  final Color homeColor;
  final String homeName;
  final int homeRuns;
  final int homeWkts;
  final String awayShort;
  final Color awayColor;
  final String awayName;
  final int awayRuns;
  final int awayWkts;

  /// True when team A (home in this projection) won. Drives row dim.
  final bool homeWon;

  /// `WON` / `LOST` / `TIED` / `SCORED` — the right-side mono chip.
  final String result;

  /// "You: 78 (52)" line. Empty string when stats aren't available — v1
  /// doesn't aggregate batting stats, so this is empty for now.
  final String mine;
}

/// Map a [MatchRoleKind] to (role line text, urgency hint). The `tag`
/// argument is left for the caller (cards include the match tag separately).
({String label, bool urgent}) roleLineFor(
  MatchRoleKind kind,
  Match match, {
  required bool isToday,
}) {
  switch (kind) {
    case MatchRoleKind.captain:
      return (
        label: 'Captain · pick XI',
        urgent: isToday,
      );
    case MatchRoleKind.xi:
      return (
        label: 'On the XI',
        urgent: isToday,
      );
    case MatchRoleKind.scoring:
      return (label: 'Scoring', urgent: false);
    case MatchRoleKind.optional:
      return (label: 'Optional', urgent: false);
    case MatchRoleKind.spectator:
      return (label: '', urgent: false);
  }
}
