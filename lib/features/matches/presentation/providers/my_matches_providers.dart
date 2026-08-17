import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/innings_summary.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_request.dart';
import '../../domain/entities/match_role.dart';
import '../state/my_matches_view.dart';
import 'matches_providers.dart';

part 'my_matches_providers.g.dart';

/// Composes matches + teams + currentUser + innings into a pre-rendered
/// [MyMatchesView] for the Pavilion screen. Online-only one-shot fetch;
/// pull-to-refresh invalidates self.
@riverpod
Future<MyMatchesView> myMatchesView(Ref ref) async {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return const MyMatchesView.empty();

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

  // Resolve teams owned/managed by the user without hanging on stream .future.
  final teamsAsync = ref.watch(myTeamsProvider);
  final teams = teamsAsync.value ?? const <Team>[];
  final myTeamIds = {for (final t in teams) t.id.value};

  final outbound = allRequests
      .where((r) =>
          myTeamIds.contains(r.fromTeamId.value) &&
          (r.status == MatchRequestStatus.pending ||
              r.status == MatchRequestStatus.countered))
      .toList();

  // Nothing at all to show.
  if (matches.isEmpty && outbound.isEmpty) {
    return const MyMatchesView.empty();
  }

  final teamsById = <String, Team>{for (final t in teams) t.id.value: t};

  // Fan-out: any team referenced by a match OR an outbound request (the
  // opponent you challenged) that isn't already loaded. One-shot getTeam —
  // cheap relative to the list roundtrips.
  final missingTeamIds = <String>{};
  for (final m in matches) {
    if (!teamsById.containsKey(m.teamAId.value)) missingTeamIds.add(m.teamAId.value);
    if (!teamsById.containsKey(m.teamBId.value)) missingTeamIds.add(m.teamBId.value);
  }
  for (final r in outbound) {
    final to = r.toTeamId?.value;
    if (to != null && !teamsById.containsKey(to)) missingTeamIds.add(to);
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

  final confirmedRows = [
    for (final m in upcoming)
      _confirmedFor(m, teamsById, currentUserId: user.id.value),
  ];
  final pastRows = [
    for (final m in past)
      _pastFor(m, teamsById,
          innings: inningsByMatch[m.id] ?? const [],
          currentUserId: user.id.value),
  ];
  final sentRows = [for (final r in outbound) _sentFor(r, teamsById)];

  return MyMatchesView(
    confirmed: confirmedRows,
    past: pastRows.take(_pastWindow).toList(),
    totalPastCount: pastRows.length,
    // Inbound "needs your reply" count is out of scope (handled in
    // Notifications); keep 0 so the inbound amber banner stays dormant.
    pendingRequestsCount: 0,
    sent: sentRows,
  );
}

const _pastWindow = 5;

int _byScheduledThenCreated(Match a, Match b) {
  final aT = a.scheduledStartTime ?? a.createdAt;
  final bT = b.scheduledStartTime ?? b.createdAt;
  return aT.compareTo(bT);
}

MyMatchConfirmed _confirmedFor(
  Match m,
  Map<String, Team> teamsById, {
  required String currentUserId,
}) {
  final home = teamsById[m.teamAId.value];
  final away = teamsById[m.teamBId.value];
  final start = m.scheduledStartTime;
  final isToday = start != null && _isSameDay(start, DateTime.now());

  final userTeamIds = {
    if (home?.isManagedBy(currentUserId) ?? false) m.teamAId.value,
    if (away?.isManagedBy(currentUserId) ?? false) m.teamBId.value,
  };
  final role = roleOnMatch(m, currentUserId, userTeamIds: userTeamIds);
  final roleLine = roleLineFor(role, m, isToday: isToday);

  // Toss-time detection — design's Case 03b. The card flips to "tap to
  // start" when the captain is approximately AT match time, not just
  // because a row was created with a default start_phase. Triggers when:
  //   (a) Captain has actively opened Match Start (status = toss), OR
  //   (b) We're within 30 min before scheduled start and up to 6h after
  //       (covering "I'm at the ground but late") on a still-pre-live row.
  // Excludes future-scheduled matches that just happen to have start_phase
  // defaulting to 'toss' on the row.
  final now = DateTime.now();
  final timeBracket = start != null &&
      now.isAfter(start.subtract(const Duration(minutes: 30))) &&
      now.isBefore(start.add(const Duration(hours: 6)));
  final isCaptain = role == MatchRoleKind.captain;
  final tossInProgress = m.status == MatchStatus.toss && isCaptain;
  final tossReady = tossInProgress ||
      (isCaptain &&
          (m.status == MatchStatus.scheduled ||
              m.status == MatchStatus.rescheduled) &&
          timeBracket);

  final when = tossReady
      ? 'Toss · ${_hhmm(start ?? DateTime.now())}'
      : _formatWhen(start, m.createdAt);
  final role0 = tossReady ? 'Captain · ready when you are' : roleLine.label;
  final countdown =
      tossReady ? 'Now' : _countdown(start, status: m.status);
  final urgent = tossReady || roleLine.urgent || _isUrgent(start, status: m.status);
  final helper = tossReady
      ? 'Both captains here. Tap to flip the coin together.'
      : null;

  return MyMatchConfirmed(
    id: m.id.value,
    tag: 'Friendly',
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
  );
}

MyMatchPast _pastFor(
  Match m,
  Map<String, Team> teamsById, {
  required List<InningsSummary> innings,
  required String currentUserId,
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
  final onHome = (home?.isManagedBy(currentUserId) ?? false) ||
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
    result: m.status == MatchStatus.completed
        ? (myWon ? 'WON' : 'LOST')
        : m.status == MatchStatus.walkover
            ? 'WALKOVER'
            : 'ABANDONED',
    mine: '',
  );
}

MyMatchRequest _sentFor(MatchRequest r, Map<String, Team> teamsById) {
  final isOpen = r.toTeamId == null;
  final opp = isOpen ? null : teamsById[r.toTeamId!.value];
  return MyMatchRequest(
    requestId: r.id.value,
    isOpen: isOpen,
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

String _short(Team? t, {required String fallback}) {
  if (t == null) return fallback;
  final mono = t.logoMonogram;
  if (mono != null && mono.isNotEmpty) return mono.toUpperCase();
  // Derive from the team's name: first letters of up to three words.
  final words = t.name.split(RegExp(r'\s+'));
  final letters = words
      .where((w) => w.isNotEmpty)
      .take(3)
      .map((w) => w[0])
      .join();
  return letters.isEmpty ? fallback : letters.toUpperCase();
}

Color _color(String? hex, {required Color fallback}) {
  if (hex == null || hex.isEmpty) return fallback;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(0xFF000000 | n);
  } else if (cleaned.length == 8) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(n);
  }
  return fallback;
}

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
