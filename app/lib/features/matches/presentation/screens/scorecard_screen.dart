import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/match_innings_state.dart';
import '../../domain/entities/match_player.dart';
import '../../domain/scoring/scoring_rules.dart';
import '../providers/matches_providers.dart';
import 'result_screen.dart' show InningsScoreLine, battingFirstIsTeamA;

/// A full detailed scorecard with per-batter and per-bowler figures, extras,
/// and innings summaries.
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
    final balls1 =
        ref.watch(liveBallsProvider(matchId, 1)).value ?? const <Ball>[];
    final balls2 =
        ref.watch(liveBallsProvider(matchId, 2)).value ?? const <Ball>[];
    final matchPlayers =
        ref.watch(matchPlayersProvider(matchId)).value ?? const <MatchPlayer>[];

    final teamA =
        ref.watch(teamProvider(match.teamAId.value)).value?.name ?? 'Team A';
    final teamB =
        ref.watch(teamProvider(match.teamBId.value)).value?.name ?? 'Team B';
    final batsFirstA = battingFirstIsTeamA(match);
    final firstName = batsFirstA ? teamA : teamB;
    final secondName = batsFirstA ? teamB : teamA;

    final ballsPerOver =
        match.format.ballsPerOver == 0 ? 6 : match.format.ballsPerOver;

    return Scaffold(
      backgroundColor: CkColors.paper,
      appBar: AppBar(
        backgroundColor: CkColors.paper,
        surfaceTintColor: CkColors.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: CkColors.ink),
          onPressed:
              () => context.canPop() ? context.pop() : context.go('/matches'),
        ),
        title: Text('SCORECARD', style: CkType.mono(fontSize: 12)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _InningsScorecard(
              label: '1st innings',
              team: firstName,
              inns: inns1,
              balls: balls1,
              matchPlayers: matchPlayers,
              ballsPerOver: ballsPerOver,
            ),
            _InningsScorecard(
              label: '2nd innings',
              team: secondName,
              inns: inns2,
              balls: balls2,
              matchPlayers: matchPlayers,
              ballsPerOver: ballsPerOver,
            ),
          ],
        ),
      ),
    );
  }
}

class _InningsScorecard extends StatelessWidget {
  const _InningsScorecard({
    required this.label,
    required this.team,
    required this.inns,
    required this.balls,
    required this.matchPlayers,
    required this.ballsPerOver,
  });

  final String label;
  final String team;
  final MatchInningsState? inns;
  final List<Ball> balls;
  final List<MatchPlayer> matchPlayers;
  final int ballsPerOver;

