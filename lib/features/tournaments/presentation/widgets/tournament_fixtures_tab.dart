import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../matches/domain/entities/match.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournaments_providers.dart';
import 'tournament_fixture_row.dart';

/// Fixtures list tab grouped by round or day.
class TournamentFixturesTab extends ConsumerWidget {
  const TournamentFixturesTab({super.key, required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(tournamentFixturesProvider(tournament.id));

    return fixturesAsync.when(
      data: (fixtures) {
        if (fixtures.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy_outlined,
                      size: 40, color: CkColors.soft),
                  const SizedBox(height: 12),
                  Text('No Fixtures Scheduled',
                      style: CkType.display(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Fixtures will be published after registration closes.',
                    style: CkType.body(fontSize: 13, color: CkColors.muted),
                  ),
                ],
              ),
            ),
          );
        }

        // Group fixtures by bracketRoundNumber if present
        final hasRounds = fixtures.any((f) => f.bracketRoundNumber != null);

        if (!hasRounds) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: fixtures.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final f = fixtures[index];
              return TournamentFixtureRow(
                match: f,
                onTap: () => context.push('/matches/${f.id.value}'),
              );
            },
          );
        }

        final roundsMap = <int, List<Match>>{};
        for (final f in fixtures) {
          final r = f.bracketRoundNumber ?? 1;
          roundsMap.putIfAbsent(r, () => []).add(f);
        }
        final sortedRounds = roundsMap.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedRounds.length,
          itemBuilder: (context, rIdx) {
            final roundNum = sortedRounds[rIdx];
            final roundFixtures = roundsMap[roundNum]!;
            final roundTitle = _roundLabel(roundNum, sortedRounds.last);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Row(
                    children: [
                      Text(
                        roundTitle.toUpperCase(),
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CkColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: CkColors.paper2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${roundFixtures.length} matches',
                          style: CkType.mono(fontSize: 9.5, color: CkColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
                ...roundFixtures.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TournamentFixtureRow(
                        match: f,
                        onTap: () => context.push('/matches/${f.id.value}'),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  String _roundLabel(int roundNum, int maxRound) {
    if (roundNum == maxRound) return 'Final';
    if (roundNum == maxRound - 1) return 'Semi-Finals';
    if (roundNum == maxRound - 2) return 'Quarter-Finals';
    return 'Round $roundNum';
  }
}
