import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/entities/match_wicket.dart';
import '../../domain/scoring/scorecard.dart';
import '../state/completed_match_view.dart';
import 'matches_providers.dart';
import 'team_display.dart';

part 'completed_match_providers.g.dart';

/// Everything the completed-match screen draws, assembled from the ledger.
///
/// One provider rather than one per tab: the four tabs are four views of the
/// same two innings, and fetching per tab would re-read the whole delivery
/// list every time the user switched. The read is O(deliveries) once.
@riverpod
Future<CompletedMatchView> completedMatch(Ref ref, String matchId) async {
  final repo = ref.watch(matchesRepositoryProvider);
  final id = MatchId(matchId);

  final match = (await repo.getMatch(
    id,
  )).fold((f) => throw FailureWrapper(f), (m) => m);
  if (match == null) {
    throw const FailureWrapper(NotFoundFailure('That match no longer exists.'));
  }

  // The innings rows and the lineup are independent of each other, and the
  // deliveries depend on neither. Start both before awaiting either — on a
  // ground with one bar of signal, sequential round-trips are the difference
  // between a screen that opens and one that is abandoned.
  final inningsFuture = repo.listInnings(id);
  final squadFuture = repo.listMatchPlayers(id);

  final innings = (await inningsFuture).fold<List<MatchInnings>>(
    (f) => throw FailureWrapper(f),
    (v) => v,
  );
  final squad = (await squadFuture).fold<List<MatchPlayer>>(
    (f) => throw FailureWrapper(f),
    (v) => v,
  );

  // Deliveries + wickets per innings, all in flight at once.
  final ledgers = await Future.wait<InningsCard>(
    innings.map((inn) async {
      final ballsFuture = repo.listBalls(id, inn.inningsNumber);
      final wicketsFuture = repo.getWickets(inn.inningsId);
      final balls = (await ballsFuture).fold<List<Ball>>(
        (_) => const [],
        (v) => v,
      );
      final wickets = (await wicketsFuture).fold<List<MatchWicket>>(
        (_) => const [],
        (v) => v,
      );
      return buildInningsCard(
        inningsNumber: inn.inningsNumber,
        battingTeamSide: inn.battingSideLetter,
        balls: balls,
        wickets: wickets,
        squad: squad,
        ballsPerOver: match.format.ballsPerOver,
      );
    }),
  );

  // Team identities.
  final teams = <String, Team>{};
  await Future.wait(
    {match.teamAId.value, match.teamBId.value}.map((tid) async {
      final t = (await ref
          .read(teamsRepositoryProvider)
          .getTeam(TeamId(tid))).fold((_) => null, (t) => t);
      if (t != null) teams[tid] = t;
    }),
  );

  final memberships = await ref.watch(
    currentUserTeamMembershipsProvider.future,
  );
  final myTeamIds = memberships.map((m) => m.team.id.value).toSet();

  return _assemble(
    match: match,
    cards: ledgers,
    teams: teams,
    myTeamIds: myTeamIds,
    squad: squad,
  );
}

