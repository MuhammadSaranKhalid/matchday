import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_player.dart';
import '../providers/matches_providers.dart';
import 'result_screen.dart' show battingFirstIsTeamA;

/// Innings break: shows the chase target and lets the batting captain pick the
/// second-innings openers + opening bowler, then starts the chase.
class InningsBreakScreen extends ConsumerStatefulWidget {
  const InningsBreakScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<InningsBreakScreen> createState() => _InningsBreakScreenState();
}

class _InningsBreakScreenState extends ConsumerState<InningsBreakScreen> {
  String? _strikerId;
  String? _nonStrikerId;
  String? _bowlerId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(liveMatchProvider(widget.matchId)).value;
    if (match == null) {
      return const Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: CircularProgressIndicator(color: CkColors.ink)),
      );
    }
    final inns1 = ref.watch(liveInningsStateProvider(widget.matchId, 1)).value;
    final players = ref.watch(matchPlayersProvider(widget.matchId)).value ??
        const <MatchPlayer>[];
    final rosterA = ref.watch(rosterProvider(match.teamAId.value)).value ??
        const <RosterMember>[];
    final rosterB = ref.watch(rosterProvider(match.teamBId.value)).value ??
        const <RosterMember>[];
    final names = <String, String>{
      for (final m in rosterA) m.member.playerId: m.displayName,
      for (final m in rosterB) m.member.playerId: m.displayName,
    };
    String nameOf(MatchPlayer p) =>
        names[p.playerRefId] ?? 'Player ${p.id.value.substring(0, 4)}';

    // Team A batting first => team B bats the 2nd innings, and vice versa.
    final battingSide =
        battingFirstIsTeamA(match) ? MatchTeamSide.b : MatchTeamSide.a;
    final batters =
        players.where((p) => p.teamSide == battingSide).toList()
          ..sort((a, b) => (a.battingOrder ?? 99).compareTo(b.battingOrder ?? 99));
    final bowlers =
        players.where((p) => p.teamSide != battingSide).toList();

    final target = (inns1?.totalRuns ?? 0) + 1;
    final ready = _strikerId != null &&
        _nonStrikerId != null &&
        _bowlerId != null &&
        _strikerId != _nonStrikerId &&
        !_busy;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Text('INNINGS BREAK', style: CkType.mono(fontSize: 12)),
            const SizedBox(height: 10),
            Text('Target $target', style: CkType.display(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              inns1 == null
                  ? ''
                  : 'Chasing ${inns1.totalRuns}/${inns1.totalWickets}',
              style: CkType.body(fontSize: 14, color: CkColors.muted),
            ),
            const SizedBox(height: 28),
            _PickerField(
              label: 'Striker',
              players: batters,
              value: _strikerId,
              nameOf: nameOf,
              disabledId: _nonStrikerId,
              onChanged: (v) => setState(() => _strikerId = v),
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: 'Non-striker',
              players: batters,
              value: _nonStrikerId,
              nameOf: nameOf,
              disabledId: _strikerId,
              onChanged: (v) => setState(() => _nonStrikerId = v),
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: 'Opening bowler',
              players: bowlers,
              value: _bowlerId,
              nameOf: nameOf,
              onChanged: (v) => setState(() => _bowlerId = v),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: ready ? () => _start(target) : null,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: CkColors.paper,
                      ),
                    )
                  : const Text('Start the chase'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(int target) async {
    setState(() => _busy = true);
    final result = await ref.read(matchesRepositoryProvider).startInnings(
          matchId: MatchId(widget.matchId),
          inningsNumber: 2,
          strikerId: _strikerId!,
          nonStrikerId: _nonStrikerId!,
          bowlerId: _bowlerId!,
          target: target,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) => context.go('/matches/${widget.matchId}/score?innings=2'),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.players,
    required this.value,
    required this.nameOf,
    required this.onChanged,
    this.disabledId,
  });
  final String label;
  final List<MatchPlayer> players;
  final String? value;
  final String? disabledId;
  final String Function(MatchPlayer) nameOf;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label.toUpperCase(), style: CkType.mono(fontSize: 11)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                'Select…',
                style: CkType.body(fontSize: 15, color: CkColors.soft),
              ),
              items: [
                for (final p in players)
                  DropdownMenuItem(
                    value: p.id.value,
                    enabled: p.id.value != disabledId,
                    child: Text(
                      nameOf(p),
                      style: CkType.body(
                        fontSize: 15,
                        color: p.id.value == disabledId
                            ? CkColors.soft
                            : CkColors.ink,
                      ),
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
