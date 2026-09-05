import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_leader.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament_organizer.dart';
import '../../domain/entities/tournament_registration.dart';
import '../providers/tournaments_providers.dart';
import 'ck_pulse_dot.dart';

/// Artboards 09, 10 and 11 — the Overview tab, which is three different
/// screens wearing one tab.
///
///  * **Registration (09)** is a decision surface. It is built around the
///    three things a manager actually decides on — is this organiser
///    trustworthy, is there room, and is it worth the fee — so the organiser
///    credibility row leads, the scarcity headline follows, and prizes sit
///    *above* rules because prizes are what you decide on and rules are
///    reference you scroll to. Money stays cream: a fee is not a warning.
///  * **Live (10)** spends red exactly three times — the LIVE pill, the live
///    score, the pulse dot. The chase line and run rate stay ink.
///  * **Completed (11)** is an archive page, so it is quiet: **zero red.**
class TournamentOverviewTab extends ConsumerWidget {
  const TournamentOverviewTab({super.key, required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (tournament.status) {
      TournamentStatus.completed =>
        _CompletedOverview(tournament: tournament),
      TournamentStatus.live => _LiveOverview(tournament: tournament),
      _ => _RegistrationOverview(tournament: tournament),
    };
  }
}

// ─── 09 · Registration ────────────────────────────────────────────────────────

class _RegistrationOverview extends ConsumerWidget {
  const _RegistrationOverview({required this.tournament});

  final Tournament tournament;

  static final _money = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizer = ref.watch(tournamentOrganizerProvider(tournament.id)).value;
    final regs =
        ref.watch(tournamentRegistrationsProvider(tournament.id)).value ??
            const <TournamentRegistration>[];
    final approved = regs.where((r) => r.isApproved).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (organizer != null) _OrganizerRow(organizer: organizer),
        _WhenAndWhere(tournament: tournament),
        _Scarcity(tournament: tournament, approved: approved),
        if (tournament.registrationDeadline case final deadline?)
          _DeadlineChip(deadline: deadline),
        if ((tournament.entryFee ?? 0) > 0) _FeeBlock(tournament: tournament),
        _Prizes(tournament: tournament),
        _Rules(tournament: tournament),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () =>
                  context.push('/tournaments/${tournament.id}/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CkColors.ink,
                foregroundColor: CkColors.paper,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                (tournament.entryFee ?? 0) > 0
                    ? 'Register Your Team · PKR '
                        '${_money.format(tournament.entryFee)}'
                    : 'Register Your Team',
                style: CkType.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CkColors.paper,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The credibility row. First thing on the screen, because it is the first
/// question a manager asks.
class _OrganizerRow extends StatelessWidget {
  const _OrganizerRow({required this.organizer});

  final TournamentOrganizer organizer;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: organizer.username == null
          ? null
          : () => context.push('/u/${organizer.username}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.line),
              ),
              alignment: Alignment.center,
              child: organizer.avatarUrl == null || organizer.avatarUrl!.isEmpty
                  ? Text(
                      organizer.monogram,
                      style: CkType.display(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Image.network(
                      organizer.avatarUrl!,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        organizer.monogram,
                        style: CkType.display(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    organizer.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    organizer.credibilityLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            if (organizer.username != null)
              const Icon(Icons.chevron_right, size: 18, color: CkColors.soft),
          ],
        ),
      ),
    );
  }
}

class _WhenAndWhere extends StatelessWidget {
  const _WhenAndWhere({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final start = tournament.startDate;
    final end = tournament.endDate;
    final fmt = DateFormat('d MMM');
    final dates = start == null
        ? null
        : end == null || DateUtils.isSameDay(start, end)
            ? fmt.format(start)
            : '${fmt.format(start)} – ${fmt.format(end)}';
    final venue = tournament.venues.isEmpty
        ? tournament.city
        : tournament.venues.first.name;

    final line = [if (dates != null) dates, if (venue != null) venue]
        .join(' · ');
    if (line.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, size: 15, color: CkColors.muted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: CkColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "2 spots left · 6 / 8 teams", with the crests of who is already in — the
/// second question a manager asks, answered with evidence rather than a count.
class _Scarcity extends StatelessWidget {
  const _Scarcity({required this.tournament, required this.approved});

  final Tournament tournament;
  final List<TournamentRegistration> approved;

  @override
  Widget build(BuildContext context) {
    final max = tournament.maxTeams;
    final count = approved.isEmpty ? tournament.approvedTeamsCount : approved.length;
    final left = max == null ? null : (max - count).clamp(0, max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  left == null
                      ? '$count team${count == 1 ? '' : 's'} in'
                      : left == 0
                          ? 'Draw is full'
                          : '$left spot${left == 1 ? '' : 's'} left',
                  style: CkType.display(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.01,
                  ),
                ),
              ),
              if (max != null)
                Text(
                  '$count / $max teams',
                  style: CkType.mono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CkColors.muted,
                  ),
                ),
            ],
          ),
          if (approved.isNotEmpty) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                for (final reg in approved.take(4)) ...[
                  _MiniCrest(registration: reg),
                  const SizedBox(width: 5),
                ],
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _alreadyIn(approved),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _alreadyIn(List<TournamentRegistration> approved) {
    final names =
        approved.take(2).map((r) => r.teamName ?? 'A team').toList();
    final rest = approved.length - names.length;
    return '${names.join(', ')}${rest > 0 ? ' +$rest' : ''} already in';
  }
}

class _MiniCrest extends StatelessWidget {
  const _MiniCrest({required this.registration});

