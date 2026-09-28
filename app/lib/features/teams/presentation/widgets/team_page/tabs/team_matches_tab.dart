import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/theme/circk_theme.dart';
import '../../../../../matches/domain/entities/match.dart';
import '../../../../domain/entities/team.dart';
import '../team_page_visuals.dart';

class TeamMatchesTab extends StatelessWidget {
  const TeamMatchesTab({
    super.key,
    required this.team,
    required this.matches,
    required this.opponentNames,
    this.onlyRecent = false,
  });

  final Team team;
  final List<Match> matches;
  final Map<String, String> opponentNames;
  final bool onlyRecent;

  @override
  Widget build(BuildContext context) {
    final upcoming = matches
        .where((m) => m.status.isUpcoming || m.status.isLive)
        .toList(growable: false);
    final recent = matches.where((m) => m.status.isPast).toList(growable: false);

    if ((onlyRecent ? recent : matches).isEmpty) {
      return TeamPageEmptyTile(
        icon: onlyRecent ? Icons.history_rounded : Icons.calendar_month,
        title: onlyRecent ? 'No recent matches' : 'No matches yet',
        body: onlyRecent
            ? 'Completed matches will appear here.'
            : 'Schedule a friendly or register for a tournament.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 14),
      children: [
        if (!onlyRecent && upcoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text('UPCOMING · ${upcoming.length}', style: teamPageMono()),
          ),
          for (final match in upcoming)
            _UpcomingRow(
              match: match,
              opponent: _opponent(match),
            ),
        ],
        if (recent.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16, onlyRecent ? 0 : 18, 16, 6),
            child: Text('RECENT · ${recent.length}', style: teamPageMono()),
          ),
          for (final match in recent)
            _RecentRow(
              match: match,
              team: team,
              opponent: _opponent(match),
            ),
        ],
      ],
    );
  }

  String _opponent(Match match) {
    final id = match.teamAId == team.id ? match.teamBId.value : match.teamAId.value;
    return opponentNames[id] ?? 'Opponent';
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.match, required this.opponent});
  final Match match;
  final String opponent;

  @override
  Widget build(BuildContext context) {
    final scheduled = match.scheduledStartTime?.toLocal();
    final day = scheduled == null ? 'Soon' : DateFormat('d MMM').format(scheduled);
    final time = scheduled == null ? '—' : DateFormat('HH:mm').format(scheduled);
    final venue = match.venue?.ground.trim() ?? '';
    final label = (match.round?.trim().isNotEmpty ?? false)
        ? match.round!.trim().toUpperCase()
        : match.matchType.label;

    return InkWell(
      onTap: () => context.push('/matches/${match.id.value}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  Text(day.toUpperCase(), style: teamPageMono(fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: CkType.display(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'vs $opponent',
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.01,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [label, if (venue.isNotEmpty) venue].join(' · '),
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            if (match.status.isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CkColors.red,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TeamPageLivePulse(),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: teamPageMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.match,
    required this.team,
    required this.opponent,
  });
  final Match match;
  final Team team;
  final String opponent;

  @override
  Widget build(BuildContext context) {
    final result = _resultFor(match, team);
    final date = DateFormat('d MMM').format(
      (match.actualStartTime ?? match.scheduledStartTime ?? match.createdAt)
          .toLocal(),
    );
    final (letter, bg, fg) = switch (result) {
      _DisplayResult.win => ('W', CkColors.green, Colors.white),
      _DisplayResult.loss => ('L', CkColors.red, Colors.white),
      _DisplayResult.tie => ('T', CkColors.cream, CkColors.ink2),
      _DisplayResult.neutral => ('—', CkColors.paper2, CkColors.ink2),
    };

    return InkWell(
      onTap: () => context.push('/matches/${match.id.value}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: CkType.display(fontSize: 12, fontWeight: FontWeight.w800, color: fg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          team.name,
                          overflow: TextOverflow.ellipsis,
                          style: teamPageMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CkColors.ink,
                          ).copyWith(letterSpacing: 0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('vs', style: CkType.body(fontSize: 11, color: CkColors.muted)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          opponent,
                          overflow: TextOverflow.ellipsis,
                          style: teamPageMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CkColors.ink2,
                          ).copyWith(letterSpacing: 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$date · ${_summary(match)}',
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DisplayResult _resultFor(Match match, Team team) {
    if (match.status == MatchStatus.tied) return _DisplayResult.tie;
    if (match.status == MatchStatus.noResult ||
        match.status == MatchStatus.abandoned) {
      return _DisplayResult.neutral;
    }
    final text = match.resultDescription?.toLowerCase() ?? '';
    if (!text.contains('won')) return _DisplayResult.neutral;
    return text.contains(team.name.toLowerCase())
        ? _DisplayResult.win
        : _DisplayResult.loss;
  }

  String _summary(Match match) {
    final description = match.resultDescription?.trim();
    if (description != null && description.isNotEmpty) return description;
    return switch (match.status) {
      MatchStatus.tied => 'Match tied',
      MatchStatus.noResult => 'No result',
      MatchStatus.abandoned => 'Match abandoned',
      MatchStatus.walkover => 'Walkover',
      _ => 'Match completed',
    };
  }
}

enum _DisplayResult { win, loss, tie, neutral }
