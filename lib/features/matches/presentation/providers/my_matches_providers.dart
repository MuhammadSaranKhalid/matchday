import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/domain/entities/team_relationship.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../../tournaments/presentation/providers/tournaments_providers.dart';
import '../../domain/entities/innings_summary.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_request.dart';
import '../../domain/entities/match_role.dart';
import '../state/live_panel_match.dart';
import '../state/my_matches_view.dart';
import 'matches_providers.dart';
import 'team_display.dart';

part 'my_matches_providers.g.dart';

/// Composes matches + teams + currentUser + innings into a pre-rendered
/// [MyMatchesView] for the Pavilion screen. Online-only one-shot fetch;
/// pull-to-refresh invalidates self.
@riverpod
Future<MyMatchesView> myMatchesView(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const MyMatchesView.empty();

  final matchesResult =
      await ref.watch(matchesRepositoryProvider).listMyMatches();
  final matches = matchesResult.fold<List<Match>>(
    (f) => throw FailureWrapper(f),
    (list) => list,
  );

  // Outbound active requests — the sender's view of pending/countered
  // challenges. Degrade to empty on failure so a requests error never blanks
  // the matches screen (mirrors the innings fold below).
  final reqResult =
      await ref.watch(matchesRepositoryProvider).listMyMatchChallenges();
  final allRequests =
      reqResult.fold<List<MatchRequest>>((_) => const [], (list) => list);

  // Current memberships are fetched once and carry both the team and the
  // canonical multi-role-aware relationship used below.
  final memberships =
      await ref.watch(currentUserTeamMembershipsProvider.future);
  final teams = [for (final membership in memberships) membership.team];
  final myTeamIds = {for (final membership in memberships) membership.team.id.value};

  final outbound = allRequests
      .where((r) =>
          r.toTeamId != null &&
          myTeamIds.contains(r.fromTeamId.value) &&
          (r.status == MatchRequestStatus.pending ||
              r.status == MatchRequestStatus.countered))
      .toList();

  final inbound = allRequests
      .where((r) =>
          r.toTeamId != null &&
          myTeamIds.contains(r.toTeamId!.value) &&
          (r.status == MatchRequestStatus.pending ||
              r.status == MatchRequestStatus.countered))
      .toList();

  // Nothing at all to show.
  if (matches.isEmpty && outbound.isEmpty && inbound.isEmpty) {
    return const MyMatchesView.empty();
  }

  final teamsById = <String, Team>{for (final t in teams) t.id.value: t};
  final myRoles = <String, TeamRelationship>{
    for (final membership in memberships)
      membership.team.id.value: membership.relationship,
  };

  // Fan-out: any team referenced by a match OR requests that isn't already loaded.
  final missingTeamIds = <String>{};
  for (final m in matches) {
    if (!teamsById.containsKey(m.teamAId.value)) missingTeamIds.add(m.teamAId.value);
    if (!teamsById.containsKey(m.teamBId.value)) missingTeamIds.add(m.teamBId.value);
  }
  for (final r in outbound) {
    final to = r.toTeamId?.value;
    if (to != null && !teamsById.containsKey(to)) missingTeamIds.add(to);
  }
  for (final r in inbound) {
    final from = r.fromTeamId.value;
    if (!teamsById.containsKey(from)) missingTeamIds.add(from);
  }
  if (missingTeamIds.isNotEmpty) {
    await Future.wait(
      missingTeamIds.map((id) async {
        final result =
            await ref.read(teamsRepositoryProvider).getTeam(TeamId(id));
        final team = result.fold((_) => null, (t) => t);
        if (team != null) teamsById[id] = team;
      }),
    );
  }

  // Competition names for the meta line. The design prints "Ravi Cup T20 ·
  // Ravi Ground 2 · 16 ov"; without this the card could only say the literal
  // word "Tournament", which tells the reader nothing they did not know.
  final tournamentNames = <String, String>{};
  for (final id in matches.map((m) => m.tournamentId).whereType<String>().toSet()) {
    try {
      final t = await ref.watch(tournamentDetailProvider(id).future);
      tournamentNames[id] = t.name;
    } catch (_) {
      // A cup we cannot read (deleted, or private to someone else) simply
      // falls back to the generic label rather than failing the whole screen.
    }
  }

  final past = matches.where((m) => m.status.isPast).toList();
  final upcoming = matches
      .where((m) => m.status.isUpcoming || m.status.isLive)
      .toList()
    ..sort(_byScheduledThenCreated);

  Map<MatchId, List<InningsSummary>> inningsByMatch = const {};
  if (past.isNotEmpty) {
    final result = await ref
        .read(matchesRepositoryProvider)
        .listInningsForMatches(past.map((m) => m.id));
    inningsByMatch = result.fold((_) => const {}, (map) => map);
  }

  // Past sorted by recency descending (createdAt as proxy when end_time not
  // surfaced on the entity).
  past.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Match Start UI authority comes from the generic RBAC system, not role
  // names. Ask the same capability system the Edge Function enforces.
  const setupPermission = 'cricket.match.setup';
  final repo = ref.read(matchesRepositoryProvider);
  final canSetupByMatchId = <String, bool>{};

  await Future.wait(
    upcoming.map((m) async {
      final matchScoped = await repo.canMatchPermission(
        matchId: m.id,
        permission: setupPermission,
      );
      final canMatch = matchScoped.fold((_) => false, (v) => v);

      final teamId = _setupAuthorityTeam(m);
      var canTeam = false;
      if (teamId != null) {
        final teamScoped = await repo.canTeamPermission(
          teamId: teamId,
          permission: setupPermission,
        );
        canTeam = teamScoped.fold((_) => false, (v) => v);
      }

      canSetupByMatchId[m.id.value] = canMatch || canTeam;
    }),
  );

  final confirmedRows = [
    for (final m in upcoming)
      _confirmedFor(m, teamsById,
          currentUserId: userId,
          myRoles: myRoles,
          canSetup: canSetupByMatchId[m.id.value] ?? false,
          tournamentNames: tournamentNames),
  ];
  final pastRows = [
    for (final m in past)
      _pastFor(m, teamsById,
          innings: inningsByMatch[m.id] ?? const [],
          currentUserId: userId,
          myRoles: myRoles,
          tournamentNames: tournamentNames),
  ];
  final sentRows = [for (final r in outbound) sentRequestRow(r, teamsById)];
  final inboundRows = [for (final r in inbound) inboundRequestRow(r, teamsById)];

  return MyMatchesView(
    confirmed: confirmedRows,
    past: pastRows.take(_pastWindow).toList(),
    totalPastCount: pastRows.length,
    pendingRequestsCount: inboundRows.length,
    sent: sentRows,
    inbound: inboundRows,
  );
}