  @override
  Widget build(BuildContext context) {
    if (inns == null && balls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label.toUpperCase(), style: CkType.mono(fontSize: 11)),
            const SizedBox(height: 8),
            InningsScoreLine(team: team, inns: null),
          ],
        ),
      );
    }

    String nameOfId(String? matchPlayerId) {
      if (matchPlayerId == null) return '—';
      final p =
          matchPlayers.where((mp) => mp.id.value == matchPlayerId).firstOrNull;
      return p?.displayName ?? '—';
    }

    // Batters involved in this innings
    final batterIds = <String>[];
    for (final b in balls) {
      if (b.batsmanId != null && !batterIds.contains(b.batsmanId)) {
        batterIds.add(b.batsmanId!);
      }
      if (b.nonStrikerId != null && !batterIds.contains(b.nonStrikerId)) {
        batterIds.add(b.nonStrikerId!);
      }
    }
    if (inns?.strikerId != null &&
        !batterIds.contains(inns!.strikerId!.value)) {
      batterIds.add(inns!.strikerId!.value);
    }
    if (inns?.nonStrikerId != null &&
        !batterIds.contains(inns!.nonStrikerId!.value)) {
      batterIds.add(inns!.nonStrikerId!.value);
    }

    // Dismissal description for each batter
    String dismissalText(String batterId) {
      final dismissalBall =
          balls
              .where(
                (b) =>
                    (b.dismissedPlayerId ??
                            (b.isWicket ? b.batsmanId : null)) ==
                        batterId &&
                    b.isWicket,
              )
              .firstOrNull;
      if (dismissalBall == null) {
        final isCurrentlyIn =
            (inns?.strikerId?.value == batterId ||
                inns?.nonStrikerId?.value == batterId) &&
            !(inns?.isAllOut ?? false);
        return isCurrentlyIn ? 'not out *' : 'not out';
      }
      final type = dismissalBall.wicketType?.label ?? 'out';
      final bowler = nameOfId(dismissalBall.bowlerId);
      final fielder = nameOfId(dismissalBall.fielderId);
      if (dismissalBall.wicketType == WicketType.bowled) {
        return 'b $bowler';
      }
      if (dismissalBall.wicketType == WicketType.caught) {
        return 'c $fielder b $bowler';
      }
      if (dismissalBall.wicketType == WicketType.lbw) {
        return 'lbw b $bowler';
      }
      if (dismissalBall.wicketType == WicketType.runOut) {
        return fielder != '—' ? 'run out ($fielder)' : 'run out';
      }
      if (dismissalBall.wicketType == WicketType.stumped) {
        return 'st $fielder b $bowler';
      }
      if (dismissalBall.wicketType == WicketType.hitWicket) {
        return 'hit wicket b $bowler';
      }
      return type;
    }

    // Bowlers involved in this innings
    final bowlerIds = <String>[];
    for (final b in balls) {
      if (b.bowlerId != null && !bowlerIds.contains(b.bowlerId)) {
        bowlerIds.add(b.bowlerId!);
      }
    }

    // Extras breakdown
    var wides = 0, noBalls = 0, byes = 0, legByes = 0;
    for (final b in balls) {
      if (b.ballKind == BallKind.wide) wides += b.extras;
      if (b.ballKind == BallKind.noBall) noBalls += b.extras;
      if (b.ballKind == BallKind.bye) byes += b.extras;
      if (b.ballKind == BallKind.legBye) legByes += b.extras;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CkColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: CkType.mono(fontSize: 10, color: CkColors.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        team,
                        style: CkType.display(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  inns == null
                      ? '—'
                      : '${inns!.totalRuns}/${inns!.totalWickets} (${inns!.oversText} ov)',
                  style: CkType.display(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Batting Table Header
          Container(
            color: CkColors.paper2,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'BATTER',
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    'R',
                    textAlign: TextAlign.right,
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    'B',
                    textAlign: TextAlign.right,
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '4s',
                    textAlign: TextAlign.right,
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '6s',
                    textAlign: TextAlign.right,
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    'SR',
                    textAlign: TextAlign.right,
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Batting Rows
          for (final batterId in batterIds) ...[
            Builder(
              builder: (_) {
                final stats = batterStatsFor(balls, batterId);
                final dismissal = dismissalText(batterId);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: CkColors.hairline),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameOfId(batterId),
                              style: CkType.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              dismissal,
                              style: CkType.body(
                                fontSize: 11,
                                color: CkColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${stats.runs}',
                          textAlign: TextAlign.right,
                          style: CkType.display(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${stats.balls}',
                          textAlign: TextAlign.right,
                          style: CkType.mono(
                            fontSize: 11,
                            color: CkColors.ink2,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${stats.fours}',
                          textAlign: TextAlign.right,
                          style: CkType.mono(
                            fontSize: 11,
                            color: CkColors.muted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${stats.sixes}',
                          textAlign: TextAlign.right,
                          style: CkType.mono(
                            fontSize: 11,
                            color: CkColors.muted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          stats.strikeRate.toStringAsFixed(1),
                          textAlign: TextAlign.right,
                          style: CkType.mono(
                            fontSize: 11,
                            color: CkColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          // Extras Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Extras',
                  style: CkType.body(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  '(w $wides, nb $noBalls, b $byes, lb $legByes)',
                  style: CkType.mono(fontSize: 10, color: CkColors.muted),
                ),
                const Spacer(),
                Text(
                  '${inns?.totalExtras ?? 0}',
                  style: CkType.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Bowling Table Header
          Container(
            color: CkColors.paper2,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'BOWLER',
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    'O',
                    textAlign: TextAlign.right,
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    'M',
                    textAlign: TextAlign.right,
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    'R',
                    textAlign: TextAlign.right,
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    'W',
                    textAlign: TextAlign.right,
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    'ECON',
                    textAlign: TextAlign.right,
                    style: CkType.mono(
                      fontSize: 9,
                      color: CkColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bowling Rows
          for (final bowlerId in bowlerIds) ...[
            Builder(
              builder: (_) {
                final spell = bowlerSpellFor(
                  balls,
                  bowlerId,
                  ballsPerOver: ballsPerOver,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: CkColors.hairline),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          nameOfId(bowlerId),
                          style: CkType.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${spell.overs}.${spell.ballsThisOver}',
                          textAlign: TextAlign.right,
                          style: CkType.mono(
                            fontSize: 11,
                            color: CkColors.ink2,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${spell.maidens}',
                          textAlign: TextAlign.right,
                          style: CkType.mono(
                            fontSize: 11,
                            color: CkColors.muted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${spell.runs}',
                          textAlign: TextAlign.right,
                          style: CkType.mono(
                            fontSize: 11,
                            color: CkColors.ink2,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${spell.wickets}',
                          textAlign: TextAlign.right,
                          style: CkType.display(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          spell.economy.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: CkType.mono(
                            fontSize: 11,
                            color: CkColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