  final TournamentRegistration registration;

  @override
  Widget build(BuildContext context) {
    final name = registration.teamName ?? '';
    final explicit = registration.teamMonogram?.trim();
    final words = name.trim().split(RegExp(r'\s+'));
    final mono = explicit != null && explicit.isNotEmpty
        ? explicit.toUpperCase()
        : words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty
            ? '${words[0][0]}${words[1][0]}'.toUpperCase()
            : name.trim().padRight(2).substring(0, 2).trim().toUpperCase();

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        shape: BoxShape.circle,
        border: Border.all(color: CkColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        mono,
        style: CkType.display(fontSize: 9.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// The deadline is cream on amber-dark, never red — a closing date is a fact,
/// not an alarm.
class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final days = deadline.difference(DateTime.now()).inDays;
    final when = days < 0
        ? 'Registration closed'
        : days == 0
            ? 'closes today'
            : 'in $days day${days == 1 ? '' : 's'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CkColors.cream,
          borderRadius: BorderRadius.circular(CkRadii.sm),
          border: Border.all(color: CkColors.creamBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 15,
              color: CkColors.amberDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                days < 0
                    ? when
                    : 'Closes ${DateFormat('d MMM').format(deadline)} · $when',
                style: CkType.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.04,
                  color: CkColors.amberDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeBlock extends StatelessWidget {
  const _FeeBlock({required this.tournament});

  final Tournament tournament;

  static final _money = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(CkRadii.md),
          border: Border.all(color: CkColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PKR ${_money.format(tournament.entryFee)}',
              style: CkType.mono(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              'Paid offline in cash. You stay Pending Payment until the '
              'organiser confirms.',
              style: CkType.body(
                fontSize: 12,
                height: 1.5,
                color: CkColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prizes sit **above** Rules: prizes are what a manager decides on, rules are
/// reference they scroll to. The winner's figure leads.
class _Prizes extends StatelessWidget {
  const _Prizes({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final details = tournament.prizeDetails?.trim();
    if (details == null || details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PRIZES',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.creamBorder),
            ),
            child: Text(
              details,
              style: CkType.body(
                fontSize: 13,
                height: 1.55,
                color: CkColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final minSquad = (tournament.rules['min_squad'] as num?)?.toInt();
    final maxSquad = (tournament.rules['max_squad'] as num?)?.toInt();
    final squad = minSquad == null && maxSquad == null
        ? null
        : minSquad == null
            ? '$maxSquad'
            : maxSquad == null
                ? '$minSquad+'
                : '$minSquad–$maxSquad';
    final perBowler =
        (tournament.format['max_overs_per_bowler'] as num?)?.toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'RULES',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: CkColors.paper,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Row(
              children: [
                _Rule(label: 'Overs', value: '${tournament.maxOvers}', flex: 1),
                if (perBowler != null)
                  _Rule(label: 'Per bowler', value: '$perBowler', flex: 1),
                _Rule(
                  label: 'Ball',
                  value: tournament.ballType,
                  flex: 14,
                  mono: false,
                ),
                if (squad != null) _Rule(label: 'Squad', value: squad, flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({
    required this.label,
    required this.value,
    required this.flex,
    this.mono = true,
  });

  final String label;
  final String value;
  final int flex;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.body(fontSize: 10, color: CkColors.muted),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: mono
                ? CkType.mono(fontSize: 13, fontWeight: FontWeight.w700)
                : CkType.body(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── 10 · Live ────────────────────────────────────────────────────────────────

class _LiveOverview extends ConsumerWidget {
  const _LiveOverview({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(tournamentLiveBoardProvider(tournament.id));
    final boards = ref.watch(tournamentLeaderboardsProvider(tournament.id));

    return switch (board) {
      AsyncLoading() =>
        const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
          ),
        ),
      AsyncData(value: final fixtures) => _liveBody(
          context,
          ref,
          fixtures,
          boards.value,
        ),
    };
  }

  Widget _liveBody(
    BuildContext context,
    WidgetRef ref,
    List<TournamentLiveMatch> fixtures,
    TournamentLeaderboards? boards,
  ) {
    final live = fixtures.where((m) => m.status == 'live').toList();
    final today = fixtures
        .where((m) =>
            DateUtils.isSameDay(m.scheduledStartTime, DateTime.now()) &&
            m.status != 'live')
        .toList();
    final grounds = fixtures
        .where((m) => DateUtils.isSameDay(m.scheduledStartTime, DateTime.now()))
        .map((m) => m.venue)
        .toSet()
        .length;

    return RefreshIndicator(
      color: CkColors.ink,
      onRefresh: () async =>
          ref.invalidate(tournamentLiveBoardProvider(tournament.id)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          for (final m in live) _LiveMatchCard(match: m),
          if (today.isNotEmpty) ...[
            _Eyebrow(
              label: 'Today’s matchday · $grounds '
                  'ground${grounds == 1 ? '' : 's'}',
            ),
            for (final m in today) _TodayRow(match: m),
          ],
          if (boards != null && !boards.isEmpty) ...[
            const _Eyebrow(label: 'Leading the cup'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (boards.orangeCap case final b?)
                    Expanded(
                      child: _LeaderCard(
                        label: 'Most runs',
                        leader: b,
                        rate: 'SR ${b.rateValue.toStringAsFixed(1)}',
                      ),
                    ),
                  if (boards.orangeCap != null && boards.purpleCap != null)
                    const SizedBox(width: 10),
                  if (boards.purpleCap case final b?)
                    Expanded(
                      child: _LeaderCard(
                        label: 'Most wickets',
                        leader: b,
                        rate: 'Econ ${b.rateValue.toStringAsFixed(1)}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The one card that spends red: the LIVE pill, the live score, the pulse dot.
/// The chase line and the run-rate cells stay ink.
class _LiveMatchCard extends StatelessWidget {
  const _LiveMatchCard({required this.match});

  final TournamentLiveMatch match;

  @override
  Widget build(BuildContext context) {
    final lines = [...match.inningsLines]
      ..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final latest = lines.isEmpty ? null : lines.last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(CkRadii.md),
          border: Border.all(color: CkColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: CkColors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LIVE',
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        if (match.round case final r?) r,
                        match.venue,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
              child: Column(
                children: [
                  _SideLine(
                    match: match,
                    teamId: match.teamAId,
                    latest: latest,
                  ),
                  const SizedBox(height: 6),
                  _SideLine(
                    match: match,
                    teamId: match.teamBId,
                    latest: latest,
                  ),
                ],
              ),
            ),
            if (match.resultDescription case final chase?
                when chase.isNotEmpty) ...[
              Container(height: 1, color: CkColors.hairline),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                child: Text(
                  chase,
                  style: CkType.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SideLine extends StatelessWidget {
  const _SideLine({
    required this.match,
    required this.teamId,
    required this.latest,
  });

  final TournamentLiveMatch match;
  final String? teamId;
  final LiveInningsLine? latest;

  @override
  Widget build(BuildContext context) {
    final line = match.lineFor(teamId);
    final striking = line != null && line.inningsNumber == latest?.inningsNumber;

    return Row(
      children: [
        Expanded(
          child: Text(
            match.displayNameFor(teamId),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 13.5,
              fontWeight: striking ? FontWeight.w700 : FontWeight.w600,
              color: striking || line == null ? CkColors.ink : CkColors.muted,
            ),
          ),
        ),
        if (line != null) ...[
          if (striking) ...[const CkPulseDot(), const SizedBox(width: 6)],
          Text(
            line.scoreText,
            style: CkType.mono(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: striking ? CkColors.red : CkColors.muted,
            ),
          ),
        ] else
          Text(
            'Yet to bat',
            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
          ),
      ],
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({required this.match});

  final TournamentLiveMatch match;

  @override
  Widget build(BuildContext context) {
    final done = match.isFinished;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  match.round ?? 'Fixture',
                  style:
                      CkType.display(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? (match.resultDescription ?? 'Result recorded')
                      : '${match.venue} · '
                          '${DateFormat('h:mm a').format(match.scheduledStartTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${match.displayNameFor(match.teamAId)} v '
            '${match.displayNameFor(match.teamBId)}',
            style: CkType.body(fontSize: 11, color: CkColors.muted),
          ),
        ],
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({
    required this.label,
    required this.leader,
    required this.rate,
  });

  final String label;
  final TournamentLeader leader;
  final String rate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            leader.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          if (leader.teamName case final t?)
            Text(
              t,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 10.5, color: CkColors.muted),
            ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${leader.primaryValue}',
                style: CkType.mono(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  rate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.mono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: CkColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

// ─── 11 · Completed ───────────────────────────────────────────────────────────

/// An archive page, so it is quiet: **zero red.** The champion spotlight is
/// cream on paper, the honours board is three ruled rows, and everything else
/// is a link into history.
class _CompletedOverview extends ConsumerWidget {
  const _CompletedOverview({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(tournamentLiveBoardProvider(tournament.id)).value ??
        const <TournamentLiveMatch>[];
    final boards = ref.watch(tournamentLeaderboardsProvider(tournament.id)).value;
    final awards = ref.watch(tournamentAwardsProvider(tournament.id)).value;

    // The final is the last decided fixture on the board.
    final decided = board.where((m) => m.winnerId != null).toList()
      ..sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));
    final finalMatch = decided.isEmpty ? null : decided.last;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (finalMatch != null) _ChampionSpotlight(match: finalMatch),
        const _Eyebrow(label: 'Honours board'),
        _Honour(
          label: 'Most valuable player',
          name: awards?.playerOfTheTournament?.playerName,
          team: awards?.playerOfTheTournament?.teamName,
          metric: awards?.playerOfTheTournament?.metricValue,
          pending: 'Named when the organiser publishes the awards',
        ),
        _Honour(
          label: 'Orange cap · most runs',
          name: boards?.orangeCap?.displayName,
          team: boards?.orangeCap?.teamName,
          metric: boards?.orangeCap == null
              ? null
              : '${boards!.orangeCap!.primaryValue} · '
                  'SR ${boards.orangeCap!.rateValue.toStringAsFixed(1)}',
          pending: 'No runs recorded',
        ),
        _Honour(
          label: 'Purple cap · most wickets',
          name: boards?.purpleCap?.displayName,
          team: boards?.purpleCap?.teamName,
          metric: boards?.purpleCap == null
              ? null
              : '${boards!.purpleCap!.primaryValue} · '
                  'Econ ${boards.purpleCap!.rateValue.toStringAsFixed(1)}',
          pending: 'No wickets recorded',
        ),
        const _Eyebrow(label: 'Archive'),
        _ArchiveLink(
          label: 'All ${board.length} scorecards',
          icon: Icons.receipt_long_outlined,
          onTap: () => DefaultTabController.of(context).animateTo(1),
        ),
        _ArchiveLink(
          label: 'Final bracket',
          icon: Icons.account_tree_outlined,
          onTap: () => DefaultTabController.of(context).animateTo(2),
        ),
        _ArchiveLink(
          label: 'Champions card · share',
          icon: Icons.ios_share,
          onTap: () => context.push('/tournaments/${tournament.id}/published'),
        ),
      ],
    );
  }
}

class _ChampionSpotlight extends StatelessWidget {
  const _ChampionSpotlight({required this.match});

  final TournamentLiveMatch match;

  @override
  Widget build(BuildContext context) {
    final winnerId = match.winnerId;
    final loserId = winnerId == match.teamAId ? match.teamBId : match.teamAId;
    final winnerLine = match.lineFor(winnerId);
    final loserLine = match.lineFor(loserId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CkColors.cream,
          borderRadius: BorderRadius.circular(CkRadii.md),
          border: Border.all(color: CkColors.creamBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHAMPION',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.14,
                color: CkColors.amberDark,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              match.displayNameFor(winnerId),
              style: CkType.display(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              match.resultDescription ??
                  'beat ${match.displayNameFor(loserId)}',
              style: CkType.body(
                fontSize: 12.5,
                height: 1.5,
                color: CkColors.ink2,
              ),
            ),
            if (winnerLine != null && loserLine != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    winnerLine.scoreText,
                    style:
                        CkType.mono(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'v',
                      style: CkType.body(fontSize: 12, color: CkColors.muted),
                    ),
                  ),
                  Text(
                    loserLine.scoreText,
                    style: CkType.mono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Honour extends StatelessWidget {
  const _Honour({
    required this.label,
    required this.name,
    required this.team,
    required this.metric,
    required this.pending,
  });

  final String label;
  final String? name;
  final String? team;
  final String? metric;
  final String pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10,
                    color: CkColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name ?? pending,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: name == null ? CkColors.muted : CkColors.ink,
                  ),
                ),
                if (team case final t?)
                  Text(
                    t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
              ],
            ),
          ),
          if (metric case final m?) ...[
            const SizedBox(width: 10),
            Text(
              m,
              style: CkType.mono(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArchiveLink extends StatelessWidget {
  const _ArchiveLink({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: CkColors.ink),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: CkType.body(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: CkColors.soft),
          ],
        ),
      ),
    );
  }
}