const _pastWindow = 5;

int _byScheduledThenCreated(Match a, Match b) {
  final aT = a.scheduledStartTime ?? a.createdAt;
  final bT = b.scheduledStartTime ?? b.createdAt;
  return aT.compareTo(bT);
}

/// Team whose role matrix controls the current pre-live setup action.
///
/// Toss -> Cricket setup team.
/// Lineup/ready -> batting team.
/// Match-scoped official authority is checked separately.
TeamId? _setupAuthorityTeam(Match m) {
  if (m.startPhase == MatchStartPhase.toss) {
    return m.setupTeamId;
  }

  if (m.startPhase == MatchStartPhase.lineup ||
      m.startPhase == MatchStartPhase.ready) {
    final won = m.tossWonBy;
    final decision = m.tossDecision;
    if (won == null || decision == null) return null;
    if (decision == TossDecision.bat) return won;
    if (won == m.teamAId) return m.teamBId;
    if (won == m.teamBId) return m.teamAId;
  }

  return null;
}

MyMatchConfirmed _confirmedFor(
  Match m,
  Map<String, Team> teamsById, {
  required String currentUserId,
  required Map<String, TeamRelationship> myRoles,
  required bool canSetup,
  Map<String, String> tournamentNames = const {},
}) {
  final home = teamsById[m.teamAId.value];
  final away = teamsById[m.teamBId.value];
  final start = m.scheduledStartTime;
  final isToday = start != null && _isSameDay(start, DateTime.now());

  // Teams on this fixture where the viewer holds match-day authority.
  // 2026-09-10: was `isManagedBy`, which read the dead `teams.managers` array
  // and — the actual bug — could not see a captain at all, so a captain's own
  // match never counted as theirs.
  final userTeamIds = {
    if (myRoles[m.teamAId.value]?.hasMatchAuthority ?? false) m.teamAId.value,
    if (myRoles[m.teamBId.value]?.hasMatchAuthority ?? false) m.teamBId.value,
  };
  final role = roleOnMatch(m, currentUserId, userTeamIds: userTeamIds);
  final roleLine = roleLineFor(role, m, isToday: isToday);

  // Match Start CTA is capability-driven. A team-specific role override may
  // allow or deny owner/manager/captain independently, and an assigned match
  // official may act through a match-scoped grant.
  final now = DateTime.now();
  final timeBracket = start != null &&
      now.isAfter(start.subtract(const Duration(minutes: 30))) &&
      now.isBefore(start.add(const Duration(hours: 6)));

  final setupInProgress =
      canSetup &&
      (m.status == MatchStatus.toss ||
          m.startPhase == MatchStartPhase.lineup ||
          m.startPhase == MatchStartPhase.ready);

  final tossReady = setupInProgress ||
      (canSetup &&
          (m.status == MatchStatus.scheduled ||
              m.status == MatchStatus.rescheduled) &&
          timeBracket);

  final when = tossReady
      ? 'Match setup · ${_hhmm(start ?? DateTime.now())}'
      : _formatWhen(start, m.createdAt);
  final role0 = tossReady ? 'Match setup · ready when you are' : roleLine.label;
  final countdown =
      tossReady ? 'Now' : _countdown(start, status: m.status);
  final urgent = tossReady || roleLine.urgent || _isUrgent(start, status: m.status);
  final helper = tossReady
      ? (m.startPhase == MatchStartPhase.toss
          ? 'The Cricket setup side records the complete toss: winner plus bat/bowl choice.'
          : 'The batting side selects the openers and starts the match.')
      : null;

  return MyMatchConfirmed(
    id: m.id.value,
    tag: 'Friendly',
    homeTeamId: m.teamAId.value,
    awayTeamId: m.teamBId.value,
    oversPerInnings: m.format.oversPerInnings,
    ballsPerOver: m.format.ballsPerOver,
    homeShort: _short(home, fallback: 'A'),
    homeColor: _color(home?.primaryColor, fallback: const Color(0xFF7A746A)),
    homeName: home?.name ?? 'Team A',
    awayShort: _short(away, fallback: 'B'),
    awayColor: _color(away?.primaryColor, fallback: const Color(0xFF7A746A)),
    awayName: away?.name ?? 'Team B',
    when: when,
    venue: _venueLine(m),
    role: role0,
    roleKind: role,
    countdown: countdown,
    urgent: urgent,
    live: m.status.isLive,
    tossReady: tossReady,
    helper: helper,
    startTime: start,
    metaLine: _metaLine(m, tournamentNames),
    // Match Start duty is capability-based. Live scoring duty keeps its
    // existing presentation role until the scoring UI is capability-refactored.
    roleIsDuty: tossReady ||
        (role == MatchRoleKind.scoring && m.status.isLive),
    liveState: switch (m.status) {
      MatchStatus.live => 'LIVE',
      MatchStatus.inningsBreak => 'BREAK',
      MatchStatus.superOver => 'SUPER OVER',
      _ => null,
    },
    liveSince: m.status.isLive && m.actualStartTime != null
        ? 'Started ${_hhmm(m.actualStartTime!)}'
        : null,
    youIsHome: userTeamIds.contains(m.teamAId.value) ||
        m.teamACaptain == currentUserId,
    opponentTbc: away == null && m.tournamentId != null,
  );
}

