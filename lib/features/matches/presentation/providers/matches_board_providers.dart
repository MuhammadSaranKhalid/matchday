import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../../../follows/presentation/providers/follows_providers.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../../tournaments/domain/entities/tournament.dart';
import '../../../tournaments/presentation/providers/tournaments_providers.dart';
import '../../domain/entities/innings_summary.dart';
import '../../domain/entities/match.dart';
import 'matches_providers.dart';

part 'matches_board_providers.g.dart';

/// The board's four status tabs — `Matches.dc.html` artboard 02.
enum MatchesBoardTab {
  live('Live'),
  forYou('For you'),
  upcoming('Upcoming'),
  finished('Finished');

  const MatchesBoardTab(this.label);
  final String label;
}

/// Statuses that count as "on right now".
///
/// All four, including `toss`: a match at the toss is on, and hiding it makes
/// the tab's count lie.
const kLiveStatuses = {
  MatchStatus.toss,
  MatchStatus.live,
  MatchStatus.inningsBreak,
  MatchStatus.superOver,
};

/// `completed` and `abandoned` both belong here — abandoned is over.
const kFinishedStatuses = {MatchStatus.completed, MatchStatus.abandoned};

@riverpod
class MatchesBoardTabController extends _$MatchesBoardTabController {
  @override
  MatchesBoardTab build() => MatchesBoardTab.live;

  void select(MatchesBoardTab tab) => state = tab;
}

/// One match on the board, with everything a row needs already resolved.
class BoardMatch {
  const BoardMatch({
    required this.match,
    this.teamA,
    this.teamB,
    this.innings = const [],
    this.viewerTeamId,
  });

  final Match match;
  final Team? teamA;
  final Team? teamB;

  /// Innings totals in order. Empty until the first ball is scored.
  final List<InningsSummary> innings;

  /// The viewer's own team in this match, if either side is theirs. Drives the
  /// soft mono "YOU" beside the team name — the lightest possible marker, so
  /// the tab does not drift back into being My Matches.
  final TeamId? viewerTeamId;

  bool get isLive => kLiveStatuses.contains(match.status);

  /// The side currently batting, marked with a small ink dot rather than a
  /// colour. Null when no ball has been bowled.
  TeamId? get battingTeamId =>
      innings.isEmpty ? null : innings.last.battingTeamId;

  InningsSummary? inningsFor(TeamId? id) {
    if (id == null) return null;
    for (final i in innings) {
      if (i.battingTeamId == id) return i;
    }
    return null;
  }
}

/// A competition's fixtures, or the trailing Friendlies group.
class BoardGroup {
  const BoardGroup({
    required this.matches,
    this.tournament,
  });

  final List<BoardMatch> matches;

  /// Null = the Friendlies group, which sits last because organised cricket
  /// leads.
  final Tournament? tournament;

  bool get isFriendlies => tournament == null;
  int get liveCount => matches.where((m) => m.isLive).length;
}

class MatchesBoardView {
  const MatchesBoardView({
    required this.groups,
    required this.liveCount,
  });

  final List<BoardGroup> groups;

  /// Drives the Live tab's figure. Counts every live match on the board, not
  /// just the selected tab's.
  final int liveCount;

  bool get isEmpty => groups.isEmpty;
}

/// The whole board for [tab], grouped by competition.
@riverpod
Future<MatchesBoardView> matchesBoard(Ref ref, MatchesBoardTab tab) async {
  final repo = ref.watch(matchesRepositoryProvider);
  final now = DateTime.now();

  Future<List<Match>> read({
    required Set<MatchStatus> statuses,
    DateTime? from,
    DateTime? to,
    bool newestFirst = false,
  }) async {
    final result = await repo.listPublicMatches(
      statuses: statuses,
      from: from,
      to: to,
      newestFirst: newestFirst,
    );
    return result.fold((f) => throw Exception(f.message), (list) => list);
  }

  // The live set is always read: the tab's count is of the whole board, so it
  // must not depend on which tab happens to be selected.
  final live = await read(statuses: kLiveStatuses);

  final matches = switch (tab) {
    MatchesBoardTab.live => live,
    MatchesBoardTab.upcoming => await read(
        statuses: const {MatchStatus.scheduled},
        from: now,
        to: now.add(const Duration(days: 7)),
      ),
    MatchesBoardTab.finished => await read(
        statuses: kFinishedStatuses,
        from: now.subtract(const Duration(days: 7)),
        to: now,
        newestFirst: true,
      ),
    // For you spans every status — it is a relevance cut, not a status one.
    MatchesBoardTab.forYou => [
        ...live,
        ...await read(
          statuses: const {MatchStatus.scheduled},
          from: now,
          to: now.add(const Duration(days: 7)),
        ),
        ...await read(
          statuses: kFinishedStatuses,
          from: now.subtract(const Duration(days: 7)),
          to: now,
          newestFirst: true,
        ),
      ],
  };

  final shown = tab == MatchesBoardTab.forYou
      ? await _narrowToForYou(ref, matches)
      : matches;

  return _group(ref, shown, liveCount: live.length);
}

