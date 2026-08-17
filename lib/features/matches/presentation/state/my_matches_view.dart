import 'package:flutter/material.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/match_request.dart';
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
    required this.sent,
    this.inbound = const [],
  });

  const MyMatchesView.empty()
      : confirmed = const [],
        past = const [],
        totalPastCount = 0,
        pendingRequestsCount = 0,
        sent = const [],
        inbound = const [];

  final List<MyMatchConfirmed> confirmed;
  final List<MyMatchPast> past;

  /// Outbound challenges the signed-in user has sent that are still active.
  final List<MyMatchRequest> sent;

  /// Inbound challenges sent by other teams directly to user's managed teams.
  final List<MyMatchRequest> inbound;

  /// Total past matches the signed-in user has played, including the ones
  /// outside the visible window. Powers the "SEE ALL N MATCHES →" footer.
  final int totalPastCount;

  /// Inbound match requests awaiting reply.
  final int pendingRequestsCount;

  bool get isEmpty =>
      confirmed.isEmpty && past.isEmpty && sent.isEmpty && inbound.isEmpty;
}

/// Pre-rendered request row for the "Requests" section.
@immutable
class MyMatchRequest {
  const MyMatchRequest({
    required this.requestId,
    required this.isOpen,
    required this.opponentName,
    required this.opponentShort,
    required this.opponentColor,
    required this.statusLabel,
    required this.expiresLabel,
    required this.status,
    this.isInbound = false,
    this.shareCode,
  });

  final String requestId;

  /// True when this is an open challenge (no target team).
  final bool isOpen;

  /// True when another team sent this challenge to our team.
  final bool isInbound;

  final String opponentName;
  final String opponentShort;
  final Color opponentColor;

  /// 6-digit share code, present for open challenges.
  final String? shareCode;

  /// e.g. "Awaiting reply" / "Countered" / "Needs your reply".
  final String statusLabel;

  /// e.g. "expires 41h". Empty when no expiry is set.
  final String expiresLabel;

  final MatchRequestStatus status;
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
    this.tossReady = false,
    this.live = false,
    this.helper,
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

  /// True when the match has entered the toss → lineup → ready window —
  /// the captain can tap to open Match Start. Drives the red-glow card +
  /// pulsing red dot + big red "Start match → Toss" CTA per the design's
  /// Case 03b ("Toss time").
  final bool tossReady;

  /// True when the match is in-play (status: live / innings_break /
  /// super_over). Tapping the card routes to the scoring screen instead
  /// of Match Start.
  final bool live;

  /// Optional helper caption shown below the action buttons in a
  /// `tossReady` card. e.g. "Both captains here. Tap to flip the coin
  /// together."
  final String? helper;
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
        label: match.status.isLive ? 'Captain · Live' : 'Captain · pick XI',
        urgent: isToday || match.status.isLive,
      );
    case MatchRoleKind.scoring:
      return (
        label: match.status.isLive ? 'Scorer · Score live' : 'Official Scorer',
        urgent: isToday || match.status.isLive,
      );
    case MatchRoleKind.xi:
      return (
        label: match.status.isLive ? 'In Playing XI · Playing now' : 'Selected in XI',
        urgent: isToday,
      );
    case MatchRoleKind.optional:
      return (label: 'Squad member', urgent: false);
    case MatchRoleKind.spectator:
      return (label: '', urgent: false);
  }
}
