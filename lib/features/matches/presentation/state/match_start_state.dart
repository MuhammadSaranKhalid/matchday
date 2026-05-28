import 'package:flutter/foundation.dart';

import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';

/// The current user's role on the Match Start screen. Derived from the match
/// row + the live toss outcome — not persisted.
enum MatchStartViewerRole {
  /// User is the captain of the side that will bat innings 1. Hosts the
  /// openers picker and the Start CTA.
  battingCaptain,

  /// Captain of the bowling side. Sees waiting cards.
  bowlingCaptain,

  /// Not a captain on this match (manager / squad / spectator). Always sees
  /// a read-only view.
  spectator,
}

/// Read-only view of a match in the Match Start flow. Composes the raw
/// [Match] row + currentUser + the inferred role/batting-team. Per
/// CLAUDE.md §5.3 pattern 3 — passive struct, no behaviour.
@immutable
class MatchStartState {
  const MatchStartState({
    required this.match,
    required this.viewerRole,
    required this.battingTeamId,
    required this.bowlingTeamId,
  });

  /// Live row.
  final Match match;

  /// User's role on this match (derived).
  final MatchStartViewerRole viewerRole;

  /// Side batting innings 1. Null until the toss is recorded.
  final TeamId? battingTeamId;

  /// Side bowling innings 1. Null until the toss is recorded.
  final TeamId? bowlingTeamId;

  /// Where the match sits in the pre-live progression. Mirrors
  /// [Match.startPhase] for convenience.
  MatchStartPhase get phase => match.startPhase;

  /// True when the viewer should see active picker UI for the current phase.
  bool get viewerCanAct {
    switch (phase) {
      case MatchStartPhase.toss:
        // Either captain can flip; design says sender hosts the coin but we
        // allow whichever captain opens the screen first to record.
        return viewerRole == MatchStartViewerRole.battingCaptain ||
            viewerRole == MatchStartViewerRole.bowlingCaptain;
      case MatchStartPhase.lineup:
      case MatchStartPhase.ready:
        return viewerRole == MatchStartViewerRole.battingCaptain;
      case MatchStartPhase.live:
        return false;
    }
  }
}

/// Resolve the viewer's role given the match row + their user id.
MatchStartViewerRole viewerRoleOnMatch(Match m, String? userId) {
  if (userId == null || userId.isEmpty) return MatchStartViewerRole.spectator;
  final batting = battingFirstTeam(m);
  if (batting == null) {
    // Toss not yet recorded — call them by which captaincy they hold.
    if (m.teamACaptain == userId || m.teamBCaptain == userId) {
      return MatchStartViewerRole.battingCaptain; // surrogate
    }
    return MatchStartViewerRole.spectator;
  }
  if (batting == m.teamAId) {
    if (m.teamACaptain == userId) return MatchStartViewerRole.battingCaptain;
    if (m.teamBCaptain == userId) return MatchStartViewerRole.bowlingCaptain;
  } else if (batting == m.teamBId) {
    if (m.teamBCaptain == userId) return MatchStartViewerRole.battingCaptain;
    if (m.teamACaptain == userId) return MatchStartViewerRole.bowlingCaptain;
  }
  return MatchStartViewerRole.spectator;
}

/// Side batting innings 1 given the toss outcome. Mirrors the deployed
/// `_batting_first_team` SQL helper.
TeamId? battingFirstTeam(Match m) {
  final won = m.tossWonBy;
  final decision = m.tossDecision;
  if (won == null || decision == null) return null;
  if (decision == TossDecision.bat) return won;
  // Bowl: the other team bats.
  if (won == m.teamAId) return m.teamBId;
  if (won == m.teamBId) return m.teamAId;
  return null;
}
