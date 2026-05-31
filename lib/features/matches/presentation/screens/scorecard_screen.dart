import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match_innings_state.dart';
import '../providers/matches_providers.dart';
import 'result_screen.dart' show InningsScoreLine, battingFirstIsTeamA;

/// A summary scorecard: per-innings totals (runs / wickets / overs / extras).
/// A full per-batter card is a later enhancement.
class ScorecardScreen extends ConsumerWidget {
  const ScorecardScreen({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(liveMatchProvider(matchId)).value;
    if (match == null) {
      return const Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: CircularProgressIndicator(color: CkColors.ink)),
      );
    }
    final inns1 = ref.watch(liveInningsStateProvider(matchId, 1)).value;
    final inns2 = ref.watch(liveInningsStateProvider(matchId, 2)).value;
    final teamA =
        ref.watch(teamProvider(match.teamAId.value)).value?.name ?? 'Team A';
    final teamB =
        ref.watch(teamProvider(match.teamBId.value)).value?.name ?? 'Team B';
    final batsFirstA = battingFirstIsTeamA(match);
    final firstName = batsFirstA ? teamA : teamB;
    final secondName = batsFirstA ? teamB : teamA;

    return Scaffold(
      backgroundColor: CkColors.paper,
      appBar: AppBar(
        backgroundColor: CkColors.paper,
        surfaceTintColor: CkColors.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: CkColors.ink),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/matches'),
        ),
        title: Text('SCORECARD', style: CkType.mono(fontSize: 12)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _InningsBlock(label: '1st innings', team: firstName, inns: inns1),
            const SizedBox(height: 18),
            _InningsBlock(label: '2nd innings', team: secondName, inns: inns2),
          ],
        ),
      ),
    );
  }
}

class _InningsBlock extends StatelessWidget {
  const _InningsBlock({
    required this.label,
    required this.team,
    required this.inns,
  });
  final String label;
  final String team;
  final MatchInningsState? inns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label.toUpperCase(), style: CkType.mono(fontSize: 11)),
        const SizedBox(height: 8),
        InningsScoreLine(team: team, inns: inns),
        if (inns != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Extras ${inns!.totalExtras}',
              style: CkType.body(fontSize: 13, color: CkColors.muted),
            ),
          ),
        ],
      ],
    );
  }
}
