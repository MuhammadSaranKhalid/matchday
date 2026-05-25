import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../controllers/match_setup_controller.dart';
import '../state/match_setup_state.dart';

/// 6-step propose-a-friendly wizard for a given team A.
class MatchSetupScreen extends ConsumerWidget {
  const MatchSetupScreen({super.key, required this.teamAId});
  final String teamAId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = matchSetupControllerProvider(teamAId);

    ref.listen(provider, (prev, next) {
      final s = next.value;
      if (s == null) return;
      if (s.createdMatchId != null && prev?.value?.createdMatchId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent — awaiting reply')),
        );
        context.go('/matches');
      } else if (s.submitError != null &&
          prev?.value?.submitError != s.submitError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.submitError!)));
      }
    });

    final async = ref.watch(provider);
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (async) {
          AsyncData(:final value) =>
            _Wizard(teamAId: teamAId, state: value),
          _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
        },
      ),
    );
  }
}

class _Wizard extends ConsumerWidget {
  const _Wizard({required this.teamAId, required this.state});
  final String teamAId;
  final MatchSetupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(matchSetupControllerProvider(teamAId).notifier);
    final i = state.step.index;
    final isLast = state.step == MatchSetupStep.review;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => i == 0 ? context.pop() : c.back(),
                icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
              ),
              Expanded(
                child: Text(
                  'NEW MATCH · ${i + 1}/${MatchSetupStep.values.length}',
                  textAlign: TextAlign.center,
                  style: CkType.mono(fontSize: 11, color: CkColors.muted),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        _Progress(active: i),
        Expanded(
          child: switch (state.step) {
            MatchSetupStep.type => const _TypeStep(),
            MatchSetupStep.opponent =>
              _OpponentStep(teamAId: teamAId, state: state, c: c),
            MatchSetupStep.format => _FormatStep(state: state, c: c),
            MatchSetupStep.whenWhere => _WhenWhereStep(state: state, c: c),
            MatchSetupStep.scorer => const _ScorerStep(),
            MatchSetupStep.pickXi =>
              _PickXiStep(teamAId: teamAId, state: state, c: c),
            MatchSetupStep.review => _ReviewStep(state: state),
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: CkButton(
            label: isLast ? 'Send request' : 'Continue',
            busy: state.submitting,
            onPressed: _canAdvance(state) ? (isLast ? c.submit : c.next) : null,
          ),
        ),
      ],
    );
  }

  bool _canAdvance(MatchSetupState s) => switch (s.step) {
        MatchSetupStep.opponent => s.canPickOpponent,
        MatchSetupStep.format => s.canFormat,
        MatchSetupStep.whenWhere => s.canWhenWhere,
        MatchSetupStep.pickXi => s.xiComplete,
        _ => true,
      };
}

