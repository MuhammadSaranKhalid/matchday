// The read-out half of the scoring screen: everything that displays state and
// takes no input. Its counterpart is the pad/ subsystem.
//
// Purely presentational — no Riverpod, no repository access. Anything that
// renders lives here or in a sibling; the screen only composes and dispatches.
import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/util/initials.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../domain/entities/ball.dart';
import '../../../domain/entities/match_player.dart';
import '../../../domain/scoring/scoring_rules.dart';
import '../../state/scoring_state.dart';
import 'ball_chip.dart';

/// Bowler badge — a green distinct from the status green.
const kBowlerBadgeColor = Color(0xFF1A6A2E); // oklch(0.36 0.10 148)

/// Free-hit banner border and text. Shared with the extras sheet, which
/// offers the free-hit toggle on a no-ball.
const kFreeHitBorder = Color(0xFFD9B96B); // oklch(0.85 0.10 80)
const kFreeHitText = Color(0xFF4B3514); // oklch(0.32 0.10 80)

/// The ink card at the top: score, overs, balls left, run rate.
class Scoreboard extends StatelessWidget {
  const Scoreboard({super.key, required this.state});

  final ScoringState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${state.totalRuns}',
                      style: CkType.display(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                        color: CkColors.paper,
                      ),
                    ),
                    TextSpan(
                      text: '/${state.totalWickets}',
                      style: CkType.display(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                        color: const Color(0x8CFDFAF4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  label: 'OVERS',
                  value: state.overText,
                  suffix: ' /${state.formatOvers}',
                ),
              ),
              _Stat(label: 'BALLS', value: '${state.ballsRemaining}', end: true),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
              ),
              child: Row(
                children: [
                  Text(
                    'CRR ',
                    style: CkType.mono(
                      fontSize: 11,
                      color: const Color(0x8CFDFAF4),
                    ),
                  ),
                  Text(
                    state.currentRunRate.toStringAsFixed(2),
                    style: CkType.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CkColors.paper,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'PARTNERSHIP ',
                    style: CkType.mono(
                      fontSize: 11,
                      color: const Color(0x8CFDFAF4),
                    ),
                  ),
                  Text(
                    '${state.currentPartnership.runs} (${state.currentPartnership.balls})',
                    style: CkType.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CkColors.paper,
                    ),
                  ),
                  if (state.isChase) ...[
                    const Spacer(),
                    Text(
                      'NEED ${state.runsNeeded} (${state.ballsRemaining}b) · RRR ',
                      style: CkType.mono(
                        fontSize: 11,
                        color: const Color(0x8CFDFAF4),
                      ),
                    ),
                    Text(
                      state.requiredRunRate?.toStringAsFixed(2) ?? '—',
                      style: CkType.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CkColors.amber,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One labelled figure on the ink scoreboard.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.suffix,
    this.end = false,
  });

  final String label;
  final String value;
  final String? suffix;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: const Color(0x8CFDFAF4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: CkType.display(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CkColors.paper,
                  ),
                ),
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: CkType.display(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0x80FDFAF4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The two batter cards plus the bowler strip and its six-ball dots.
class BattersAndBowler extends StatelessWidget {
  const BattersAndBowler({
    super.key,
    required this.state,
    this.onTapBowler,
    this.onTapStriker,
    this.onTapNonStriker,
  });

  final ScoringState state;
  final VoidCallback? onTapBowler;
  final VoidCallback? onTapStriker;
  final VoidCallback? onTapNonStriker;

  @override
  Widget build(BuildContext context) {
    final spell = state.bowlerSpell;
    final chips = [
      for (final b in state.currentOverBalls)
        BallChipData(label: ballChipLabel(b), kind: ballChipKind(b)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: BatterCard(
                  name: state.strikerName,
                  photoUrl: state.strikerPhoto,
                  stats: state.strikerStats,
                  onStrike: true,
                  onTap: state.canScore ? onTapStriker : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BatterCard(
                  name: state.nonStrikerName,
                  photoUrl: state.nonStrikerPhoto,
                  stats: state.nonStrikerStats,
                  onStrike: false,
                  onTap: state.canScore ? onTapNonStriker : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Material(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: state.canScore ? onTapBowler : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Row(
                  children: [
                    Avatar(
                      mono: personInitials(state.bowlerName),
                      imageUrl: state.bowlerPhoto,
                      size: 28,
                      background: kBowlerBadgeColor,
                      foreground: CkColors.paper,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  state.bowlerName,
                                  overflow: TextOverflow.ellipsis,
                                  style: CkType.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (state.canScore) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 14,
                                  color: CkColors.muted,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${spell.overs}.${spell.ballsThisOver} ov · '
                            '${spell.maidens}m · '
                            '${spell.runs}r · ${spell.wickets}w',
                            style: CkType.mono(
                              fontSize: 10,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 6; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          if (i < chips.length)
                            BallChip(chip: chips[i], size: 22)
                          else
                            const _EmptyBallSlot(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Group of deliveries belonging to a single over.
class OverGroup {
  const OverGroup({
    required this.overNumber,
    required this.bowlerId,
    required this.balls,
    required this.totalRuns,
    required this.totalWickets,
  });

  final int overNumber;
  final String? bowlerId;
  final List<Ball> balls;
  final int totalRuns;
  final int totalWickets;
}

List<OverGroup> groupBallsByOver(List<Ball> balls) {
  if (balls.isEmpty) return const [];
  final map = <int, List<Ball>>{};
  for (final b in balls) {
    map.putIfAbsent(b.overNumber, () => []).add(b);
  }
  final groups = <OverGroup>[];
  final sortedOvers = map.keys.toList()..sort();
  for (final overNum in sortedOvers) {
    final overBalls = map[overNum]!;
    String? bowlerId;
    var runs = 0;
    var wickets = 0;
    for (final b in overBalls) {
      bowlerId ??= b.bowlerId;
      runs += (b.runsScored + b.extras);
      if (b.isWicket) wickets += 1;
    }
    groups.add(OverGroup(
      overNumber: overNum,
      bowlerId: bowlerId,
      balls: overBalls,
      totalRuns: runs,
      totalWickets: wickets,
    ));
  }
  return groups;
}

/// The rolling list of deliveries grouped by over, newest over first.
class BallLog extends StatelessWidget {
  const BallLog({
    super.key,
    required this.balls,
    this.nameOf,
    this.matchPlayers = const [],
  });

  final List<Ball> balls;

  /// Resolves a player ref id to a name.
  final String Function(String?)? nameOf;

  /// Needed to translate a ball's `match_player_id` into the ref id [nameOf] speaks.
  final List<MatchPlayer> matchPlayers;

  String? _name(String? matchPlayerId) {
    if (nameOf == null || matchPlayerId == null) return null;
    final refId = matchPlayers.playerRefIdOf(matchPlayerId);
    if (refId == null) return null;
    final resolved = nameOf!(refId);
    return resolved == '—' ? null : resolved;
  }

  String _describe(Ball b) => describeBall(
        b,
        batterName: _name(b.dismissedPlayerId ?? b.batsmanId),
        fielderName: _name(b.fielderId),
      );

  @override
  Widget build(BuildContext context) {
    if (balls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No deliveries recorded yet',
            style: CkType.body(fontSize: 13, color: CkColors.muted),
          ),
        ),
      );
    }

    final overGroups = groupBallsByOver(balls).reversed.toList();
    final latestBallId = balls.last.id;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      shrinkWrap: false,
      itemCount: overGroups.length,
      itemBuilder: (context, index) {
        final group = overGroups[index];
        final bowlerName = _name(group.bowlerId) ?? 'Bowler';
        final isCurrentOver = index == 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentOver ? CkColors.surface : CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentOver ? CkColors.line : CkColors.hairline,
                width: isCurrentOver ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Over Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentOver
                        ? CkColors.paper2
                        : const Color(0x08000000),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCurrentOver ? CkColors.ink : CkColors.muted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OVER ${group.overNumber + 1}',
                          style: CkType.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bowlerName,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.body(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CkColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        '${group.totalRuns} runs${group.totalWickets > 0 ? ' · ${group.totalWickets}w' : ''}',
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Deliveries in this over (reversed so newest in over is on top)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(
                    children: [
                      for (final ball in group.balls.reversed)
                        BallLogRow(
                          ball: ball,
                          highlighted: ball.id == latestBallId,
                          description: _describe(ball),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BallLogRow extends StatelessWidget {
  const BallLogRow({
    super.key,
    required this.ball,
    required this.highlighted,
    required this.description,
  });

  final Ball ball;
  final bool highlighted;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? CkColors.cream : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              ballNumberLabel(ball),
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: CkColors.muted,
              ),
            ),
          ),
          BallChip(
            chip: BallChipData(
              label: ballChipLabel(ball),
              kind: ballChipKind(ball),
            ),
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(
                fontSize: 12,
                color: CkColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBallSlot extends StatelessWidget {
  const _EmptyBallSlot();

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: CkColors.line, width: 1.5),
        ),
      );
}

class BatterCard extends StatelessWidget {
  const BatterCard({
    super.key,
    required this.name,
    required this.stats,
    required this.onStrike,
    this.photoUrl,
    this.onTap,
  });
  final String name;
  final BatterStats stats;
  final bool onStrike;
  final VoidCallback? onTap;

  /// Avatar URL, or null to render the monogram. Kept small (20px) — two of
  /// these sit side by side and the runs figure is what the scorer reads.
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onStrike ? CkColors.surface : CkColors.paper2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onStrike ? CkColors.ink : CkColors.hairline,
              width: onStrike ? 1.5 : 1,
            ),
          ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(
                    mono: personInitials(name),
                    imageUrl: photoUrl,
                    size: 20,
                    tone: onStrike ? AvatarTone.ink : AvatarTone.paper,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onStrike ? CkColors.ink : CkColors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${stats.runs}',
                    style: CkType.display(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${stats.balls})',
                    style: CkType.mono(
                      fontSize: 11,
                      color: CkColors.muted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Flexible, not a Spacer + fixed Text: with a Spacer the
                  // boundary tally had no way to give ground, so two of these
                  // cards side by side on a phone overflowed the row. Letting
                  // it ellipsise keeps the runs figure — the number actually
                  // being read — intact instead.
                  Expanded(
                    child: Text(
                      '${stats.fours}×4 ${stats.sixes}×6',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.mono(
                        fontSize: 10,
                        color: CkColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (onStrike)
            const Positioned(
              top: 0,
              right: 0,
              child: _StrikeDot(),
            ),
        ],
      ),
    ),
  ),
);
  }
}

class _StrikeDot extends StatelessWidget {
  const _StrikeDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: CkColors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}

class FreeHitBanner extends StatelessWidget {
  const FreeHitBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kFreeHitBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: CkColors.amber,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: CkColors.paper,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'FREE HIT',
                  style: CkType.mono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: CkColors.paper,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Next ball — only a run-out or hit wicket can dismiss.',
              style: CkType.body(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kFreeHitText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
