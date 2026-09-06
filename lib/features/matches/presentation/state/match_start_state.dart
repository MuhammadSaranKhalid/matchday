import 'package:equatable/equatable.dart';

import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';

/// The current user's role on the Match Start screen. Derived from the match
/// row + the live toss outcome — not persisted.
enum MatchStartViewerRole {
  /// A captain on this match, before the toss has settled which side bats.
  /// Both captains sit here between "match created" and the winner's call.
  captain,

  /// User is the captain of the side that will bat innings 1. Hosts the
  /// openers picker and the Start CTA.
  battingCaptain,

  /// Captain of the bowling side. Sees waiting cards.
  bowlingCaptain,

  /// Not a captain on this match (manager / squad / spectator). Always sees
  /// a read-only view.
  spectator,
}

/// The two acts of the toss. Derived from the match row rather than stored:
/// `start_phase` stays 'toss' until the winner has made their call, so the
/// pause in between is visible without a fourth enum label.
enum TossStep {
  /// Nobody has won anything yet. The match creator flips the real coin and
  /// records who won — that action is theirs alone.
  winner,

  /// The winner is known; their captain, and only their captain, chooses to
  /// bat or bowl.
  decision,
}

/// Visible steps in the Match Start progress bar: toss → lineup.
/// [MatchStartPhase.live] is the exit, not a step, so it is not counted.
const int matchStartStepCount = 2;

/// View state of a match in the Match Start flow.
///
/// A passive struct: the live server row, the viewer's derived role, the
/// openers already locked server-side, and the viewer's in-flight selections.
/// Every question the UI asks about "what is selected" is answered here, so
/// widgets never merge pending-vs-locked themselves.
class MatchStartState extends Equatable {
  const MatchStartState({
    required this.match,
    required this.viewerRole,
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.captainOf,
    this.isCreator = false,
    this.lockedStriker,
    this.lockedNonStriker,
    this.pendingTossWinner,
    this.pendingDecision,
    this.pendingStriker,
    this.pendingNonStriker,
    this.isBusy = false,
  });

  /// Live row.
  final Match match;

  /// User's role on this match (derived).
  final MatchStartViewerRole viewerRole;

  /// The side this viewer captains, or null if they captain neither. Roster
  /// identity — independent of the toss, unlike [viewerRole].
  final TeamId? captainOf;

  /// Whether this viewer created the match. Grants exactly one action:
  /// recording who won the toss.
  final bool isCreator;

  /// Side batting innings 1. Null until the toss decision is recorded.
  final TeamId? battingTeamId;

  /// Side bowling innings 1. Null until the toss decision is recorded.
  final TeamId? bowlingTeamId;

  /// Openers already persisted on `match_innings_state` for innings 1,
  /// resolved back to player ref ids. Null before they are submitted.
  final String? lockedStriker;
  final String? lockedNonStriker;

  /// Local form/selection state — what this phone has picked but not yet sent.
  final TeamId? pendingTossWinner;
  final TossDecision? pendingDecision;
  final String? pendingStriker;
  final String? pendingNonStriker;
  final bool isBusy;

  /// Where the match sits in the pre-live progression. Mirrors
  /// [Match.startPhase] for convenience.
  MatchStartPhase get phase => match.startPhase;

  /// Which act of the toss is outstanding. Only meaningful while
  /// [phase] is [MatchStartPhase.toss].
  TossStep get tossStep =>
      match.tossWonBy == null ? TossStep.winner : TossStep.decision;

  /// The side that won the toss, once recorded.
  TeamId? get tossWinnerTeamId => match.tossWonBy;

  /// Zero-based index into the [matchStartStepCount] progress bar.
  int get stepIndex => switch (phase) {
        MatchStartPhase.toss => 0,
        MatchStartPhase.lineup ||
        MatchStartPhase.ready ||
        MatchStartPhase.live => 1,
      };

  bool get isViewerBattingCaptain =>
      viewerRole == MatchStartViewerRole.battingCaptain;

  /// Whether this viewer captains the side that won the toss — the one person
  /// who may choose to bat or bowl.
  bool get isViewerTossWinnerCaptain {
    final won = match.tossWonBy;
    return won != null && captainOf == won;
  }

  /// True when the viewer should see active picker UI for the current phase.
  bool get viewerCanAct => switch (phase) {
        MatchStartPhase.toss => switch (tossStep) {
            TossStep.winner => isCreator,
            TossStep.decision => isViewerTossWinnerCaptain,
          },
        MatchStartPhase.lineup ||
        MatchStartPhase.ready =>
          isViewerBattingCaptain,
        MatchStartPhase.live => false,
      };

