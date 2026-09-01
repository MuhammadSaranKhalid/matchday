import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_awards.dart';
import '../providers/tournaments_providers.dart';

/// Leaderboards and statistical honors for a tournament.
class TournamentStatsTab extends ConsumerStatefulWidget {
  const TournamentStatsTab({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentStatsTab> createState() => _TournamentStatsTabState();
}

class _TournamentStatsTabState extends ConsumerState<TournamentStatsTab> {
  int _selectedStatIndex = 0;

  @override
  Widget build(BuildContext context) {
    final awardsAsync =
        ref.watch(tournamentAwardsProvider(widget.tournament.id));

    return Column(
      children: [
        // Stat category toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: CkColors.paper2,
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      'TOP RUN SCORERS',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _selectedStatIndex == 0
                            ? Colors.white
                            : CkColors.ink2,
                      ),
                    ),
                  ),
                  selected: _selectedStatIndex == 0,
                  selectedColor: CkColors.ink,
                  backgroundColor: CkColors.surface,
                  onSelected: (_) => setState(() => _selectedStatIndex = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      'TOP WICKET TAKERS',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _selectedStatIndex == 1
                            ? Colors.white
                            : CkColors.ink2,
                      ),
                    ),
                  ),
                  selected: _selectedStatIndex == 1,
                  selectedColor: CkColors.ink,
                  backgroundColor: CkColors.surface,
                  onSelected: (_) => setState(() => _selectedStatIndex = 1),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: awardsAsync.when(
            data: (awards) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_selectedStatIndex == 0) ...[
                    if (awards.bestBatsman != null)
                      _buildLeaderCard(
                        title: 'BEST BATSMAN (ORANGE CAP)',
                        recipient: awards.bestBatsman!,
                      ),
                    const SizedBox(height: 12),
                    _buildStatRow(1, 'Babar Azam', 'Model Town CC', '342', 'SR 154.2'),
                    _buildStatRow(2, 'Mohammad Rizwan', 'Cantt CC', '288', 'SR 138.5'),
                    _buildStatRow(3, 'Fakhar Zaman', 'Lahore Gymkhana', '264', 'SR 162.0'),
                  ] else ...[
                    if (awards.bestBowler != null)
                      _buildLeaderCard(
                        title: 'BEST BOWLER (PURPLE CAP)',
                        recipient: awards.bestBowler!,
                      ),
                    const SizedBox(height: 12),
                    _buildStatRow(1, 'Shaheen Afridi', 'Model Town CC', '14 Wkts', 'Econ 5.8'),
                    _buildStatRow(2, 'Haris Rauf', 'Gulberg Lions', '12 Wkts', 'Econ 6.4'),
                    _buildStatRow(3, 'Naseem Shah', 'DHA Strikers', '11 Wkts', 'Econ 6.1'),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderCard({
    required String title,
    required AwardRecipient recipient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF6B5414),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.emoji_events, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B5414),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recipient.playerName,
                  style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildStatRow(
    int rank,
    String playerName,
    String teamName,
    String mainStat,
    String subStat,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: CkType.mono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: rank == 1 ? CkColors.ink : CkColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  style: CkType.display(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  teamName,
                  style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mainStat,
                style: CkType.mono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CkColors.ink,
                ),
              ),
              Text(
                subStat,
                style: CkType.mono(fontSize: 10.5, color: CkColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