class _Progress extends StatelessWidget {
  const _Progress({required this.active});
  final int active;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Row(
          children: [
            for (var i = 0; i < MatchSetupStep.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= active ? CkColors.ink : CkColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

// ─── Step 1: Type ─────────────────────────────────────────────────────────────

class _TypeStep extends StatelessWidget {
  const _TypeStep();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
        children: [
          Text('What kind of match?', style: CkType.display(fontSize: 26)),
          const SizedBox(height: 18),
          _SelectableCard(
            title: 'Friendly',
            subtitle: 'One-off match between two teams. Stats count.',
            selected: true,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _SelectableCard(
            title: 'Tournament',
            subtitle: 'Coming soon',
            selected: false,
            disabled: true,
            onTap: () {},
          ),
        ],
      );
}

// ─── Step 2: Opponent ─────────────────────────────────────────────────────────

class _OpponentStep extends ConsumerWidget {
  const _OpponentStep(
      {required this.teamAId, required this.state, required this.c});
  final String teamAId;
  final MatchSetupState state;
  final MatchSetupController c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(allTeamsProvider);
    return switch (teams) {
      AsyncData(:final value) => Builder(builder: (_) {
          final opponents =
              value.where((t) => t.id.value != teamAId).toList();
          if (opponents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'No other teams found yet. Opponent teams appear here once '
                  'they exist and sync.',
                  textAlign: TextAlign.center,
                  style: CkType.body(fontSize: 14, color: CkColors.muted),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            children: [
              Text('Pick your opponent', style: CkType.display(fontSize: 26)),
              const SizedBox(height: 18),
              for (final t in opponents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SelectableCard(
                    title: t.name,
                    subtitle: [
                      t.type.name,
                      if (t.city != null && t.city!.isNotEmpty) t.city!,
                    ].join(' · '),
                    selected: state.opponentId == t.id.value,
                    onTap: () => c.pickOpponent(t.id.value, t.name),
                  ),
                ),
            ],
          );
        }),
      _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
    };
  }
}

// ─── Step 3: Format ─────────────────────────────────────────────────────────

class _FormatStep extends StatelessWidget {
  const _FormatStep({required this.state, required this.c});
  final MatchSetupState state;
  final MatchSetupController c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      children: [
        Text('Match format', style: CkType.display(fontSize: 26)),
        const SizedBox(height: 18),
        const _Label('Overs per innings'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in [10, 20, 40, 50])
              _Chip(
                label: 'T$o',
                active: state.overs == o,
                onTap: () => c.setOvers(o),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const _Label('Ball type'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final b in MatchBallType.values)
              _Chip(
                label: b.name[0].toUpperCase() + b.name.substring(1),
                active: state.ballType == b,
                onTap: () => c.setBallType(b),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const _Label('Players a side'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in [6, 7, 8, 11])
              _Chip(
                label: '$n',
                active: state.playersPerTeam == n,
                onTap: () => c.setPlayersPerTeam(n),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Label('Max overs per bowler'),
            Text('${state.maxOversPerBowler}',
                style: CkType.display(fontSize: 18)),
          ],
        ),
      ],
    );
  }
}

// ─── Step 4: When & where ─────────────────────────────────────────────────────

class _WhenWhereStep extends StatefulWidget {
  const _WhenWhereStep({required this.state, required this.c});
  final MatchSetupState state;
  final MatchSetupController c;

  @override
  State<_WhenWhereStep> createState() => _WhenWhereStepState();

  static String _fmt(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} · $h:$mm $ap';
  }
}

class _WhenWhereStepState extends State<_WhenWhereStep> {
  late final TextEditingController _ground =
      TextEditingController(text: widget.state.venueGround);
  late final TextEditingController _city =
      TextEditingController(text: widget.state.venueCity);

