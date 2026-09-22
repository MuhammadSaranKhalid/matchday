import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/match.dart';
import '../../../domain/entities/match_player.dart';
import '../../controllers/match_room_controller.dart';
import '../../state/match_room_state.dart';
import 'add_match_player_sheet.dart';

class MatchRoomBody extends ConsumerStatefulWidget {
  const MatchRoomBody({super.key, required this.matchId, required this.state});

  final String matchId;
  final MatchRoomState state;

  @override
  ConsumerState<MatchRoomBody> createState() => _MatchRoomBodyState();
}

class _MatchRoomBodyState extends ConsumerState<MatchRoomBody> {
  String? _tossWinner;
  TossDecision? _decision;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final match = state.snapshot.match;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed:
                      () =>
                          context.canPop()
                              ? context.pop()
                              : context.go('/my/matches'),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('Match hub', style: CkType.display(fontSize: 20)),
                const Spacer(),
                if (state.isRefreshing || state.isCommandPending)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          if (!state.isRealtimeConnected || state.nonBlockingError != null)
            MaterialBanner(
              content: Text(
                !state.isRealtimeConnected
                    ? 'Reconnecting. The last confirmed match state is still shown.'
                    : 'Could not refresh. The last confirmed match state is still shown.',
              ),
              actions: [
                TextButton(
                  onPressed:
                      () =>
                          ref
                              .read(
                                matchRoomControllerProvider(
                                  widget.matchId,
                                ).notifier,
                              )
                              .refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(
            child: switch (match.startPhase) {
              MatchStartPhase.toss => _toss(state),
              MatchStartPhase.lineup || MatchStartPhase.ready => _lineup(state),
              MatchStartPhase.live => const Center(
                child: Text('Match is live. Opening scoring…'),
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _toss(MatchRoomState state) {
    final match = state.snapshot.match;
    if (!state.snapshot.capabilities.canRecordToss) {
      return const _Waiting(
        title: 'Waiting for the toss',
        body: 'The authorized setup phone will record the toss here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Who won the toss?', style: CkType.display(fontSize: 22)),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: match.teamAId.value,
              label: const Text('Team A'),
            ),
            ButtonSegment(
              value: match.teamBId.value,
              label: const Text('Team B'),
            ),
          ],
          emptySelectionAllowed: true,
          selected: _tossWinner == null ? const {} : {_tossWinner!},
          onSelectionChanged:
              (value) => setState(() => _tossWinner = value.first),
        ),
        const SizedBox(height: 18),
        SegmentedButton<TossDecision>(
          segments: const [
            ButtonSegment(value: TossDecision.bat, label: Text('Bat')),
            ButtonSegment(value: TossDecision.bowl, label: Text('Bowl')),
          ],
          emptySelectionAllowed: true,
          selected: _decision == null ? const {} : {_decision!},
          onSelectionChanged:
              (value) => setState(() => _decision = value.first),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed:
              _tossWinner == null || _decision == null || state.isCommandPending
                  ? null
                  : () => ref
                      .read(
                        matchRoomControllerProvider(widget.matchId).notifier,
                      )
                      .submitToss(
                        wonByTeamId: _tossWinner!,
                        decision: _decision!,
                      ),
          child: const Text('Confirm toss'),
        ),
      ],
    );
  }

  Widget _lineup(MatchRoomState state) {
    final snapshot = state.snapshot;
    final battingId = snapshot.match.battingFirstTeamId;
    final battingSide =
        battingId == snapshot.match.teamBId ? MatchTeamSide.b : MatchTeamSide.a;

    // A false capability is an authorization result, not evidence that some
    // particular phone currently owns a scorer lease. The previous copy said
    // "the active scorer" even when no lease existed, which made two waiting
    // phones look like a realtime failure. Name the authoritative batting side
    // instead: after the toss, that side's effective `match.score` permission
    // determines who can commit BOTH openers and the opposing opening bowler.
    if (!snapshot.capabilities.canSetupInnings) {
      final battingSideLabel =
          battingSide == MatchTeamSide.a ? 'Team A' : 'Team B';
      return _Waiting(
        title: 'Waiting for $battingSideLabel lineup',
        body:
            'A scorer authorized for the batting team must select both openers and the opening bowler.',
      );
    }
    final bowlingSide =
        battingSide == MatchTeamSide.a ? MatchTeamSide.b : MatchTeamSide.a;
    final batters =
        snapshot.participants.where((p) => p.teamSide == battingSide).toList();
    final bowlers =
        snapshot.participants.where((p) => p.teamSide == bowlingSide).toList();
    final controller = ref.read(
      matchRoomControllerProvider(widget.matchId).notifier,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Opening players', style: CkType.display(fontSize: 22)),
        const SizedBox(height: 6),
        Text(
          'Select the on-strike batter, non-striker, and opening bowler together.',
          style: CkType.body(fontSize: 13, color: CkColors.muted),
        ),
        const SizedBox(height: 18),
        _PlayerDropdown(
          label: 'On strike',
          value: state.selectedStrikerId,
          players: batters,
          onChanged: controller.selectStriker,
        ),
        const SizedBox(height: 12),
        _PlayerDropdown(
          label: 'Non-striker',
          value: state.selectedNonStrikerId,
          players: batters,
          onChanged: controller.selectNonStriker,
        ),
        const SizedBox(height: 12),
        _PlayerDropdown(
          label: 'Opening bowler',
          value: state.selectedBowlerId,
          players: bowlers,
          onChanged: controller.selectBowler,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed:
              snapshot.capabilities.canAddParticipant
                  ? () => _showAddPlayer(controller)
                  : null,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Add player for this match'),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed:
              state.selectedStrikerId == null ||
                      state.selectedNonStrikerId == null ||
                      state.selectedBowlerId == null ||
                      state.selectedStrikerId == state.selectedNonStrikerId ||
                      state.isCommandPending
                  ? null
                  : controller.startMatch,
          child: const Text('Start match — first ball'),
        ),
      ],
    );
  }

  Future<void> _showAddPlayer(MatchRoomController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (sheetContext) => AddMatchPlayerSheet(
            onSubmit: (side, name) async {
              final result = await controller.addParticipant(
                side: side,
                displayName: name,
              );
              if (!sheetContext.mounted) return;
              result.fold(
                (failure) => ScaffoldMessenger.of(
                  sheetContext,
                ).showSnackBar(SnackBar(content: Text(failure.message))),
                (_) => Navigator.of(sheetContext).pop(),
              );
            },
          ),
    );
  }
}

class _PlayerDropdown extends StatelessWidget {
  const _PlayerDropdown({
    required this.label,
    required this.value,
    required this.players,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<MatchPlayer> players;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final player in players)
          DropdownMenuItem(
            value: player.id.value,
            child: Text(player.displayName),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: CkType.display(fontSize: 22)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
