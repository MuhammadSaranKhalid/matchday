import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/ck_button.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../../teams/presentation/providers/teams_providers.dart';
import '../../../domain/entities/match.dart';
import '../../controllers/match_start_controller.dart';
import '../../state/match_start_state.dart';
import '../challenge/ch_section_label.dart';
import 'match_start_atoms.dart';

/// Stage 1 — one atomic physical-toss form.
///
/// The controlling Cricket setup side/official records:
///   1. who won the toss, and
///   2. whether that winning side chose to bat or bowl.
///
/// Both facts are submitted together. There is no second-device decision step.
class MatchStartTossStage extends ConsumerWidget {
  const MatchStartTossStage({
    super.key,
    required this.matchId,
    required this.state,
  });

  final String matchId;
  final MatchStartState state;

  MatchStartController _controller(WidgetRef ref) =>
      ref.read(matchStartControllerProvider(matchId).notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = state.match;

    final teamA = ref.watch(teamProvider(match.teamAId.value)).value;

    final teamB = ref.watch(teamProvider(match.teamBId.value)).value;

    String nameOf(TeamId? id) {
      if (id == match.teamAId) {
        return teamA?.name ?? 'Team A';
      }

      if (id == match.teamBId) {
        return teamB?.name ?? 'Team B';
      }

      return 'Team';
    }

    if (!state.canRecordToss) {
      final setupTeamId = match.setupTeamId;

      final neutral = setupTeamId == null;

      return Center(
        child: MatchStartWaitingCard(
          eyebrow:
              neutral
                  ? 'WAITING ON THE MATCH OFFICIAL'
                  : 'WAITING ON THE CRICKET SETUP TEAM',
          title:
              neutral
                  ? 'The assigned official will record the toss.'
                  : '${nameOf(setupTeamId)} is running the toss.',
          body:
              neutral
                  ? 'They’ll record who won and whether the winner chose to bat or bowl.'
                  : 'The setup-side member will ask the winning side whether they want to bat or bowl, then submit both details here.',
        ),
      );
    }

    final winner = state.pendingTossWinner;

    final decision = state.pendingDecision;

    final batting = state.pendingBattingTeamId;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            children: [
              Center(child: MatchStartCoinTile(face: match.tossFace)),
              const SizedBox(height: 22),

              const ChSectionLabel('Who won the toss?'),
              Row(
                children: [
                  Expanded(
                    child: MatchStartChoiceTile(
                      label: nameOf(match.teamAId),
                      selected: winner == match.teamAId,
                      onTap:
                          () => _controller(ref).pickTossWinner(match.teamAId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MatchStartChoiceTile(
                      label: nameOf(match.teamBId),
                      selected: winner == match.teamBId,
                      onTap:
                          () => _controller(ref).pickTossWinner(match.teamBId),
                    ),
                  ),
                ],
              ),

              if (winner != null) ...[
                const SizedBox(height: 22),
                ChSectionLabel('What did ${nameOf(winner)} choose?'),
                Row(
                  children: [
                    Expanded(
                      child: MatchStartChoiceTile(
                        label: 'Bat first',
                        selected: decision == TossDecision.bat,
                        onTap:
                            () => _controller(
                              ref,
                            ).pickTossDecision(TossDecision.bat),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MatchStartChoiceTile(
                        label: 'Bowl first',
                        selected: decision == TossDecision.bowl,
                        onTap:
                            () => _controller(
                              ref,
                            ).pickTossDecision(TossDecision.bowl),
                      ),
                    ),
                  ],
                ),
              ],

              if (winner != null && decision != null && batting != null) ...[
                const SizedBox(height: 22),
                _TossSummary(
                  winnerName: nameOf(winner),
                  decision: decision,
                  battingName: nameOf(batting),
                ),
              ],
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: CkColors.paper,
            border: Border(top: BorderSide(color: CkColors.hairline)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: CkButton(
            label: 'Confirm toss → lineup',
            busy: state.isBusy,
            onPressed:
                state.isTossReady
                    ? () async {
                      final res = await _controller(ref).submitToss();

                      if (!context.mounted) {
                        return;
                      }

                      res.fold(
                        (failure) => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(failure.message)),
                        ),
                        (_) {},
                      );
                    }
                    : null,
          ),
        ),
      ],
    );
  }
}

class _TossSummary extends StatelessWidget {
  const _TossSummary({
    required this.winnerName,
    required this.decision,
    required this.battingName,
  });

  final String winnerName;
  final TossDecision decision;
  final String battingName;

  @override
  Widget build(BuildContext context) {
    final decisionLabel = decision == TossDecision.bat ? 'bat' : 'bowl';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$winnerName won the toss and chose to $decisionLabel.',
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$battingName will bat first.',
            style: CkType.body(fontSize: 13, color: CkColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Cosmetic coin only. The authoritative toss result is what the Cricket setup side/official
/// records in the form.
class MatchStartCoinTile extends StatefulWidget {
  const MatchStartCoinTile({super.key, this.face});

  final String? face;

  @override
  State<MatchStartCoinTile> createState() => _MatchStartCoinTileState();
}

class _MatchStartCoinTileState extends State<MatchStartCoinTile>
    with SingleTickerProviderStateMixin {
  static const _spinDuration = Duration(milliseconds: 1300);

  static const _faceSwapInterval = Duration(milliseconds: 110);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _spinDuration,
  );

  Timer? _faceTimer;

  late String _face = widget.face ?? 'H';

  @override
  void dispose() {
    _faceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) {
      return;
    }

    _controller.forward(from: 0);

    _faceTimer?.cancel();

    _faceTimer = Timer.periodic(_faceSwapInterval, (timer) {
      if (!_controller.isAnimating) {
        timer.cancel();
        return;
      }

      setState(() {
        _face = _face == 'H' ? 'T' : 'H';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder:
            (context, child) => Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(_controller.value * 4 * 3.1415926535),
              child: child,
            ),
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
          child: _CoinFace(face: _face),
        ),
      ),
    );
  }
}

class _CoinFace extends StatelessWidget {
  const _CoinFace({required this.face});

  final String face;

  @override
  Widget build(BuildContext context) {
    return Text(
      face,
      style: CkType.display(
        fontSize: 46,
        fontWeight: FontWeight.w700,
        color: CkColors.paper,
      ),
    );
  }
}
