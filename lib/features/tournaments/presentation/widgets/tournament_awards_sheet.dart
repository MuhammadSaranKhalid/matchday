import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_awards.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';

/// Bottom sheet allowing the organizer to review and confirm individual tournament awards.
class TournamentAwardsSheet extends ConsumerStatefulWidget {
  const TournamentAwardsSheet({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentAwardsSheet> createState() =>
      _TournamentAwardsSheetState();
}

class _TournamentAwardsSheetState extends ConsumerState<TournamentAwardsSheet> {
  Future<void> _confirm(TournamentAwards awards) async {
    final ok = await ref
        .read(tournamentsControllerProvider.notifier)
        .confirmAwards(widget.tournament.id, awards);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Awards confirmed and published!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final awardsAsync =
        ref.watch(tournamentAwardsProvider(widget.tournament.id));
    final isBusy = ref.watch(tournamentsControllerProvider).isLoading;

    return Container(
      decoration: const BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(CkRadii.lg)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tournament Awards',
                    style: CkType.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: CkColors.ink),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: CkColors.hairline),
            Expanded(
              child: awardsAsync.when(
                data: (awards) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _awardTile(
                        'PLAYER OF THE TOURNAMENT (MVP)',
                        awards.playerOfTheTournament ??
                            const AwardRecipient(
                              playerId: '1',
                              playerName: 'Babar Azam',
                              teamName: 'Model Town CC',
                              metricLabel: 'Performance',
                              metricValue: '342 Runs · 6 Wkts',
                            ),
                      ),
                      const SizedBox(height: 12),
                      _awardTile(
                        'BEST BATSMAN (ORANGE CAP)',
                        awards.bestBatsman ??
                            const AwardRecipient(
                              playerId: '1',
                              playerName: 'Babar Azam',
                              teamName: 'Model Town CC',
                              metricLabel: 'Runs',
                              metricValue: '342 Runs (SR 154.2)',
                            ),
                      ),
                      const SizedBox(height: 12),
                      _awardTile(
                        'BEST BOWLER (PURPLE CAP)',
                        awards.bestBowler ??
                            const AwardRecipient(
                              playerId: '2',
                              playerName: 'Shaheen Afridi',
                              teamName: 'Model Town CC',
                              metricLabel: 'Wickets',
                              metricValue: '14 Wickets (Econ 5.8)',
                            ),
                      ),
                      const SizedBox(height: 24),
                      CkButton(
                        label: isBusy
                            ? 'Confirming...'
                            : 'Confirm & Publish Awards →',
                        onPressed: isBusy ? null : () => _confirm(awards),
                        variant: CkButtonVariant.primary,
                      ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _awardTile(String label, AwardRecipient recipient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: CkColors.cream,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.emoji_events,
                  size: 22, color: Color(0xFF6B5414)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CkType.mono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: CkColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recipient.playerName,
                  style: CkType.display(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${recipient.teamName ?? "Team"} · ${recipient.metricValue}',
                  style: CkType.body(fontSize: 12, color: CkColors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
