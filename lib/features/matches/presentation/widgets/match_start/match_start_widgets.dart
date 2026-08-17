import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../teams/domain/entities/roster_member.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../../teams/presentation/providers/teams_providers.dart';
import '../../../domain/entities/match.dart';
import '../../../domain/entities/match_player.dart';
import '../../providers/match_start_lineup_provider.dart';
import '../../providers/matches_providers.dart';
import '../../state/match_start_state.dart';
import '../lineup_picker.dart';


class MatchStartHeaderRow extends StatelessWidget {
  const MatchStartHeaderRow({required this.onBack, required this.title});
  final VoidCallback onBack;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
        ),
        Text(title, style: CkType.display(fontSize: 20)),
      ]),
    );
  }
}

class MatchStartHeader extends StatelessWidget {
  const MatchStartHeader({required this.state, required this.onBack});
  final MatchStartState state;
  final VoidCallback onBack;

  static const _stages = MatchStartPhase.values;

  int get _stageIndex {
    switch (state.phase) {
      case MatchStartPhase.toss:
        return 0;
      case MatchStartPhase.lineup:
        return 1;
      case MatchStartPhase.ready:
        return 2;
      case MatchStartPhase.live:
        return 2;
    }
  }

  String get _title {
    switch (state.phase) {
      case MatchStartPhase.toss:
        return 'The toss.';
      case MatchStartPhase.lineup:
        return state.viewerRole == MatchStartViewerRole.battingCaptain
            ? 'Pick your openers.'
            : 'Waiting on the batting team.';
      case MatchStartPhase.ready:
        return state.viewerRole == MatchStartViewerRole.battingCaptain
            ? 'Ready to start.'
            : 'Ready.';
      case MatchStartPhase.live:
        return 'Live.';
    }
  }

  String? get _countdown {
    final start = state.match.scheduledStartTime;
    if (start == null) return null;
    final delta = start.difference(DateTime.now());
    if (delta.isNegative && delta.inHours > -2) return 'STARTING NOW';
    if (delta.isNegative) return 'T+${(-delta.inMinutes)} MIN';
    if (delta.inHours > 1) return null;
    return 'T-${delta.inMinutes} MIN';
  }

