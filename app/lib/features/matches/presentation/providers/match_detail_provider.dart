import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/domain/entities/team_membership.dart';
import '../../../teams/domain/entities/team_relationship.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../utils/format_display.dart';
import '../widgets/match_detail/pv_v2_data.dart';
import '../widgets/match_detail/pv_v2_map.dart';
import 'matches_providers.dart';
import 'my_matches_providers.dart';

part 'match_detail_provider.g.dart';

const _cricketSetupPermission = 'cricket.match.setup';
const _cancelMatchPermission = 'match.cancel';

/// Which fixture side represents the current viewer.
///
/// `neutral` covers a match-scoped official who is not a member of either team.
enum _ViewerSide { teamA, teamB, neutral }

/// Match Detail provider.
///
/// IMPORTANT ARCHITECTURE:
///
/// The OLD implementation primarily converted:
///
/// MyMatchesView -> PvMatch
///
/// That is a list-card projection and throws away important match state and
/// effective capabilities.
///
/// Real fixtures are now built from:
///
/// Match
/// + teams
/// + viewer memberships
/// + current Cricket phase
/// + effective RBAC
///
/// Pending challenge/request IDs still fall back to MyMatchesView because they
/// are not yet real `matches` rows.
@riverpod
Future<PvMatch?> matchDetail(Ref ref, String matchId) async {
  final memberships = await ref.watch(
    currentUserTeamMembershipsProvider.future,
  );

  // Subscribe to live state so the detail automatically rebuilds when the
  // Cricket workflow changes:
  //
  // toss -> lineup -> ready -> live
  //
  // On the first frame the stream may not have emitted yet, so the normal
  // one-shot match provider remains the hydration fallback.
  final liveMatch = ref.watch(liveMatchProvider(matchId));
  final Match? directMatch =
      liveMatch.value ?? await ref.watch(matchProvider(matchId).future);

  if (directMatch != null) {
    return _buildFixtureDetail(ref, directMatch, memberships);
  }

  // -------------------------------------------------------------------------
  // Pending challenge fallback
  // -------------------------------------------------------------------------
  //
  // A challenge/request ID is not a confirmed match ID. Keep the existing
  // request projection for that special case only.
  final view = await ref.watch(myMatchesViewProvider.future);

  final pvTeams = pvTeamsFromMemberships(memberships);
  final meFallback = pvTeams.isNotEmpty ? pvTeams.first.crest : kPvUnknownCrest;

  for (final match in pvMatchesFromView(view, meFallback: meFallback)) {
    if (match.id == matchId) {
      return match;
    }
  }

  return null;
}

