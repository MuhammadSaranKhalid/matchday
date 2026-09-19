import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_request.dart';
import '../state/challenges_view.dart';
import 'matches_providers.dart';

part 'challenges_providers.g.dart';

/// Builds the Challenges queue — `Challenges.dc.html`.
///
/// Sorted nearest-to-expiry first on BOTH tabs. That ordering is the design's
/// primary urgency device: "the list is sorted by time-to-die, so the top row
/// is always the one about to go — position carries the urgency for free, and
/// no row needs to shout."
@riverpod
Future<ChallengesView> challengesView(Ref ref) async {
  // Memberships are a one-shot scoped read; no permanent team stream is kept.
  final memberships =
      await ref.watch(currentUserTeamMembershipsProvider.future);
  final teams = [for (final membership in memberships) membership.team];
  if (teams.isEmpty) return const ChallengesView.empty();

  final result = await ref.watch(matchesRepositoryProvider).listMyMatchChallenges();
  final all = result.fold<List<MatchRequest>>((_) => const [], (l) => l);

  final myIds = {for (final t in teams) t.id.value};
  bool live(MatchRequest r) =>
      r.status == MatchRequestStatus.pending ||
      r.status == MatchRequestStatus.countered;

  // Targeted challenges only. Open pool posts are a different object (one
  // decision over N applicants) and live on the Pool surface — see the note on
  // the screen about the designer's 1b recommendation.
  final mine = all
      .where((r) => r.toTeamId != null && live(r))
      .where((r) =>
          myIds.contains(r.fromTeamId.value) ||
          myIds.contains(r.toTeamId!.value))
      .toList();
  if (mine.isEmpty) return const ChallengesView.empty();

  final teamsById = <String, Team>{for (final t in teams) t.id.value: t};
  final needed = <String>{
    for (final r in mine) ...[
      if (!teamsById.containsKey(r.fromTeamId.value)) r.fromTeamId.value,
      if (!teamsById.containsKey(r.toTeamId!.value)) r.toTeamId!.value,
    ],
  };
  for (final id in needed) {
    final t = await ref.watch(teamProvider(id).future);
    if (t != null) teamsById[id] = t;
  }

  final needsYou = <ChallengeRow>[];
  final waiting = <ChallengeRow>[];

  for (final r in mine) {
    final iSent = myIds.contains(r.fromTeamId.value);

    // Obligation, not provenance. A challenge I sent that has been COUNTERED is
    // back on my desk, so it belongs in "Needs you" even though I sent it —
    // this is exactly the case Received/Sent would file wrongly.
    final bool mine0;
    if (r.status == MatchRequestStatus.countered) {
      // Whoever did NOT counter owes the reply.
      mine0 = iSent;
    } else {
      mine0 = !iSent;
    }

    final opponentId = iSent ? r.toTeamId!.value : r.fromTeamId.value;
    final opponent = teamsById[opponentId];
    final row = _rowFor(r, opponent, isInbound: mine0, canWithdraw: iSent);
    (mine0 ? needsYou : waiting).add(row);
  }

  int byExpiry(ChallengeRow a, ChallengeRow b) {
    final x = a.expiresAt;
    final y = b.expiresAt;
    if (x == null && y == null) return a.createdAt.compareTo(b.createdAt);
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }

  needsYou.sort(byExpiry);
  waiting.sort(byExpiry);
  return ChallengesView(needsYou: needsYou, waitingOnThem: waiting);
}

ChallengeRow _rowFor(
  MatchRequest r,
  Team? opponent, {
  required bool isInbound,
  required bool canWithdraw,
}) {
  final countered = r.status == MatchRequestStatus.countered;

  // The governing clock: countering restarts a tighter 24h budget, so once
  // countered that is the deadline that matters.
  final expires = countered
      ? (r.counterExpiresAt ?? r.proposalExpiresAt)
      : r.proposalExpiresAt;

  final liveStart = countered ? (r.counteredStartTime ?? r.proposedStartTime)
                              : r.proposedStartTime;
  final liveVenue = countered ? (r.counteredVenue ?? r.proposedVenue)
                              : r.proposedVenue;
  final liveFormat = countered ? (r.counteredFormat ?? r.proposedFormat)
                               : r.proposedFormat;

  return ChallengeRow(
    requestId: r.id.value,
    isInbound: isInbound,
    canWithdraw: canWithdraw,
    opponentName: opponent?.name ?? 'A team',
    opponentShort: _short(opponent),
    opponentColor: _color(opponent?.primaryColor),
    status: r.status,
    createdAt: r.createdAt,
    expiresAt: expires,
    whenLabel: _when(liveStart),
    metaLabel: _meta(liveVenue, liveFormat, r.playersPerSide),
    message: r.message,
    // On a countered row the ledger shows what was superseded against what is
    // now on the table. Only the fields that actually changed are worth
    // repeating, so both sides are rendered as one terms line.
    supersededLabel: countered
        ? _terms(r.proposedStartTime, r.proposedVenue)
        : null,
    counterLabel: countered
        ? _terms(r.counteredStartTime ?? r.proposedStartTime,
            r.counteredVenue ?? r.proposedVenue)
        : null,
  );
}

String _short(Team? t) {
  final n = (t?.name ?? '').trim();
  if (n.isEmpty) return '??';
  final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

Color _color(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF7A746A);
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFF7A746A);
}

String _when(DateTime? d) {
  if (d == null) return 'Date to be agreed';
  final l = d.toLocal();
  return '${DateFormat('EEE d MMM').format(l)} · ${DateFormat('h:mm a').format(l)}';
}

String _terms(DateTime? d, String? venue) {
  final when = d == null
      ? null
      : DateFormat('EEE d MMM · h:mm a').format(d.toLocal());
  return [when, venue].where((s) => (s ?? '').isNotEmpty).join(' · ');
}

String _meta(String? venue, MatchFormat? f, int playersPerSide) {
  final overs = f == null
      ? null
      : (f.oversPerInnings == 0 ? 'Unlimited' : '${f.oversPerInnings} ov');
  final side = '$playersPerSide-a-side';
  return [venue, overs, side]
      .where((s) => (s ?? '').isNotEmpty)
      .join(' · ');
}