  @override
  Widget build(BuildContext context) {
    final cd = _countdown;
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon:
                  const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
            ),
            const SizedBox(width: 4),
            Text(
              'MATCH START · ${_stageIndex + 1}/3',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: CkColors.muted,
              ),
            ),
            const Spacer(),
            if (cd != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: CkColors.redSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cd,
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.red,
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_stages.length - 1, (i) {
              final past = i < _stageIndex;
              final current = i == _stageIndex;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 1 ? 0 : 4),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: past
                          ? CkColors.green
                          : current
                              ? CkColors.ink
                              : const Color(0x1A14120E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            _title,
            style: CkType.display(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.025,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class MatchStartPhonePill extends ConsumerWidget {
  const MatchStartPhonePill({required this.state});
  final MatchStartState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = state.match;
    final yourTeamId = state.viewerRole == MatchStartViewerRole.battingCaptain
        ? state.battingTeamId
        : state.viewerRole == MatchStartViewerRole.bowlingCaptain
            ? state.bowlingTeamId
            : null;
    if (yourTeamId == null) return const SizedBox.shrink();
    final team = ref.watch(teamProvider(yourTeamId.value)).value;
    final role = state.viewerRole == MatchStartViewerRole.battingCaptain
        ? 'BATTING CAPTAIN'
        : state.viewerRole == MatchStartViewerRole.bowlingCaptain
            ? 'BOWLING CAPTAIN'
            : 'SPECTATOR';
    return Container(
      width: double.infinity,
      color: CkColors.paper2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          MatchStartMiniBadge(
              short: matchStartShortTeamName(team), color: matchStartTeamColor(team?.primaryColor)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${team?.name.toUpperCase() ?? 'YOUR TEAM'} · $role · THIS PHONE',
              overflow: TextOverflow.ellipsis,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.ink2,
              ),
            ),
          ),
          if (m.tossDecision != null) ...[
            const SizedBox(width: 8),
            Text(
              'TOSS ✓',
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MatchStartMiniBadge extends StatelessWidget {
  const MatchStartMiniBadge({required this.short, required this.color});
  final String short;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        short,
        style: CkType.display(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: CkColors.paper,
        ),
      ),
    );
  }
}

// ─── Stage 1: Toss ───────────────────────────────────────────────────────

class MatchStartStage1Toss extends ConsumerWidget {
  const MatchStartStage1Toss({
    required this.state,
    required this.onPickWinner,
    required this.onPickDecision,
  });

  final MatchStartState state;
  final ValueChanged<TeamId> onPickWinner;
  final ValueChanged<TossDecision> onPickDecision;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = state.match;
    final teamA = ref.watch(teamProvider(m.teamAId.value)).value;
    final teamB = ref.watch(teamProvider(m.teamBId.value)).value;
    if (!state.viewerCanAct) {
      return const Center(
        child: MatchStartWaitingCard(
          eyebrow: 'WAITING ON THE OTHER PHONE',
          title: 'The coin is on the captain’s phone.',
          body:
              'Both captains watch the toss together on one device. You’ll see the result here the moment it lands.',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      children: [
        Center(
          child: MatchStartCoinTile(face: m.tossFace),
        ),
        const SizedBox(height: 22),
        Text(
          'WHO WON THE TOSS?',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: MatchStartChoiceTile(
            label: teamA?.name ?? 'Team A',
            selected: state.pendingTossWinner == m.teamAId,
            onTap: () => onPickWinner(m.teamAId),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: MatchStartChoiceTile(
            label: teamB?.name ?? 'Team B',
            selected: state.pendingTossWinner == m.teamBId,
            onTap: () => onPickWinner(m.teamBId),
          )),
        ]),
        if (state.pendingTossWinner != null) ...[
          const SizedBox(height: 18),
          Text(
            'THEIR CALL',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: MatchStartChoiceTile(
                label: 'Bat first',
                selected: state.pendingDecision == TossDecision.bat,
                onTap: () => onPickDecision(TossDecision.bat),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MatchStartChoiceTile(
                label: 'Bowl first',
                selected: state.pendingDecision == TossDecision.bowl,
                onTap: () => onPickDecision(TossDecision.bowl),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

class MatchStartCoinTile extends StatefulWidget {
  const MatchStartCoinTile({this.face});
  final String? face;

  @override
  State<MatchStartCoinTile> createState() => _CoinTileState();
}

class _CoinTileState extends State<MatchStartCoinTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  String _face = 'H';

  @override
  void initState() {
    super.initState();
    _face = widget.face ?? 'H';
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _flip() async {
    if (_c.isAnimating) return;
    _c.forward(from: 0);
    // Quick interleave so the user sees a flip.
    Timer.periodic(const Duration(milliseconds: 110), (t) {
      if (!mounted || !_c.isAnimating) {
        t.cancel();
        return;
      }
      setState(() => _face = _face == 'H' ? 'T' : 'H');
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(t * 6.283 * 2),
            child: Container(
              width: 160,
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.ink,
                borderRadius: BorderRadius.circular(80),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3814120E),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Text(
                _face,
                style: CkType.display(
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  color: CkColors.paper,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MatchStartChoiceTile extends StatelessWidget {
  const MatchStartChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.paper,
          border: Border.all(
              color: selected ? CkColors.ink : CkColors.hairline, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: CkType.display(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Stage 2: Lineup ──────────────────────────────────────────────────────

class MatchStartStage2Lineup extends ConsumerWidget {
  const MatchStartStage2Lineup({
    required this.state,
    required this.onPickStriker,
    required this.onPickNonStriker,
  });

  final MatchStartState state;
  final ValueChanged<String> onPickStriker;
  final ValueChanged<String> onPickNonStriker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.viewerRole != MatchStartViewerRole.battingCaptain) {
      return const Center(
        child: MatchStartWaitingCard(
          eyebrow: 'WAITING ON THE BATTING CAPTAIN',
          title: 'They’re picking their openers.',
          body:
              'When ball 1 is bowled, the scoring screen prompts whoever has the ball. You don’t pre-pick a bowler.',
        ),
      );
    }

    final m = state.match;
    final lineupAsync = ref.watch(matchStartLineupProvider(m.id.value));

    return lineupAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (lineupState) {
        final shownStriker = state.pendingStriker ?? lineupState.lockedStriker;
        final shownNonStriker = state.pendingNonStriker ?? lineupState.lockedNonStriker;

        final byId = <String, RosterMember>{};
        for (final r in lineupState.players) {
          byId[r.member.playerId] = r;
        }

        // Selection mode: tap a player to fill striker first, then non-striker.
        final nextSlot = shownStriker == null
            ? 'striker'
            : shownNonStriker == null
                ? 'non'
                : 'striker';

        return Column(children: [
          MatchStartSlotsRow(
            strikerLabel:
                shownStriker == null ? null : byId[shownStriker]?.displayName,
            nonStrikerLabel: shownNonStriker == null
                ? null
                : byId[shownNonStriker]?.displayName,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: lineupState.players.length,
              itemBuilder: (_, i) {
                final p = lineupState.players[i];
                final isStriker = shownStriker == p.member.playerId;
                final isNon = shownNonStriker == p.member.playerId;
                return LineupRosterRow(
                  name: p.displayName,
                  jersey: p.member.jerseyNumber,
                  badge: isStriker ? 'STR' : (isNon ? 'NS' : null),
                  onTap: () {
                    if (nextSlot == 'striker') {
                      onPickStriker(p.member.playerId);
                    } else {
                      onPickNonStriker(p.member.playerId);
                    }
                  },
                );
              },
            ),
          ),
        ]);
      },
    );
  }
}

class MatchStartSlotsRow extends StatelessWidget {
  const MatchStartSlotsRow({this.strikerLabel, this.nonStrikerLabel});
  final String? strikerLabel;
  final String? nonStrikerLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(children: [
        Expanded(
          child: LineupSlotCard(
            label: 'ON STRIKE',
            value: strikerLabel,
            hot: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LineupSlotCard(
            label: 'NON-STRIKER',
            value: nonStrikerLabel,
          ),
        ),
      ]),
    );
  }
}

// ─── Stage 3: Ready ──────────────────────────────────────────────────────

class MatchStartStage3Ready extends ConsumerWidget {
  const MatchStartStage3Ready({required this.state});
  final MatchStartState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = state.match;
    final batting = state.battingTeamId;
    final bowling = state.bowlingTeamId;
    final teamA = ref.watch(teamProvider(m.teamAId.value)).value;
    final teamB = ref.watch(teamProvider(m.teamBId.value)).value;
    Team? teamFor(TeamId? id) {
      if (id == null) return null;
      if (id == m.teamAId) return teamA;
      if (id == m.teamBId) return teamB;
      return null;
    }

    final battingTeam = teamFor(batting);
    final bowlingTeam = teamFor(bowling);

    // Openers are persisted on match_innings_state for innings 1.
    // We resolve striker_id / non_striker_id (match_player_ids) back
    // to player_ref_ids for display.
    final inningsState =
        ref.watch(liveInningsStateProvider(m.id.value, 1)).value;
    final allMatchPlayers =
        ref.watch(matchPlayersProvider(m.id.value)).value ??
            const <MatchPlayer>[];
    String? refIdOf(String? matchPlayerId) {
      if (matchPlayerId == null) return null;
      for (final mp in allMatchPlayers) {
        if (mp.id.value == matchPlayerId) return mp.playerRefId;
      }
      return null;
    }

    final strikerId = refIdOf(inningsState?.strikerId?.value);
    final nonStrikerId = refIdOf(inningsState?.nonStrikerId?.value);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: [
        // Hero scoreboard preview.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FIRST BALL · OVER 0.1',
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: const Color(0xB3FDFAF4),
                  )),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Text(
                    battingTeam?.name ?? 'Batting',
                    style: CkType.display(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CkColors.paper,
                    ),
                  ),
                ),
                Text('0/0',
                    style: CkType.display(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: CkColors.paper,
                    )),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Text(
                    bowlingTeam?.name ?? 'Bowling',
                    style: CkType.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xB3FDFAF4),
                    ),
                  ),
                ),
                Text('—',
                    style: CkType.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xB3FDFAF4),
                    )),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        MatchStartSummary(
          tossLine: _tossLine(state),
          strikerName: strikerId,
          nonStrikerName: nonStrikerId,
          formatLine: _formatLine(m.format),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: state.viewerRole == MatchStartViewerRole.battingCaptain
                    ? CkColors.red
                    : CkColors.ink,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 20, color: CkColors.paper),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.viewerRole == MatchStartViewerRole.battingCaptain
                        ? 'You’re scoring this innings'
                        : 'You’re spectating this innings',
                    style: CkType.display(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.viewerRole == MatchStartViewerRole.battingCaptain
                        ? 'Your team is batting — you enter every ball.'
                        : 'See the live scoreboard. You score when your team bats.',
                    style: CkType.body(
                      fontSize: 11.5,
                      color: CkColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  String _tossLine(MatchStartState state) {
    final m = state.match;
    if (m.tossDecision == null || m.tossWonBy == null) return '';
    final won = m.tossWonBy == m.teamAId ? 'Team A' : 'Team B';
    return '$won · chose to ${m.tossDecision == TossDecision.bat ? 'bat' : 'bowl'}';
  }

  String _formatLine(MatchFormat f) =>
      'T${f.oversPerInnings} · ${f.playersPerTeam}-a-side · '
      '${f.ballType.name} ball';
}

class MatchStartSummary extends StatelessWidget {
  const MatchStartSummary({
    required this.tossLine,
    required this.strikerName,
    required this.nonStrikerName,
    required this.formatLine,
  });
  final String tossLine;
  final String? strikerName;
  final String? nonStrikerName;
  final String formatLine;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {Color? valueColor}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            SizedBox(
              width: 96,
              child: Text(label.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.muted,
                  )),
            ),
            Expanded(
              child: Text(
                value,
                style: CkType.body(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? CkColors.ink,
                ),
              ),
            ),
          ]),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        if (tossLine.isNotEmpty) row('Toss', tossLine),
        if (strikerName != null) row('On strike', strikerName!, valueColor: CkColors.red),
        if (nonStrikerName != null) row('Non-striker', nonStrikerName!),
        row('Opening bowler', 'Picked at ball 1', valueColor: CkColors.muted),
        row('Format', formatLine),
      ]),
    );
  }
}

// ─── Waiting / CTA ───────────────────────────────────────────────────────

class MatchStartWaitingCard extends StatelessWidget {
  const MatchStartWaitingCard({
    required this.eyebrow,
    required this.title,
    required this.body,
  });
  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const MatchStartPulseDot(),
          ),
          const SizedBox(height: 12),
          Text(eyebrow,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: CkColors.amber,
              )),
          const SizedBox(height: 6),
          Text(title,
              textAlign: TextAlign.center,
              style: CkType.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
              )),
          const SizedBox(height: 6),
          Text(body,
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 12,
                color: CkColors.muted,
                height: 1.45,
              )),
        ],
      ),
    );
  }
}

class MatchStartPulseDot extends StatefulWidget {
  const MatchStartPulseDot();

  @override
  State<MatchStartPulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<MatchStartPulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.35 + (_c.value * 0.65),
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: CkColors.amber,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class MatchStartCtaBar extends StatelessWidget {
  const MatchStartCtaBar({required this.state, required this.builder});
  final MatchStartState state;
  final Widget Function(MatchStartState) builder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: builder(state),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────

String matchStartShortTeamName(Team? t) {
  if (t == null) return '??';
  final mono = t.logoMonogram;
  if (mono != null && mono.isNotEmpty) return mono.toUpperCase();
  final letters = t.name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join();
  return letters.isEmpty ? '??' : letters.toUpperCase();
}

Color matchStartTeamColor(String? hex) {
  if (hex == null || hex.isEmpty) return CkColors.muted;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(0xFF000000 | n);
  } else if (cleaned.length == 8) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(n);
  }
  return CkColors.muted;
}
