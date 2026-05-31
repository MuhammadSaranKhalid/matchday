import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_innings_state.dart';
import '../providers/matches_providers.dart';

/// Shown when a match reaches `completed` — the headline result + the two
/// innings scores. Reached via the scoring screen's status listener.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.matchId});
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
    final teamA = ref.watch(teamProvider(match.teamAId.value)).value?.name ??
        'Team A';
    final teamB = ref.watch(teamProvider(match.teamBId.value)).value?.name ??
        'Team B';

    final batsFirstA = battingFirstIsTeamA(match);
    final firstName = batsFirstA ? teamA : teamB;
    final secondName = batsFirstA ? teamB : teamA;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('RESULT', style: CkType.mono(fontSize: 12)),
              const SizedBox(height: 10),
              Text(
                match.resultDescription ?? 'Match complete',
                style: CkType.display(fontSize: 26, height: 1.1),
              ),
              const SizedBox(height: 28),
              InningsScoreLine(team: firstName, inns: inns1),
              const SizedBox(height: 10),
              InningsScoreLine(team: secondName, inns: inns2),
              const Spacer(),
              OutlinedButton(
                onPressed: () => context.go('/matches/$matchId/scorecard'),
                child: const Text('View scorecard'),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => context.go('/matches'),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which side batted first, derived from the toss. Shared by the result and
/// scorecard screens (mirrors the engine + repository attribution).
bool battingFirstIsTeamA(Match match) {
  final won = match.tossWonBy?.value;
  final dec = match.tossDecision;
  if (won != null && dec != null) {
    final firstId = dec == TossDecision.bat
        ? won
        : (won == match.teamAId.value
            ? match.teamBId.value
            : match.teamAId.value);
    return firstId == match.teamAId.value;
  }
  return true; // fallback: team A bats first
}

class InningsScoreLine extends StatelessWidget {
  const InningsScoreLine({super.key, required this.team, required this.inns});
  final String team;
  final MatchInningsState? inns;

  @override
  Widget build(BuildContext context) {
    final score = inns == null
        ? '—'
        : '${inns!.totalRuns}/${inns!.totalWickets}  (${inns!.oversText})';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              team,
              style: CkType.body(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Text(score, style: CkType.mono(fontSize: 15, color: CkColors.ink)),
        ],
      ),
    );
  }
}
