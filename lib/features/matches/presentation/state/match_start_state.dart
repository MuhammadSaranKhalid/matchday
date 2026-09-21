import 'package:equatable/equatable.dart';

import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';

/// Display-only relationship on the Match Start screen.
///
/// IMPORTANT: this enum is NOT an authorization source. Buttons are gated by
/// [canRecordToss] and [canManageBattingSetup], which come from the generic
/// RBAC engine.
enum MatchStartViewerRole { captain, battingCaptain, bowlingCaptain, spectator }

const int matchStartStepCount = 2;

/// Passive state for Match Start.
///
/// Authorization is capability-based:
///
///   phase=toss
///     -> canRecordToss
///
///   phase=lineup/ready
///     -> canManageBattingSetup
///
/// Role/captain fields remain only for labels and presentation.
class MatchStartState extends Equatable {
  const MatchStartState({
    required this.match,
    required this.viewerRole,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.canRecordToss,
    required this.canManageBattingSetup,
    this.captainOf,
    this.lockedStriker,
    this.lockedNonStriker,
    this.pendingTossWinner,
    this.pendingDecision,
    this.pendingStriker,
    this.pendingNonStriker,
    this.isBusy = false,
  });

  final Match match;

  /// Display-only role.
  final MatchStartViewerRole viewerRole;

  /// Display-only captain identity. Never use it to authorize a write.
  final TeamId? captainOf;

  /// Effective RBAC answer for the current user:
  ///
  /// peer-to-peer Cricket:
  ///   cricket_matches.setup_side -> setup team + cricket.match.setup
  ///
  /// neutral/tournament:
  ///   match-scoped cricket.match.setup
  final bool canRecordToss;

  /// Effective RBAC answer for the current user:
  ///
  /// batting team + cricket.match.setup
  /// OR match-scoped cricket.match.setup
  final bool canManageBattingSetup;

  final TeamId? battingTeamId;
  final TeamId? bowlingTeamId;

  final String? lockedStriker;
  final String? lockedNonStriker;

  /// Local toss form state. Winner and decision are submitted together.
  final TeamId? pendingTossWinner;
  final TossDecision? pendingDecision;

  final String? pendingStriker;
  final String? pendingNonStriker;

  final bool isBusy;

  MatchStartPhase get phase => match.startPhase;

  TeamId? get tossWinnerTeamId => match.tossWonBy;

  int get stepIndex => switch (phase) {
    MatchStartPhase.toss => 0,
    MatchStartPhase.lineup ||
    MatchStartPhase.ready ||
    MatchStartPhase.live => 1,
  };

  bool get isViewerBattingCaptain =>
      viewerRole == MatchStartViewerRole.battingCaptain;

  bool get viewerCanAct => switch (phase) {
    MatchStartPhase.toss => canRecordToss,
    MatchStartPhase.lineup || MatchStartPhase.ready => canManageBattingSetup,
    MatchStartPhase.live => false,
  };

  /// Atomic toss needs both values.
  bool get isTossReady => pendingTossWinner != null && pendingDecision != null;

  /// Preview of the first batting team using this phone's pending toss form.
  TeamId? get pendingBattingTeamId {
    final winner = pendingTossWinner;
    final decision = pendingDecision;

    if (winner == null || decision == null) {
      return null;
    }

    if (decision == TossDecision.bat) {
      return winner;
    }

    if (winner == match.teamAId) {
      return match.teamBId;
    }

    if (winner == match.teamBId) {
      return match.teamAId;
    }

    return null;
  }

  String? get striker => pendingStriker ?? lockedStriker;

  String? get nonStriker => pendingNonStriker ?? lockedNonStriker;

  bool get isLineupReady =>
      striker != null && nonStriker != null && striker != nonStriker;

  MatchStartState copyWith({
    Match? match,
    MatchStartViewerRole? viewerRole,
    TeamId? captainOf,
    bool? canRecordToss,
    bool? canManageBattingSetup,
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
      canRecordToss: canRecordToss ?? this.canRecordToss,
      canManageBattingSetup:
          canManageBattingSetup ?? this.canManageBattingSetup,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      lockedStriker: lockedStriker ?? this.lockedStriker,
      lockedNonStriker: lockedNonStriker ?? this.lockedNonStriker,
      pendingTossWinner:
          pendingTossWinner != null
              ? pendingTossWinner()
              : this.pendingTossWinner,
      pendingDecision:
          pendingDecision != null ? pendingDecision() : this.pendingDecision,
      pendingStriker:
          pendingStriker != null ? pendingStriker() : this.pendingStriker,
      pendingNonStriker:
          pendingNonStriker != null
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
    canRecordToss,
    canManageBattingSetup,
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

/// Display-only helper. Match write authorization must use RBAC instead.
TeamId? captainSideOf(Match m, String? userId) {
  if (userId == null || userId.isEmpty) {
    return null;
  }

  if (m.teamACaptain == userId) {
    return m.teamAId;
  }

  if (m.teamBCaptain == userId) {
    return m.teamBId;
  }

  return null;
}

/// Display-only role helper.
MatchStartViewerRole viewerRoleOnMatch(Match m, String? userId) {
  final side = captainSideOf(m, userId);

  if (side == null) {
    return MatchStartViewerRole.spectator;
  }

  final batting = battingFirstTeam(m);

  if (batting == null) {
    return MatchStartViewerRole.captain;
  }

  return side == batting
      ? MatchStartViewerRole.battingCaptain
      : MatchStartViewerRole.bowlingCaptain;
}

/// Display-only helper. Match write authorization must use RBAC instead.
/// Delegates to the domain extension [CricketMatchSetupX.battingFirstTeamId].
TeamId? battingFirstTeam(Match m) => m.battingFirstTeamId;

String? matchStartCountdownLabel(DateTime? scheduledStart, DateTime now) {
  if (scheduledStart == null) {
    return null;
  }

  final delta = scheduledStart.difference(now);

  if (delta.isNegative && delta.inHours > -2) {
    return 'STARTING NOW';
  }

  if (delta.isNegative) {
    return 'T+${-delta.inMinutes} MIN';
  }

  if (delta.inHours > 1) {
    return null;
  }

  return 'T-${delta.inMinutes} MIN';
}