/// "For you" = a team you follow is playing, **or** the match belongs to a
/// tournament you are registered in or organising.
///
/// Two rules, both derived from something the viewer explicitly did. Location
/// is deliberately not a factor: a follow is a stated interest, a GPS radius
/// is a guess.
Future<List<Match>> _narrowToForYou(Ref ref, List<Match> matches) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  final myTeams = await ref.watch(myTeamsProvider.future);
  final followed = <String>{
    ...myTeams.map((t) => t.id.value),
    ...(await ref.watch(followedTeamIdsProvider.future)),
  };

  final myTournaments =
      (await ref.watch(myTournamentsProvider.future)).map((t) => t.id).toSet();

  return matches.where((m) {
    if (followed.contains(m.teamAId.value)) return true;
    if (followed.contains(m.teamBId.value)) return true;
    final tid = m.tournamentId;
    return tid != null && myTournaments.contains(tid);
  }).toList();
}

/// Resolve teams, innings and tournament for each match, then bucket by
/// competition with Friendlies last.
Future<MatchesBoardView> _group(
  Ref ref,
  List<Match> matches, {
  required int liveCount,
}) async {
  if (matches.isEmpty) {
    return MatchesBoardView(groups: const [], liveCount: liveCount);
  }

  final userId = ref.watch(currentUserIdProvider);
  final myTeams = await ref.watch(myTeamsProvider.future);
  final myTeamIds = userId == null
      ? <String>{}
      : myTeams.map((t) => t.id.value).toSet();

  // One round trip for every score on the board.
  final inningsByMatch = (await ref
          .watch(matchesRepositoryProvider)
          .listInningsForMatches(matches.map((m) => m.id)))
      .getOrElse((_) => const {});

  final board = <BoardMatch>[];
  for (final m in matches) {
    final teamA = await ref.watch(teamProvider(m.teamAId.value).future);
    final teamB = await ref.watch(teamProvider(m.teamBId.value).future);

    board.add(
      BoardMatch(
        match: m,
        teamA: teamA,
        teamB: teamB,
        innings: inningsByMatch[m.id] ?? const [],
        viewerTeamId: myTeamIds.contains(m.teamAId.value)
            ? m.teamAId
            : (myTeamIds.contains(m.teamBId.value) ? m.teamBId : null),
      ),
    );
  }

  final byTournament = <String, List<BoardMatch>>{};
  final friendlies = <BoardMatch>[];
  for (final b in board) {
    final tid = b.match.tournamentId;
    if (tid == null) {
      friendlies.add(b);
    } else {
      byTournament.putIfAbsent(tid, () => []).add(b);
    }
  }

  final groups = <BoardGroup>[];
  for (final entry in byTournament.entries) {
    // Fixtures are public even where the tournament's own detail read fails,
    // so a group survives without its header metadata rather than vanishing.
    Tournament? tournament;
    try {
      tournament =
          await ref.watch(tournamentDetailProvider(entry.key).future);
    } catch (_) {
      tournament = null;
    }
    groups.add(BoardGroup(tournament: tournament, matches: entry.value));
  }

  // Live competitions first, then by name, so the thing that is on rises.
  groups.sort((a, b) {
    final byLive = b.liveCount.compareTo(a.liveCount);
    if (byLive != 0) return byLive;
    return (a.tournament?.name ?? '~').compareTo(b.tournament?.name ?? '~');
  });

  if (friendlies.isNotEmpty) {
    groups.add(BoardGroup(matches: friendlies));
  }

  return MatchesBoardView(groups: groups, liveCount: liveCount);
}
