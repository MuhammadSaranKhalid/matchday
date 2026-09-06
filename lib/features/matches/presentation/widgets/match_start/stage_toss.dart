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

/// Stage 1 — the toss, in two acts.
///
/// The match creator records who won it; the winning side's captain then
/// makes the call. Everyone else waits — including the creator, once they
/// have done their one part.
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
      if (id == match.teamAId) return teamA?.name ?? 'Team A';
      if (id == match.teamBId) return teamB?.name ?? 'Team B';
      return 'The toss winner';
    }

    if (!state.viewerCanAct) {
      return Center(
        child: switch (state.tossStep) {
          TossStep.winner => const MatchStartWaitingCard(
              eyebrow: 'WAITING ON THE MATCH CREATOR',
              title: 'The coin is with whoever set this match up.',
              body: 'They record who won it. You’ll see the result here the '
                  'moment it lands.',
            ),
          TossStep.decision => MatchStartWaitingCard(
              eyebrow: 'WAITING ON THE TOSS WINNER',
              title: '${nameOf(state.tossWinnerTeamId)} won the toss.',
              body: 'Their captain is choosing whether to bat or bowl.',
            ),
        },
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            children: [
              Center(child: MatchStartCoinTile(face: match.tossFace)),
              const SizedBox(height: 22),
              ...switch (state.tossStep) {
                TossStep.winner => [
                    const ChSectionLabel('Who won the toss?'),
                    Row(
                      children: [
                        Expanded(
                          child: MatchStartChoiceTile(
                            label: nameOf(match.teamAId),
                            selected: state.pendingTossWinner == match.teamAId,
                            onTap: () =>
                                _controller(ref).pickTossWinner(match.teamAId),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MatchStartChoiceTile(
                            label: nameOf(match.teamBId),
                            selected: state.pendingTossWinner == match.teamBId,
                            onTap: () =>
                                _controller(ref).pickTossWinner(match.teamBId),
                          ),
                        ),
                      ],
                    ),
                  ],
                TossStep.decision => [
                    ChSectionLabel(
                      '${nameOf(state.tossWinnerTeamId)} won — your call',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: MatchStartChoiceTile(
                            label: 'Bat first',
                            selected:
                                state.pendingDecision == TossDecision.bat,
                            onTap: () => _controller(ref)
                                .pickTossDecision(TossDecision.bat),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MatchStartChoiceTile(
                            label: 'Bowl first',
                            selected:
                                state.pendingDecision == TossDecision.bowl,
                            onTap: () => _controller(ref)
                                .pickTossDecision(TossDecision.bowl),
                          ),
                        ),
                      ],
                    ),
                  ],
              },
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
            label: switch (state.tossStep) {
              TossStep.winner => 'Record the toss',
              TossStep.decision => 'Continue → lineup',
            },
            busy: state.isBusy,
            onPressed: state.isTossReady
                ? () async {
                    final controller = _controller(ref);
                    final res = switch (state.tossStep) {
                      TossStep.winner => await controller.submitTossWinner(),
                      TossStep.decision =>
                        await controller.submitTossDecision(),
                    };
                    if (!context.mounted) return;
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

/// Tappable coin. Cosmetic only — the recorded outcome is whatever the
/// captains enter below it, not what this lands on.
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
    if (_controller.isAnimating) return;
    _controller.forward(from: 0);
    _faceTimer?.cancel();
    _faceTimer = Timer.periodic(_faceSwapInterval, (timer) {
      if (!_controller.isAnimating) {
        timer.cancel();
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