MyMatchPast _pastFor(
  Match m,
  Map<String, Team> teamsById, {
  Map<String, String> tournamentNames = const {},
  required List<InningsSummary> innings,
  required String currentUserId,
  required Map<String, TeamRelationship> myRoles,
}) {
  final home = teamsById[m.teamAId.value];
  final away = teamsById[m.teamBId.value];

  // Per-team final score = innings where batting_team_id matches.
  InningsSummary? innFor(TeamId id) =>
      innings.where((i) => i.battingTeamId == id).fold<InningsSummary?>(
            null,
            (acc, it) =>
                acc == null || it.inningsNumber > acc.inningsNumber ? it : acc,
          );
  final homeInn = innFor(m.teamAId);
  final awayInn = innFor(m.teamBId);

  final homeWon = (homeInn?.totalRuns ?? -1) > (awayInn?.totalRuns ?? -1);
  // Is the user on the home side? (manager OR captain).
  // XI-membership check was removed when matches stopped carrying squad
  // uuid[] columns directly; per-match XI now lives on match_players.
  // For the past-tile attribution v1, manager-or-captain is enough —
  // matches without a clear winner-side fallback still render correctly.
  final onHome = (myRoles[m.teamAId.value]?.hasMatchAuthority ?? false) ||
      m.teamACaptain == currentUserId;
  final myWon = onHome ? homeWon : !homeWon;

  return MyMatchPast(
    id: m.id.value,
    tag: 'Friendly',
    when: _formatDate(m.scheduledStartTime ?? m.createdAt),
    homeShort: _short(home, fallback: 'A'),
    homeColor: _color(home?.primaryColor, fallback: const Color(0xFF7A746A)),
    homeName: home?.name ?? 'Team A',
    homeRuns: homeInn?.totalRuns ?? 0,
    homeWkts: homeInn?.totalWickets ?? 0,
    awayShort: _short(away, fallback: 'B'),
    awayColor: _color(away?.primaryColor, fallback: const Color(0xFF7A746A)),
    awayName: away?.name ?? 'Team B',
    awayRuns: awayInn?.totalRuns ?? 0,
    awayWkts: awayInn?.totalWickets ?? 0,
    homeWon: homeWon,
    // The one-word chip. `tied` and `no_result` are real statuses since the
    // 2026-09-06 enum reconciliation and used to both mislabel as ABANDONED.
    result: switch (m.status) {
      MatchStatus.completed => myWon ? 'Won' : 'Lost',
      MatchStatus.tied => 'Tied',
      MatchStatus.noResult => 'No result',
      MatchStatus.walkover => 'Walkover',
      _ => 'Abandoned',
    },
    mine: '',
    startTime: m.scheduledStartTime ?? m.createdAt,
    metaLine: _metaLine(m, tournamentNames),
    // The result as a sentence is the card's hero; the chip only summarises it.
    sentence: _resultSentence(m, home: home, away: away, homeWon: homeWon),
    homeOvers: _oversLabel(homeInn, m),
    awayOvers: _oversLabel(awayInn, m),
    // A walkover was never bowled, so printing 0/0 would be a lie.
    showScores: m.status != MatchStatus.walkover,
    mineIsHome: onHome,
    note: switch (m.status) {
      MatchStatus.walkover => 'Opposition did not arrive · no overs bowled',
      MatchStatus.noResult => 'Rain stopped play · result not awarded',
      _ => null,
    },
  );
}