  /// Whether the current toss act has everything it needs to be submitted.
  bool get isTossReady => switch (tossStep) {
        TossStep.winner => pendingTossWinner != null,
        TossStep.decision => pendingDecision != null,
      };

  /// The opener shown in each slot: this phone's pick if it has one, else
  /// whatever is already locked server-side.
  String? get striker => pendingStriker ?? lockedStriker;
  String? get nonStriker => pendingNonStriker ?? lockedNonStriker;

  bool get isLineupReady =>
      striker != null && nonStriker != null && striker != nonStriker;

  MatchStartState copyWith({
    Match? match,
    MatchStartViewerRole? viewerRole,
    TeamId? captainOf,
    bool? isCreator,
    TeamId? battingTeamId,
    TeamId? bowlingTeamId,
    String? lockedStriker,
    String? lockedNonStriker,
    TeamId? Function()? pendingTossWinner,
    TossDecision? Function()? pendingDecision,
    String? Function()? pendingStriker,
    String? Function()? pendingNonStriker,
    bool? isBusy,
  }) {
    return MatchStartState(
      match: match ?? this.match,
      viewerRole: viewerRole ?? this.viewerRole,
      captainOf: captainOf ?? this.captainOf,
      isCreator: isCreator ?? this.isCreator,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      lockedStriker: lockedStriker ?? this.lockedStriker,
      lockedNonStriker: lockedNonStriker ?? this.lockedNonStriker,
      pendingTossWinner: pendingTossWinner != null
          ? pendingTossWinner()
          : this.pendingTossWinner,
      pendingDecision:
          pendingDecision != null ? pendingDecision() : this.pendingDecision,
      pendingStriker:
          pendingStriker != null ? pendingStriker() : this.pendingStriker,
      pendingNonStriker: pendingNonStriker != null
          ? pendingNonStriker()
          : this.pendingNonStriker,
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object?> get props => [
        match,
        viewerRole,
        captainOf,
        isCreator,
        battingTeamId,
        bowlingTeamId,
        lockedStriker,
        lockedNonStriker,
        pendingTossWinner,
        pendingDecision,
        pendingStriker,
        pendingNonStriker,
        isBusy,
      ];
}

/// The side [userId] captains on this match, or null for anyone else.
///
/// Reads the captain snapshot on the match row. Since 20260906100000 a
/// trigger keeps those columns filled for every path that puts a team on a
/// match, including tournament fixtures and bracket advancement.
TeamId? captainSideOf(Match m, String? userId) {
  if (userId == null || userId.isEmpty) return null;
  if (m.teamACaptain == userId) return m.teamAId;
  if (m.teamBCaptain == userId) return m.teamBId;
  return null;
}

/// Resolve the viewer's role given the match row + their user id.
///
/// Before the toss decision there is no batting side, so both captains are
/// simply [MatchStartViewerRole.captain] — claiming otherwise would put a
/// "BATTING CAPTAIN" badge on a phone that may end up fielding.
MatchStartViewerRole viewerRoleOnMatch(Match m, String? userId) {
  final side = captainSideOf(m, userId);
  if (side == null) return MatchStartViewerRole.spectator;

  final batting = battingFirstTeam(m);
  if (batting == null) return MatchStartViewerRole.captain;

  return side == batting
      ? MatchStartViewerRole.battingCaptain
      : MatchStartViewerRole.bowlingCaptain;
}

/// Side batting innings 1 given the toss outcome. Mirrors the deployed
/// `_batting_first_team` SQL helper.
TeamId? battingFirstTeam(Match m) {
  final won = m.tossWonBy;
  final decision = m.tossDecision;
  if (won == null || decision == null) return null;
  if (decision == TossDecision.bat) return won;
  if (won == m.teamAId) return m.teamBId;
  if (won == m.teamBId) return m.teamAId;
  return null;
}

/// The `T-12 MIN` / `STARTING NOW` kicker for the header, or null when the
/// start time is too far out (or unset) to be worth showing.
///
/// Pure over [now] so it can be tested without clock control.
String? matchStartCountdownLabel(DateTime? scheduledStart, DateTime now) {
  if (scheduledStart == null) return null;
  final delta = scheduledStart.difference(now);
  if (delta.isNegative && delta.inHours > -2) return 'STARTING NOW';
  if (delta.isNegative) return 'T+${-delta.inMinutes} MIN';
  if (delta.inHours > 1) return null;
  return 'T-${delta.inMinutes} MIN';
}