  @override
  void dispose() {
    _ground.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final c = widget.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      children: [
        Text('When & where', style: CkType.display(fontSize: 26)),
        const SizedBox(height: 18),
        const _Label('Date & time'),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickDateTime(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: CkColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.line, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_outlined, size: 20, color: CkColors.muted),
                const SizedBox(width: 10),
                Text(
                  state.when == null
                      ? 'Pick a date & time'
                      : _WhenWhereStep._fmt(state.when!),
                  style: CkType.body(
                    fontSize: 16,
                    color: state.when == null ? CkColors.soft : CkColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _Label('Ground'),
        const SizedBox(height: 8),
        TextField(
          controller: _ground,
          onChanged: c.setVenueGround,
          textCapitalization: TextCapitalization.words,
          style: CkType.body(fontSize: 16),
          decoration: const InputDecoration(hintText: 'Gaddafi B Ground'),
        ),
        const SizedBox(height: 18),
        const _Label('City (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _city,
          onChanged: c.setVenueCity,
          textCapitalization: TextCapitalization.words,
          style: CkType.body(fontSize: 16),
          decoration: const InputDecoration(hintText: 'Lahore'),
        ),
      ],
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: widget.state.when ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 16, minute: 0),
    );
    if (time == null) return;
    widget.c
        .setWhen(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}

// ─── Step 5: Scorer ─────────────────────────────────────────────────────────

class _ScorerStep extends StatelessWidget {
  const _ScorerStep();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
        children: [
          Text('Who scores?', style: CkType.display(fontSize: 26)),
          const SizedBox(height: 18),
          _SelectableCard(
            title: 'Me',
            subtitle: 'You run the scoring app for this match.',
            selected: true,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _SelectableCard(
            title: 'Someone from my team',
            subtitle: 'Coming soon',
            selected: false,
            disabled: true,
            onTap: () {},
          ),
        ],
      );
}

// ─── Step 6: Pick XI ─────────────────────────────────────────────────────────

class _PickXiStep extends ConsumerWidget {
  const _PickXiStep(
      {required this.teamAId, required this.state, required this.c});
  final String teamAId;
  final MatchSetupState state;
  final MatchSetupController c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(rosterProvider(teamAId));
    return switch (roster) {
      AsyncData(:final value) => _build(context, value),
      _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
    };
  }

  Widget _build(BuildContext context, List<RosterMember> members) {
    if (members.length < state.playersPerTeam) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_off_outlined,
                  size: 52, color: CkColors.soft),
              const SizedBox(height: 14),
              Text("Your squad doesn't have enough players",
                  textAlign: TextAlign.center,
                  style: CkType.display(fontSize: 20)),
              const SizedBox(height: 6),
              Text(
                '${members.length} of ${state.playersPerTeam} needed. Add more '
                'players in Team manage, or pick a smaller format.',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 14, color: CkColors.muted),
              ),
              const SizedBox(height: 18),
              CkButton.secondary(
                label: 'Manage team',
                expand: false,
                onPressed: () => context.push('/teams/$teamAId/manage'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pick your XI', style: CkType.display(fontSize: 22)),
              Text('${state.selectedPlayers.length} of ${state.playersPerTeam}',
                  style: CkType.mono(fontSize: 12, color: CkColors.muted)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: members.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: CkColors.hairline),
            itemBuilder: (_, idx) {
              final m = members[idx];
              final id = m.member.playerId;
              final selected = state.selectedPlayers.contains(id);
              return CheckboxListTile(
                value: selected,
                onChanged: (_) => c.togglePlayer(id),
                activeColor: CkColors.ink,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(m.displayName,
                    style: CkType.body(fontSize: 15, fontWeight: FontWeight.w500)),
                subtitle: selected
                    ? Row(
                        children: [
                          _MiniToggle(
                            label: 'Captain',
                            active: state.captainId == id,
                            onTap: () => c.setCaptain(id),
                          ),
                          const SizedBox(width: 8),
                          _MiniToggle(
                            label: 'Keeper',
                            active: state.keeperId == id,
                            onTap: () => c.setKeeper(id),
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),
        ),
        if (state.captainId == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Tap "Captain" on a selected player to set a captain.',
                style: CkType.body(fontSize: 12, color: CkColors.red)),
          ),
      ],
    );
  }
}

class _MiniToggle extends StatelessWidget {
  const _MiniToggle(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active ? CkColors.ink : CkColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? CkColors.ink : CkColors.line),
          ),
          child: Text(label,
              style: CkType.mono(
                  fontSize: 10,
                  color: active ? CkColors.paper : CkColors.muted)),
        ),
      );
}

// ─── Step 7: Review ─────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state});
  final MatchSetupState state;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('OPPONENT', state.opponentName ?? '—'),
      ('FORMAT',
          'T${state.overs} · ${state.playersPerTeam}-a-side · ${state.ballType.name}'),
      ('WHEN', state.when == null ? '—' : _WhenWhereStep._fmt(state.when!)),
      (
        'WHERE',
        [state.venueGround, if (state.venueCity.isNotEmpty) state.venueCity]
            .where((s) => s.isNotEmpty)
            .join(' · ')
      ),
      ('XI', '${state.selectedPlayers.length} players · captain set'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      children: [
        Text('Review & send', style: CkType.display(fontSize: 26)),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            top: BorderSide(color: CkColors.hairline)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(rows[i].$1,
                            style: CkType.mono(
                                fontSize: 10, color: CkColors.muted)),
                      ),
                      Expanded(
                        child: Text(rows[i].$2,
                            style: CkType.body(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared ─────────────────────────────────────────────────────────────────

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });
  final String title;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? CkColors.paper2 : CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(
              color: selected ? CkColors.ink : CkColors.line,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            CkType.display(fontSize: 16, letterSpacing: -0.01)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            CkType.body(fontSize: 13, color: CkColors.muted)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: CkColors.ink, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: CkType.body(
          fontSize: 13, fontWeight: FontWeight.w600, color: CkColors.ink2));
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? CkColors.ink : CkColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: active ? CkColors.ink : CkColors.line, width: 1.5),
          ),
          child: Text(label,
              style: CkType.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? CkColors.paper : CkColors.ink)),
        ),
      );
}

