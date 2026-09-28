import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/entities/tournament_registration.dart';
import '../providers/tournaments_providers.dart';
import 'champion_moment_view.dart';
import 'tournament_awards_sheet.dart';

/// Artboard 27b — Live Ops becomes Wrap Up once the final is scored.
///
/// A short checklist of the three things left to do, then the cup closes.
/// Zero red: nothing here is live or destructive.
class TournamentWrapUpTab extends ConsumerWidget {
  const TournamentWrapUpTab({super.key, required this.tournament});

  final Tournament tournament;

  /// The final is the last fixture to finish — highest bracket round if the
  /// draw is a tree, otherwise the latest completed fixture.
  TournamentLiveMatch? _finalOf(List<TournamentLiveMatch> board) {
    final finished = board.where((m) => m.isFinished && m.winnerId != null);
    if (finished.isEmpty) return null;
    return finished.reduce(
      (a, b) => b.scheduledStartTime.isAfter(a.scheduledStartTime) ? b : a,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(tournamentLiveBoardProvider(tournament.id));
    final regsAsync = ref.watch(tournamentRegistrationsProvider(tournament.id));
    final awardsPublished = tournament.awards.isNotEmpty;

    return boardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$e',
            style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (board) {
        final decider = _finalOf(board);
        final played = board.where((m) => m.isFinished).length;
        final allConfirmed = played == board.length && board.isNotEmpty;
        final regs = regsAsync.value ?? const <TournamentRegistration>[];
        final approved = regs.where((r) => r.isApproved).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            if (decider != null)
              _ChampionCard(
                tournament: tournament,
                decider: decider,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChampionMomentView(
                      tournament: tournament,
                      championTeamName:
                          decider.displayNameFor(decider.winnerId),
                      runnerUpTeamName: decider.displayNameFor(
                        decider.winnerId == decider.teamAId
                            ? decider.teamBId
                            : decider.teamAId,
                      ),
                      finalScoreSummary:
                          decider.resultDescription ?? 'Won the final',
                      matchesPlayed: played,
                      teamCount: approved.length,
                      city: tournament.city,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              'THREE THINGS LEFT',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
              ),
            ),
            const SizedBox(height: 8),
            _ChecklistRow(
              done: allConfirmed,
              title: allConfirmed
                  ? 'All $played results confirmed'
                  : '$played of ${board.length} results confirmed',
              subtitle: allConfirmed
                  ? 'Every fixture has a recorded outcome'
                  : 'Finish the remaining fixtures on Live Ops',
            ),
            _ChecklistRow(
              done: awardsPublished,
              title: 'Review & publish awards',
              subtitle: awardsPublished
                  ? 'Published'
                  : 'Auto-computed · not yet published',
              actionLabel: awardsPublished ? null : 'Review',
              onAction: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TournamentAwardsSheet(tournament: tournament),
              ),
            ),
            _ChecklistRow(
              done: false,
              enabled: awardsPublished && decider != null,
              title: 'Share the champions card',
              subtitle: awardsPublished
                  ? 'Ready to post'
                  : 'Unlocks once awards are published',
              actionLabel: 'Share',
              onAction: decider == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChampionMomentView(
                            tournament: tournament,
                            championTeamName:
                                decider.displayNameFor(decider.winnerId),
                            runnerUpTeamName: decider.displayNameFor(
                              decider.winnerId == decider.teamAId
                                  ? decider.teamBId
                                  : decider.teamAId,
                            ),
                            finalScoreSummary:
                                decider.resultDescription ?? 'Won the final',
                            matchesPlayed: played,
                            teamCount: approved.length,
                            city: tournament.city,
                          ),
                        ),
                      ),
            ),
            if ((tournament.entryFee ?? 0) > 0) ...[
              const SizedBox(height: 18),
              _FeesCollected(
                tournament: tournament,
                approved: approved,
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'THE CUP IN NUMBERS',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberTile(label: 'Matches', value: '$played'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberTile(
                    label: 'Teams',
                    value: '${approved.length}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberTile(
                    label: 'Players',
                    value: '${approved.fold<int>(0, (s, r) => s + r.squad.length)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(CkRadii.md),
                border: Border.all(color: CkColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run it again next season?',
                    style: CkType.display(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Duplicates the format, rules and venues into a new draft. '
                    'Teams are not carried over.',
                    style: CkType.body(
                      fontSize: 12.5,
                      height: 1.5,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push(
                      '/tournaments/create?duplicateOf=${tournament.id}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CkColors.ink,
                      side: const BorderSide(color: CkColors.line),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CkRadii.sm),
                      ),
                    ),
                    child: Text(
                      'Duplicate as a new draft',
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChampionCard extends StatelessWidget {
  const _ChampionCard({
    required this.tournament,
    required this.decider,
    required this.onOpen,
  });

  final Tournament tournament;
  final TournamentLiveMatch decider;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final champion = decider.displayNameFor(decider.winnerId);
    final parts = champion.trim().split(RegExp(r'\s+'));
    final initials = parts.length == 1
        ? parts.first.characters.take(2).toString().toUpperCase()
        : (parts.first.characters.first + parts[1].characters.first)
            .toUpperCase();

    return Material(
      color: CkColors.paper,
      borderRadius: BorderRadius.circular(CkRadii.md),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(CkRadii.md),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.creamBorder),
            color: CkColors.cream,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: CkColors.creamBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: CkType.display(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CHAMPION',
                      style: CkType.mono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.12,
                        color: CkColors.amberDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      champion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.display(fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      decider.resultDescription ?? 'Won the final',
                      style: CkType.body(
                        fontSize: 12,
                        color: CkColors.amberDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: CkColors.amberDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.done,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.enabled = true,
  });

  final bool done;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final live = enabled && !done;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done
                ? CkColors.greenInk
                : (live ? CkColors.ink2 : CkColors.soft),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: CkType.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: live || done ? CkColors.ink : CkColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                ),
              ],
            ),
          ),
          if (actionLabel != null && live && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: CkColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                actionLabel!,
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.ink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeesCollected extends StatelessWidget {
  const _FeesCollected({required this.tournament, required this.approved});

  final Tournament tournament;
  final List<TournamentRegistration> approved;

  @override
  Widget build(BuildContext context) {
    final fee = tournament.entryFee ?? 0;
    final paid = approved.where((r) => r.paymentStatus == 'paid').length;
    final money = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);
    final due = fee * approved.length;
    final collected = fee * paid;
    final outstanding = due - collected;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: outstanding > 0 ? CkColors.cream : CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(
          color: outstanding > 0 ? CkColors.creamBorder : CkColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FEES COLLECTED',
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: outstanding > 0 ? CkColors.amberDark : CkColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$paid of ${approved.length} teams paid · ${money.format(collected)}',
            style: CkType.display(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            outstanding > 0
                ? 'of ${money.format(due)} · ${money.format(outstanding)} outstanding'
                : 'Everything is settled',
            style: CkType.body(
              fontSize: 12,
              color: outstanding > 0 ? CkColors.amberDark : CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: CkType.mono(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: CkColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
