import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../../domain/usecases/start_match.dart';
import '../providers/matches_providers.dart';

/// Single-phone match start: toss → opening pair → opening bowler → start.
/// (Two-phone choreography and match-conditions are v1.1.)
class MatchStartScreen extends ConsumerStatefulWidget {
  const MatchStartScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<MatchStartScreen> createState() => _MatchStartScreenState();
}

class _MatchStartScreenState extends ConsumerState<MatchStartScreen> {
  bool? _tossWonByA; // true = team A won the toss
  TossDecision? _decision;
  final List<String> _batters = []; // ordered: [striker, nonStriker]
  String? _bowlerId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchProvider(widget.matchId));
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (async) {
          AsyncData(:final value?) => _body(value),
          AsyncData() => const Center(child: Text('Match not found')),
          AsyncError() => const Center(child: Text('Could not load match')),
          _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
        },
      ),
    );
  }

  Widget _body(Match match) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
        ),
        Text('Start match', style: CkType.display(fontSize: 20)),
      ]),
    );

    if (match.status != MatchStatus.accepted) {
      return Column(children: [
        header,
        const Expanded(
            child: Center(child: Text('This match is not ready to start.'))),
      ]);
    }

    final teamA = ref.watch(teamProvider(match.teamAId.value)).value;
    final teamB = ref.watch(teamProvider(match.teamBId.value)).value;
    final nameA = teamA?.name ?? 'Team A';
    final nameB = teamB?.name ?? 'Team B';

    // Derived sides (null until toss is fully chosen).
    final tossDecided = _tossWonByA != null && _decision != null;
    final battingIsA = tossDecided &&
        ((_tossWonByA! && _decision == TossDecision.bat) ||
            (!_tossWonByA! && _decision == TossDecision.bowl));
    final battingTeamId = battingIsA ? match.teamAId : match.teamBId;
    final bowlingTeamId = battingIsA ? match.teamBId : match.teamAId;
    final battingSquad = battingIsA ? match.teamASquad : match.teamBSquad;
    final bowlingSquad = battingIsA ? match.teamBSquad : match.teamASquad;

    final canStart =
        tossDecided && _batters.length == 2 && _bowlerId != null;

    return Column(
      children: [
        header,
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            children: [
              const _SectionTitle('1 · Toss'),
              Text('Who won the toss?',
                  style: CkType.body(fontSize: 14, color: CkColors.muted)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _Pick(
                    label: nameA,
                    active: _tossWonByA == true,
                    onTap: () => setState(() {
                      _tossWonByA = true;
                      _resetSelections();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Pick(
                    label: nameB,
                    active: _tossWonByA == false,
                    onTap: () => setState(() {
                      _tossWonByA = false;
                      _resetSelections();
                    }),
                  ),
                ),
              ]),
              if (_tossWonByA != null) ...[
                const SizedBox(height: 12),
                Text('They chose to…',
                    style: CkType.body(fontSize: 14, color: CkColors.muted)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _Pick(
                      label: 'Bat',
                      active: _decision == TossDecision.bat,
                      onTap: () => setState(() {
                        _decision = TossDecision.bat;
                        _resetSelections();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Pick(
                      label: 'Bowl',
                      active: _decision == TossDecision.bowl,
                      onTap: () => setState(() {
                        _decision = TossDecision.bowl;
                        _resetSelections();
                      }),
                    ),
                  ),
                ]),
              ],
              if (tossDecided) ...[
                const SizedBox(height: 22),
                const _SectionTitle('2 · Opening pair'),
                Text('Pick striker, then non-striker.',
                    style: CkType.body(fontSize: 14, color: CkColors.muted)),
                const SizedBox(height: 10),
                _PlayerPicks(
                  teamId: battingTeamId.value,
                  squad: battingSquad,
                  selected: _batters,
                  badgeFor: (id) => _batters.isNotEmpty && _batters[0] == id
                      ? 'STRIKER'
                      : (_batters.length > 1 && _batters[1] == id
                          ? 'NON-STRIKER'
                          : null),
                  onTap: (id) => setState(() => _toggleBatter(id)),
                ),
                const SizedBox(height: 22),
                const _SectionTitle('3 · Opening bowler'),
                Text('From $nameA / $nameB — the fielding side.',
                    style: CkType.body(fontSize: 13, color: CkColors.muted)),
                const SizedBox(height: 10),
                _PlayerPicks(
                  teamId: bowlingTeamId.value,
                  squad: bowlingSquad,
                  selected: _bowlerId == null ? const [] : [_bowlerId!],
                  badgeFor: (_) => null,
                  onTap: (id) =>
                      setState(() => _bowlerId = _bowlerId == id ? null : id),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: CkButton(
            label: 'Start match',
            busy: _busy,
            onPressed: canStart ? () => _start(match) : null,
          ),
        ),
      ],
    );
  }

  void _resetSelections() {
    _batters.clear();
    _bowlerId = null;
  }

  void _toggleBatter(String id) {
    if (_batters.contains(id)) {
      _batters.remove(id);
    } else if (_batters.length < 2) {
      _batters.add(id);
    }
  }

  Future<void> _start(Match match) async {
    setState(() => _busy = true);
    final result = await ref.read(startMatchUseCaseProvider).call(
          StartMatchParams(
            match: match,
            tossWonBy: _tossWonByA! ? match.teamAId : match.teamBId,
            tossDecision: _decision!,
            strikerId: _batters[0],
            nonStrikerId: _batters[1],
            bowlerId: _bowlerId!,
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (innings) {
        // Straight into ball-by-ball scoring.
        context.go('/matches/${match.id.value}/score/${innings.id.value}');
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: CkType.display(fontSize: 18)),
      );
}

class _Pick extends StatelessWidget {
  const _Pick({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? CkColors.ink : CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.sm),
            border: Border.all(
                color: active ? CkColors.ink : CkColors.line, width: 1.5),
          ),
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? CkColors.paper : CkColors.ink)),
        ),
      );
}

/// Renders the [squad] of [teamId] as tappable rows, resolving names from the
/// team's roster. A [badgeFor] callback labels selected rows (e.g. STRIKER).
class _PlayerPicks extends ConsumerWidget {
  const _PlayerPicks({
    required this.teamId,
    required this.squad,
    required this.selected,
    required this.badgeFor,
    required this.onTap,
  });

  final String teamId;
  final List<String> squad;
  final List<String> selected;
  final String? Function(String id) badgeFor;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(rosterProvider(teamId));
    final names = <String, String>{
      for (final RosterMember m in (roster.value ?? const []))
        m.member.playerId: m.displayName,
    };
    return Column(
      children: [
        for (final id in squad)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PlayerRow(
              name: names[id] ?? 'Player',
              selected: selected.contains(id),
              badge: badgeFor(id),
              onTap: () => onTap(id),
            ),
          ),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.name,
    required this.selected,
    required this.badge,
    required this.onTap,
  });
  final String name;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? CkColors.paper2 : CkColors.surface,
          borderRadius: BorderRadius.circular(CkRadii.sm),
          border: Border.all(
              color: selected ? CkColors.ink : CkColors.hairline,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? CkColors.ink : CkColors.soft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style:
                      CkType.body(fontSize: 15, fontWeight: FontWeight.w500)),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CkColors.ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge!,
                    style: CkType.mono(fontSize: 9, color: CkColors.paper)),
              ),
          ],
        ),
      ),
    );
  }
}