/// Build an actual fixture detail from the canonical Match entity.
///
/// This function is intentionally independent of role-name authorization.
Future<PvMatch> _buildFixtureDetail(
  Ref ref,
  Match match,
  List<TeamMembership> memberships,
) async {
  final teamsRepository = ref.read(teamsRepositoryProvider);

  final teamAResult = await teamsRepository.getTeam(match.teamAId);
  final teamBResult = await teamsRepository.getTeam(match.teamBId);

  final Team? teamA = teamAResult.fold((_) => null, (team) => team);
  final Team? teamB = teamBResult.fold((_) => null, (team) => team);

  final currentUserId = ref.watch(currentUserIdProvider) ?? '';

  final teamAMembership = _membershipFor(memberships, match.teamAId);
  final teamBMembership = _membershipFor(memberships, match.teamBId);

  final viewerSide = _resolveViewerSide(
    match,
    currentUserId: currentUserId,
    teamAMembership: teamAMembership,
    teamBMembership: teamBMembership,
  );

  final permissions = await Future.wait<bool>([
    _canEnterCurrentMatchSetup(ref, match),
    _canCancelMatch(ref, match),
  ]);

  final canStartMatch = permissions[0];
  final canCancelMatch = permissions[1];

  final crestA =
      teamA != null
          ? crestFromTeam(teamA)
          : const PvCrest(short: 'A', name: 'Team A', color: CkColors.muted);
  final crestB =
      teamB != null
          ? crestFromTeam(teamB)
          : const PvCrest(short: 'B', name: 'Team B', color: CkColors.muted);

  // -------------------------------------------------------------------------
  // Correct "me" / "opponent" orientation
  // -------------------------------------------------------------------------
  //
  // The old detail projection always treated Team A as "me".
  //
  // That is wrong whenever the current user belongs to Team B.
  //
  // The new projection places the viewer's own side first when the viewer
  // belongs to one of the teams.
  final bool viewerIsTeamB = viewerSide == _ViewerSide.teamB;

  final PvCrest me = viewerIsTeamB ? crestB : crestA;
  final PvCrest them = viewerIsTeamB ? crestA : crestB;

  final TeamMembership? myMembership = switch (viewerSide) {
    _ViewerSide.teamA => teamAMembership,
    _ViewerSide.teamB => teamBMembership,
    _ViewerSide.neutral => null,
  };

  final bool viewerIsCaptainSnapshot = switch (viewerSide) {
    _ViewerSide.teamA => match.teamACaptain == currentUserId,
    _ViewerSide.teamB => match.teamBCaptain == currentUserId,
    _ViewerSide.neutral => false,
  };

  final relationshipLabel = _relationshipLabel(
    myMembership,
    captainSnapshot: viewerIsCaptainSnapshot,
  );

  final String role =
      viewerSide == _ViewerSide.neutral
          ? (canStartMatch || canCancelMatch ? 'official' : 'viewer')
          : relationshipLabel;

  final String meSubtitle =
      viewerSide == _ViewerSide.neutral ? 'team' : 'you · $relationshipLabel';

  final String themSubtitle =
      viewerSide == _ViewerSide.neutral ? 'team' : 'opponent';

  return PvMatch(
    id: match.id.value,
    phase: _pvPhaseForMatch(match),
    me: me,
    them: them,
    // Display only.
    role: role,
    meSubtitle: meSubtitle,
    themSubtitle: themSubtitle,
    canStartMatch: canStartMatch,
    canCancelMatch: canCancelMatch,
    when: _formatWhen(match.scheduledStartTime),
    venue: _venueLine(match),
    sub: match.matchType.label,
    oversPerInnings: match.format.oversPerInnings,
    ballsPerOver: match.format.ballsPerOver,
    playersPerTeam: match.format.playersPerTeam,
    ballType: match.format.ballType.wire,
    formatCode: _formatCode(match),
  );
}

/// Effective authorization for the CURRENT Cricket setup phase.
///
/// This deliberately mirrors the Edge Function:
///
/// TOSS:
/// match-scoped cricket.match.setup
/// OR
/// setup-side team cricket.match.setup
///
/// LINEUP / READY:
/// match-scoped cricket.match.setup
/// OR
/// batting-team cricket.match.setup
///
/// There is NO role-name check.
/// There is NO time-window check.
Future<bool> _canEnterCurrentMatchSetup(Ref ref, Match match) async {
  if (!match.isPreLiveCricketSetup) {
    return false;
  }

  final repository = ref.read(matchesRepositoryProvider);

  // Match-scoped authority wins first.
  //
  // This is how an explicitly assigned match official can operate a neutral
  // tournament fixture where setup_side is null.
  final matchPermission = await repository.canMatchPermission(
    matchId: match.id,
    permission: _cricketSetupPermission,
  );

  final canMatchScope = matchPermission.fold(
    (_) => false,
    (allowed) => allowed,
  );

  if (canMatchScope) {
    return true;
  }

  // No match grant: use the team controlling the current Cricket phase.
  final controllingTeam = match.currentSetupAuthorityTeamId;

  if (controllingTeam == null) {
    // Fail closed.
    //
    // Examples:
    // - corrupted peer-to-peer fixture with no setup_side
    // - neutral fixture with no assigned match-scoped official
    return false;
  }

  final teamPermission = await repository.canTeamPermission(
    teamId: controllingTeam,
    permission: _cricketSetupPermission,
  );

  return teamPermission.fold((_) => false, (allowed) => allowed);
}