/// Pre-render an OUTBOUND challenge row. Public because My Challenges renders
/// the same rows now that requests have moved off My Matches.
MyMatchRequest sentRequestRow(MatchRequest r, Map<String, Team> teamsById) {
  final isOpen = r.toTeamId == null;
  final opp = isOpen ? null : teamsById[r.toTeamId!.value];
  return MyMatchRequest(
    requestId: r.id.value,
    isOpen: isOpen,
    isInbound: false,
    opponentName: isOpen ? 'Open challenge' : (opp?.name ?? 'A team'),
    opponentShort: isOpen ? 'OPN' : _short(opp, fallback: '?'),
    opponentColor: isOpen
        ? const Color(0xFF7A746A)
        : _color(opp?.primaryColor, fallback: const Color(0xFF7A746A)),
    shareCode: r.shareCode,
    statusLabel: r.status == MatchRequestStatus.countered
        ? 'Countered'
        : 'Awaiting reply',
    expiresLabel: _expiresLabel(r),
    status: r.status,
  );
}

/// Pre-render an INBOUND challenge row. See [sentRequestRow].
MyMatchRequest inboundRequestRow(MatchRequest r, Map<String, Team> teamsById) {
  final challenger = teamsById[r.fromTeamId.value];
  return MyMatchRequest(
    requestId: r.id.value,
    isOpen: false,
    isInbound: true,
    opponentName: challenger?.name ?? 'Challenging Team',
    opponentShort: _short(challenger, fallback: 'CH'),
    opponentColor: _color(challenger?.primaryColor, fallback: const Color(0xFF7A746A)),
    shareCode: r.shareCode,
    statusLabel: r.status == MatchRequestStatus.countered
        ? 'Countered by you'
        : 'Needs your reply',
    expiresLabel: _expiresLabel(r),
    status: r.status,
  );
}

