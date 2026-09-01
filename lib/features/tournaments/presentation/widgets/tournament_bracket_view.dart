import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../matches/domain/entities/match.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournaments_providers.dart';
import 'ck_bracket_node.dart';

/// Horizontal panning knockout bracket tree with round selector pills.
class TournamentBracketView extends ConsumerStatefulWidget {
  const TournamentBracketView({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentBracketView> createState() =>
      _TournamentBracketViewState();
}

class _TournamentBracketViewState extends ConsumerState<TournamentBracketView> {
  int _selectedRoundIndex = 0;

  @override
  Widget build(BuildContext context) {
    final fixturesAsync =
        ref.watch(tournamentFixturesProvider(widget.tournament.id));

    return fixturesAsync.when(
      data: (fixtures) {
        if (fixtures.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_tree_outlined,
                      size: 40, color: CkColors.soft),
                  const SizedBox(height: 12),
                  Text('Bracket Not Yet Generated',
                      style: CkType.display(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'The knockout bracket tree will appear here once the organizer seeds the teams and publishes fixtures.',
                    style: CkType.body(fontSize: 13, color: CkColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Group fixtures by bracket_round_number
        final roundsMap = <int, List<Match>>{};
        for (final f in fixtures) {
          final r = f.bracketRoundNumber ?? 1;
          roundsMap.putIfAbsent(r, () => []).add(f);
        }

        final roundKeys = roundsMap.keys.toList()..sort();
        final roundNames = roundKeys.map((r) {
          if (r == roundKeys.last) return 'Final';
          if (r == roundKeys.last - 1) return 'Semi-Finals';
          if (r == roundKeys.last - 2) return 'Quarter-Finals';
          return 'Round $r';
        }).toList();

        return Column(
          children: [
            // Round Selector Pills
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CkColors.paper2,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: roundKeys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final isSelected = _selectedRoundIndex == idx;
                  return ChoiceChip(
                    label: Text(
                      roundNames[idx],
                      style: CkType.mono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : CkColors.ink2,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: CkColors.ink,
                    backgroundColor: CkColors.surface,
                    onSelected: (_) =>
                        setState(() => _selectedRoundIndex = idx),
                  );
                },
              ),
            ),

            // Horizontal Bracket Tree
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: roundKeys.map((roundNum) {
                    final roundMatches = roundsMap[roundNum] ?? [];
                    final roundTitle =
                        roundNames[roundKeys.indexOf(roundNum)];

                    return Container(
                      width: 195,
                      margin: const EdgeInsets.only(right: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roundTitle.toUpperCase(),
                            style: CkType.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: CkColors.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: roundMatches.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 24),
                              itemBuilder: (context, matchIdx) {
                                final match = roundMatches[matchIdx];
                                final isLive =
                                    match.status == MatchStatus.live;

                                return CkBracketNode(
                                  teamAName: 'Team A',
                                  teamBName: 'Team B',
                                  seedA: matchIdx * 2 + 1,
                                  seedB: matchIdx * 2 + 2,
                                  isLive: isLive,
                                  roundLabel: match.round,
                                  onTap: () => context
                                      .push('/matches/${match.id.value}'),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}