/// Cancellation authorization.
///
/// This is deliberately separate from Cricket Match Start.
///
/// `match.cancel` means administrative authority over the fixture.
/// `cricket.match.setup` means sporting authority over toss/openers/start.
Future<bool> _canCancelMatch(Ref ref, Match match) async {
  // Tournament lifecycle belongs to tournament organizers and the existing
  // tournament_* command family.
  if (match.matchType == MatchType.tournament) {
    return false;
  }

  // A live or terminal fixture cannot use the pre-live cancellation command.
  if (!match.status.isUpcoming) {
    return false;
  }

  final repository = ref.read(matchesRepositoryProvider);

  // Explicit one-match delegation.
  final matchPermission = await repository.canMatchPermission(
    matchId: match.id,
    permission: _cancelMatchPermission,
  );

  final canMatchScope = matchPermission.fold(
    (_) => false,
    (allowed) => allowed,
  );

  if (canMatchScope) {
    return true;
  }

  // Either participating team's administration can cancel.
  //
  // public.team_can() still evaluates the team's configurable matrix.
  final teamAPermission = await repository.canTeamPermission(
    teamId: match.teamAId,
    permission: _cancelMatchPermission,
  );

  if (teamAPermission.fold((_) => false, (allowed) => allowed)) {
    return true;
  }

  final teamBPermission = await repository.canTeamPermission(
    teamId: match.teamBId,
    permission: _cancelMatchPermission,
  );

  return teamBPermission.fold((_) => false, (allowed) => allowed);
}

TeamMembership? _membershipFor(
  List<TeamMembership> memberships,
  TeamId teamId,
) {
  for (final membership in memberships) {
    if (membership.team.id == teamId) {
      return membership;
    }
  }
  return null;
}

_ViewerSide _resolveViewerSide(
  Match match, {
  required String currentUserId,
  required TeamMembership? teamAMembership,
  required TeamMembership? teamBMembership,
}) {
  // Normal case: viewer belongs to exactly one side.
  if (teamAMembership != null && teamBMembership == null) {
    return _ViewerSide.teamA;
  }

  if (teamBMembership != null && teamAMembership == null) {
    return _ViewerSide.teamB;
  }

  // Defensive case: the same account belongs to both participating teams.
  //
  // Prefer the team currently responsible for setup because that is the
  // context that matters most on this screen.
  if (teamAMembership != null && teamBMembership != null) {
    if (match.currentSetupAuthorityTeamId == match.teamBId) {
      return _ViewerSide.teamB;
    }
    return _ViewerSide.teamA;
  }

  // Captain snapshot fallback.
  if (match.teamACaptain == currentUserId) {
    return _ViewerSide.teamA;
  }

  if (match.teamBCaptain == currentUserId) {
    return _ViewerSide.teamB;
  }

  // Assigned match official / spectator.
  return _ViewerSide.neutral;
}

/// Relationship is for display only.
///
/// TeamMembership.relationship is intentionally multi-role aware:
/// staff wins over captain if the same user has both.
String _relationshipLabel(
  TeamMembership? membership, {
  required bool captainSnapshot,
}) {
  if (membership != null) {
    return switch (membership.relationship) {
      TeamRelationship.owner => 'owner',
      TeamRelationship.manager => 'manager',
      TeamRelationship.captain => 'captain',
      TeamRelationship.player => 'player',
      TeamRelationship.none => captainSnapshot ? 'captain' : 'player',
    };
  }

  if (captainSnapshot) {
    return 'captain';
  }

  return 'player';
}

PvPhase _pvPhaseForMatch(Match match) {
  if (match.status.isLive) {
    return PvPhase.live;
  }

  if (match.status.isPast) {
    return PvPhase.completed;
  }

  return PvPhase.scheduled;
}

String _formatWhen(DateTime? value) {
  if (value == null) {
    return 'TBD';
  }

  final local = value.toLocal();
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final tomorrow = today.add(const Duration(days: 1));

  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';

  if (day == today) {
    return 'Today · $time';
  }

  if (day == tomorrow) {
    return 'Tomorrow · $time';
  }

  return '${local.day}/${local.month} · $time';
}

String _venueLine(Match match) {
  final venue = match.venue;
  if (venue == null) {
    return 'TBD';
  }

  final city = venue.city?.trim();
  if (city == null || city.isEmpty) {
    return venue.ground;
  }

  return '${venue.ground} · $city';
}

String _formatCode(Match match) {
  if (match.matchType == MatchType.tournament) {
    return 'Tournament';
  }

  return formatTitle(
    formatCode: match.formatCode ?? match.format.formatCode,
    isCustom: (match.formatCode ?? match.format.formatCode) == 'custom',
    overs: match.format.oversPerInnings,
  );
}