/// "expires 41h" / "expires 12m" / "expires 2d" for an active request. Picks
/// the timer that governs the current state. Empty when no expiry is set.
String _expiresLabel(MatchRequest r) {
  final expiry = r.status == MatchRequestStatus.countered
      ? r.counterExpiresAt
      : r.proposalExpiresAt;
  if (expiry == null) return '';
  final remaining = expiry.difference(DateTime.now());
  if (remaining.isNegative) return 'expiring now';
  if (remaining.inHours < 1) return 'expires ${remaining.inMinutes}m';
  if (remaining.inHours < 48) return 'expires ${remaining.inHours}h';
  return 'expires ${remaining.inDays}d';
}

String _short(Team? t, {required String fallback}) =>
    teamShort(t, fallback: fallback);

Color _color(String? hex, {required Color fallback}) =>
    teamColor(hex, fallback: fallback);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _venueLine(Match m) {
  final v = m.venue;
  if (v == null) return '';
  if (v.city == null || v.city!.isEmpty) return v.ground;
  return '${v.ground} · ${v.city}';
}

String _formatWhen(DateTime? scheduled, DateTime fallback) {
  final t = scheduled ?? fallback;
  final now = DateTime.now();
  if (_isSameDay(t, now)) {
    return 'Today · ${_hhmm(t)}';
  }
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  if (_isSameDay(t, tomorrow)) {
    return 'Tomorrow · ${_hhmm(t)}';
  }
  return '${_dayOfWeekShort(t)} ${t.day} · ${_hhmm(t)}';
}

String _formatDate(DateTime t) =>
    '${_dayOfWeekShort(t)} ${t.day} ${_monthShort(t)}';

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _dayOfWeekShort(DateTime t) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];

String _monthShort(DateTime t) => const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][t.month - 1];

String _countdown(DateTime? scheduled, {required MatchStatus status}) {
  if (status.isLive) return 'LIVE';
  if (scheduled == null) return '';
  final delta = scheduled.difference(DateTime.now());
  if (delta.isNegative) return 'Past';
  if (delta.inHours < 1) return 'In ${delta.inMinutes}m';
  if (delta.inHours < 24) {
    final h = delta.inHours;
    final m = delta.inMinutes - h * 60;
    return m == 0 ? 'In ${h}h' : 'In ${h}h ${m}m';
  }
  final days = delta.inDays;
  return days == 1 ? 'In 1 day' : 'In $days days';
}

bool _isUrgent(DateTime? scheduled, {required MatchStatus status}) {
  if (status.isLive) return true;
  if (scheduled == null) return false;
  final delta = scheduled.difference(DateTime.now());
  return !delta.isNegative && delta.inHours < 24;
}