CompletedMatchView _assemble({
  required Match match,
  required List<InningsCard> cards,
  required Map<String, Team> teams,
  required Set<String> myTeamIds,
  required List<MatchPlayer> squad,
}) {
  final aId = match.teamAId.value;
  final bId = match.teamBId.value;
  final a = teams[aId];
  final b = teams[bId];
  final aName = a?.name ?? 'Team A';
  final bName = b?.name ?? 'Team B';

  // Totals per side, from the ledger and nowhere else.
  InningsCard? cardFor(String side) {
    final matching = cards.where((c) => c.battingTeamSide == side);
    return matching.isEmpty ? null : matching.first;
  }

  final aCard = cardFor('a');
  final bCard = cardFor('b');

  final tone = switch (match.status) {
    MatchStatus.tied => ResultTone.tied,
    MatchStatus.completed => ResultTone.won,
    _ => ResultTone.none,
  };

  // Who won. The result sentence is authored server-side; deciding the winner
  // by comparing our own totals would let a provisional local sum contradict
  // it, so the sentence is matched against the team names instead.
  final sentence =
      match.resultDescription?.trim().isNotEmpty == true
          ? match.resultDescription!.trim()
          : switch (match.status) {
            MatchStatus.tied => 'Match tied · scores level',
            MatchStatus.noResult => 'No result',
            MatchStatus.abandoned => 'Abandoned',
            MatchStatus.walkover => 'Awarded by walkover',
            _ => 'Match complete',
          };
  bool won(String name) =>
      tone == ResultTone.won &&
      name.isNotEmpty &&
      sentence.toLowerCase().contains(name.split(' ').last.toLowerCase());

  CompletedSide side(
    String tid,
    String letter,
    String name,
    Team? team,
    InningsCard? card,
    String fallbackShort,
  ) => CompletedSide(
    teamId: tid,
    sideLetter: letter,
    name: name,
    short: teamShort(team, fallback: fallbackShort),
    color: teamColor(team?.primaryColor, fallback: const Color(0xFF7A746A)),
    isYou: myTeamIds.contains(tid),
    won: won(name),
    batted: card != null && card.legalBalls > 0,
    runs: card?.totalRuns,
    wickets: card?.wickets,
    oversLabel: card?.oversLabel,
  );

  // The result card prints the sides in the order they batted, so a chase
  // reads top-to-bottom the way it happened.
  final firstIsA = cards.isEmpty || cards.first.battingTeamSide == 'a';
  final sideA = side(aId, 'a', aName, a, aCard, 'A');
  final sideB = side(bId, 'b', bName, b, bCard, 'B');
  final sides = firstIsA ? [sideA, sideB] : [sideB, sideA];

  final df = DateFormat('EEE d MMM');
  final when = match.scheduledStartTime;
  final meta = [
    if (when != null) df.format(when.toLocal()),
    if (match.venue != null) match.venue!.ground,
    match.matchType == MatchType.tournament ? 'Tournament' : 'Friendly',
    _formatLabel(match.format),
  ].join(' · ');

  // ── The record page (walkover / abandoned) ────────────────────────────────
  final played = cards.any((c) => c.legalBalls > 0);
  String? headline;
  String? absence;
  if (!played) {
    headline = 'No match was played.';
    absence = switch (match.status) {
      MatchStatus.walkover =>
        'The fixture was awarded without a ball being bowled. No toss was '
            'made and no innings began.',
      _ =>
        'The fixture was called off before a ball was bowled. No toss was '
            'made and no innings began.',
    };
  }

  final tossTeam = match.tossWonBy?.value;
  final tossName = tossTeam == null ? null : (tossTeam == aId ? aName : bName);
  final tossLine =
      (tossName == null || match.tossDecision == null)
          ? null
          : '$tossName, chose to ${match.tossDecision == TossDecision.bat ? 'bat' : 'bowl'}';

  final aCount = squad.where((p) => p.teamSide == MatchTeamSide.a).length;
  final bCount = squad.where((p) => p.teamSide == MatchTeamSide.b).length;

  return CompletedMatchView(
    title: '${_shortName(aName)} vs ${_shortName(bName)}',
    sides: sides,
    tone: tone,
    sentence: sentence,
    metaLine: meta,
    innings: cards.where((c) => c.legalBalls > 0).toList(),
    headline: headline,
    absenceNote: absence,
    tossLine: tossLine,
    squadsLine:
        (aCount + bCount) == 0 ? null : '$aCount v $bCount · named on the card',
    recordRows: [
      if (when != null)
        (
          label: 'Scheduled',
          value:
              '${df.format(when.toLocal())} · '
              '${DateFormat('h:mm a').format(when.toLocal())}',
        ),
      if (match.venue != null) (label: 'Ground', value: match.venue!.ground),
      (
        label: 'Format',
        value:
            '${_formatLabel(match.format)} · '
            '${match.format.playersPerTeam}-a-side',
      ),
    ],
  );
}

/// "Lahore Lions" → "Lions". The header has room for two names and a pair of
/// 36px controls; the full names overflow at anything past a short club name.
String _shortName(String full) {
  final words = full.trim().split(RegExp(r'\s+'));
  return words.length > 1 ? words.last : full;
}

/// "T20" / "16 ov" — the shape of the contest, not the enum name. A format is
/// only worth naming when it is one people say out loud.
String _formatLabel(MatchFormat f) {
  final overs = f.oversPerInnings;
  if (overs == 0) return 'Unlimited';
  if (overs == 20 && f.inningsPerSide == 1) return 'T20';
  if (overs == 50 && f.inningsPerSide == 1) return 'ODI';
  return '$overs ov';
}