/// The one live match the side panel promotes into its hero card, with the
/// current innings numbers attached. Null when nothing of the user's is live.
///
/// Autodispose: the drawer only builds while it is open (Flutter's
/// `DrawerController` short-circuits its child when dismissed), so this
/// resolves on open and is torn down on close.
///
/// Scope note (design open question 2): when more than one of the user's
/// matches is live the panel shows a single card rather than growing — the
/// rest stay counted on the My Matches row.
@riverpod
Future<LivePanelMatch?> livePanelMatch(Ref ref) async {
  final view = await ref.watch(myMatchesViewProvider.future);
  final live = view.confirmed.where((m) => m.live).toList();
  if (live.isEmpty) return null;
  final row = live.first;

  final result = await ref
      .watch(matchesRepositoryProvider)
      .listInningsForMatches([MatchId(row.id)]);
  final innings = result.fold<List<InningsSummary>>((_) => const [], (map) {
    final list = [...?map[MatchId(row.id)]];
    list.sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    return list;
  });
  if (innings.isEmpty) return null;

  final current = innings.last;
  final battingIsHome = current.battingTeamId.value == row.homeTeamId;

  // Whatever the other side has already put on the board. Absent in the first
  // innings, where the design's second row reads as an em-dash.
  final chased = innings
      .where((i) => i.battingTeamId != current.battingTeamId)
      .fold<InningsSummary?>(
        null,
        (acc, i) => acc == null || i.totalRuns > acc.totalRuns ? i : acc,
      );

  final bpo = row.ballsPerOver > 0 ? row.ballsPerOver : 6;
  String overs(int balls) => '${balls ~/ bpo}.${balls % bpo}';

  // Limited-overs only: an unlimited format has no ball budget to count down.
  final ballsAllowed = row.oversPerInnings * bpo;
  final ballsLeft = ballsAllowed - current.legalBallsFaced;

  String? targetLine;
  if (chased != null) {
    final need = chased.totalRuns + 1 - current.totalRuns;
    if (need > 0 && ballsAllowed > 0 && ballsLeft > 0) {
      targetLine = 'Need $need off $ballsLeft';
    }
  } else if (ballsAllowed > 0 && ballsLeft > 0) {
    targetLine = '${overs(ballsLeft)} overs left';
  }

  return LivePanelMatch(
    matchId: row.id,
    oversLabel: overs(current.legalBallsFaced),
    battingShort: battingIsHome ? row.homeShort : row.awayShort,
    battingColor: battingIsHome ? row.homeColor : row.awayColor,
    battingName: battingIsHome ? row.homeName : row.awayName,
    battingScore: '${current.totalRuns}/${current.totalWickets}',
    opponentShort: battingIsHome ? row.awayShort : row.homeShort,
    opponentColor: battingIsHome ? row.awayColor : row.homeColor,
    opponentName: battingIsHome ? row.awayName : row.homeName,
    opponentScore: chased == null ? '—' : '${chased.totalRuns}',
    targetLine: targetLine,
  );
}

// ─── New-card helpers (My Matches.dc.html) ──────────────────────────────────

/// "Ravi Cup T20 · Ravi Ground 2 · 16 ov" — competition, ground, overs.
/// A friendly says so where a tournament would name itself.
String _metaLine(Match m, [Map<String, String> tournamentNames = const {}]) {
  final tid = m.tournamentId;
  final comp = tid == null
      ? 'Friendly'
      : (tournamentNames[tid] ?? 'Tournament');
  final ground = m.venue?.ground;
  final overs = m.format.oversPerInnings == 0
      ? null
      : '${m.format.oversPerInnings} ov';
  return [comp, ground, overs]
      .where((p) => p != null && p.isNotEmpty)
      .join(' · ');
}

/// Overs faced, from the legal-ball count: 98 balls at 6 per over is "16.2".
String _oversLabel(InningsSummary? inn, Match m) {
  if (inn == null) return '';
  final bpo = m.format.ballsPerOver == 0 ? 6 : m.format.ballsPerOver;
  final balls = inn.legalBallsFaced;
  return '${balls ~/ bpo}.${balls % bpo}';
}

/// The result as a sentence — the past card's hero. The chip beside it is only
/// the one-word summary, so this carries the margin and the reason.
String _resultSentence(
  Match m, {
  required Team? home,
  required Team? away,
  required bool homeWon,
}) {
  String shortName(Team? t) {
    final n = (t?.name ?? '').trim();
    if (n.isEmpty) return 'They';
    final parts = n.split(RegExp(r'\s+'));
    return parts.length > 1 ? parts.last : n;
  }

  switch (m.status) {
    case MatchStatus.tied:
      return 'Match tied · scores level';
    case MatchStatus.noResult:
      return 'No result · rain stopped play';
    case MatchStatus.walkover:
      return 'Awarded to ${(homeWon ? home : away)?.name ?? 'the other side'}';
    case MatchStatus.abandoned:
      return 'Abandoned before the toss';
    case MatchStatus.completed:
      final winner = shortName(homeWon ? home : away);
      // Prefer the server's own sentence when it wrote one — it knows the
      // margin ("won by 24 runs" vs "won by 3 wickets"), which cannot be
      // recomputed here without the full scorecard.
      final summary = (m.resultDescription ?? '').trim();
      if (summary.isNotEmpty) return summary;
      return '$winner won';
    default:
      return 'Match ended';
  }
}
