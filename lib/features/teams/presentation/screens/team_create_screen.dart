import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../domain/entities/team.dart';
import '../controllers/team_create_controller.dart';
import '../state/team_create_state.dart';
import '../widgets/team_avatar.dart';

/// Preset primary/secondary colour pairs (no full picker / image upload in P1).
const _colorPresets = <(String, String)>[
  ('#338946', '#E24A3F'),
  ('#E24A3F', '#161107'),
  ('#161107', '#E6AC3D'),
  ('#2D6CDF', '#E6AC3D'),
  ('#7A3FD6', '#F8EAC6'),
  ('#0E7C7B', '#E24A3F'),
];

class TeamCreateScreen extends ConsumerWidget {
  const TeamCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(teamCreateControllerProvider, (prev, next) {
      final id = next.value?.createdTeamId;
      if (id != null && prev?.value?.createdTeamId == null) {
        context.go('/teams/$id/manage?justCreated=true');
      }
      final err = next.value?.submitError;
      if (err != null && prev?.value?.submitError != err) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    });

    final async = ref.watch(teamCreateControllerProvider);
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (async) {
          AsyncData(:final value) => _Wizard(state: value),
          _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
        },
      ),
    );
  }
}

class _Wizard extends ConsumerWidget {
  const _Wizard({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(teamCreateControllerProvider.notifier);
    final stepIndex = state.step.index;
    final isLast = state.step == TeamCreateStep.review;

    return Column(
      children: [
        // Top bar + progress
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () =>
                    stepIndex == 0 ? context.pop() : c.back(),
                icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
              ),
              Expanded(
                child: Text(
                  'NEW TEAM · ${stepIndex + 1}/${TeamCreateStep.values.length}',
                  textAlign: TextAlign.center,
                  style: CkType.mono(fontSize: 11, color: CkColors.muted),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              for (var i = 0; i < TeamCreateStep.values.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= stepIndex ? CkColors.ink : CkColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: switch (state.step) {
            TeamCreateStep.basics => _BasicsStep(state: state, c: c),
            TeamCreateStep.identity => _IdentityStep(state: state, c: c),
            TeamCreateStep.home => _HomeStep(state: state, c: c),
            TeamCreateStep.crest => _CrestStep(state: state),
            TeamCreateStep.review => _ReviewStep(state: state, c: c),
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: CkButton(
            label: isLast ? 'Create team' : 'Continue',
            busy: state.submitting,
            onPressed: _canAdvance(state)
                ? (isLast ? c.submit : c.next)
                : null,
          ),
        ),
      ],
    );
  }

  bool _canAdvance(TeamCreateState s) => switch (s.step) {
        TeamCreateStep.basics => s.canContinueBasics,
        TeamCreateStep.home => s.canContinueHome,
        _ => true,
      };
}

// ─── Step 1: Basics ───────────────────────────────────────────────────────────

class _BasicsStep extends StatefulWidget {
  const _BasicsStep({required this.state, required this.c});
  final TeamCreateState state;
  final TeamCreateController c;
  @override
  State<_BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends State<_BasicsStep> {
  late final TextEditingController _name =
      TextEditingController(text: widget.state.name);
  late final TextEditingController _founded =
      TextEditingController(text: widget.state.foundedYear ?? '');

  @override
  void dispose() {
    _name.dispose();
    _founded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final c = widget.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      children: [
        Text('Team basics', style: CkType.display(fontSize: 26)),
        const SizedBox(height: 18),
        const _Label('Team name'),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          onChanged: c.setName,
          textCapitalization: TextCapitalization.words,
          style: CkType.body(fontSize: 16),
          decoration: const InputDecoration(hintText: 'Lahore Lions'),
        ),
        const SizedBox(height: 18),
        const _Label('Team type'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in TeamType.values)
              _Chip(
                label: t.name[0].toUpperCase() + t.name.substring(1),
                active: state.type == t,
                onTap: () => c.setType(t),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const _Label('Founded (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _founded,
          onChanged: c.setFoundedYear,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          style: CkType.body(fontSize: 16),
          decoration: const InputDecoration(hintText: '2019'),
        ),
        const SizedBox(height: 18),
        const _Label('Privacy'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final p in TeamPrivacy.values) ...[
              _Chip(
                label: p.name[0].toUpperCase() + p.name.substring(1),
                active: state.privacy == p,
                onTap: () => c.setPrivacy(p),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Step 2: Identity ─────────────────────────────────────────────────────────

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({required this.state, required this.c});
  final TeamCreateState state;
  final TeamCreateController c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      children: [
        Text('Identity & colours', style: CkType.display(fontSize: 26)),
        const SizedBox(height: 18),
        Center(
          child: TeamAvatar(
            name: state.name.isEmpty ? 'New Team' : state.name,
            primaryColor: state.primaryColor,
            size: 84,
            radius: 22,
          ),
        ),
        const SizedBox(height: 22),
        const _Label('Colour pair'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final preset in _colorPresets)
              _ColorSwatch(
                primary: preset.$1,
                secondary: preset.$2,
                selected: state.primaryColor == preset.$1 &&
                    state.secondaryColor == preset.$2,
                onTap: () => c.setColors(preset.$1, preset.$2),
              ),
          ],
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.primary,
    required this.secondary,
    required this.selected,
    required this.onTap,
  });
  final String primary;
  final String secondary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: selected ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(child: Container(color: parseHexColor(primary))),
            Expanded(child: Container(color: parseHexColor(secondary))),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Home ─────────────────────────────────────────────────────────────

class _HomeStep extends StatefulWidget {
  const _HomeStep({required this.state, required this.c});
  final TeamCreateState state;
  final TeamCreateController c;
  @override
  State<_HomeStep> createState() => _HomeStepState();
}

class _HomeStepState extends State<_HomeStep> {
  late final TextEditingController _city =
      TextEditingController(text: widget.state.city);
  late final TextEditingController _area =
      TextEditingController(text: widget.state.area);
  late final TextEditingController _ground =
      TextEditingController(text: widget.state.homeGround);

  @override
  void dispose() {
    _city.dispose();
    _area.dispose();
    _ground.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      children: [
        Text('Home & location', style: CkType.display(fontSize: 26)),
        const SizedBox(height: 18),
        const _Label('City'),
        const SizedBox(height: 8),
        TextField(
          controller: _city,
          onChanged: c.setCity,
          textCapitalization: TextCapitalization.words,
          style: CkType.body(fontSize: 16),
          decoration: const InputDecoration(hintText: 'Lahore'),
        ),
        const SizedBox(height: 18),
        const _Label('Area / mohalla (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _area,
          onChanged: c.setArea,
          textCapitalization: TextCapitalization.words,
          style: CkType.body(fontSize: 16),
          decoration: const InputDecoration(hintText: 'Model Town'),
        ),
        const SizedBox(height: 18),
        const _Label('Home ground (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _ground,
          onChanged: c.setHomeGround,
          textCapitalization: TextCapitalization.words,
          style: CkType.body(fontSize: 16),
          decoration: const InputDecoration(hintText: 'Gaddafi B Ground'),
        ),
      ],
    );
  }
}

// ─── Step 4: Crest ────────────────────────────────────────────────────────────

class _CrestStep extends StatelessWidget {
  const _CrestStep({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      children: [
        Text('Crest', style: CkType.display(fontSize: 26)),
        const SizedBox(height: 6),
        Text('Auto-synced with your team colours. Image upload comes later.',
            style: CkType.body(fontSize: 14, color: CkColors.muted)),
        const SizedBox(height: 28),
        Center(
          child: TeamAvatar(
            name: state.name.isEmpty ? 'New Team' : state.name,
            primaryColor: state.primaryColor,
            size: 120,
            radius: 30,
          ),
        ),
      ],
    );
  }
}

// ─── Step 5: Review ───────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state, required this.c});
  final TeamCreateState state;
  final TeamCreateController c;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, TeamCreateStep)>[
      (
        'BASICS',
        '${state.name} · ${state.type.name} · ${state.privacy.name}'
            '${state.foundedYear != null && state.foundedYear!.isNotEmpty ? ' · est. ${state.foundedYear}' : ''}',
        TeamCreateStep.basics,
      ),
      (
        'HOME',
        state.combinedCity.isEmpty ? '—' : state.combinedCity,
        TeamCreateStep.home,
      ),
      if (state.homeGround.trim().isNotEmpty)
        ('GROUND', state.homeGround, TeamCreateStep.home),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      children: [
        Text('Review', style: CkType.display(fontSize: 26)),
        const SizedBox(height: 18),
        Center(
          child: TeamAvatar(
            name: state.name.isEmpty ? 'New Team' : state.name,
            primaryColor: state.primaryColor,
            size: 72,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                InkWell(
                  onTap: () => c.goToStep(rows[i].$3),
                  child: Container(
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : const Border(
                              top: BorderSide(color: CkColors.hairline)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(rows[i].$1,
                              style: CkType.mono(
                                  fontSize: 10, color: CkColors.muted)),
                        ),
                        Expanded(
                          child: Text(rows[i].$2,
                              style: CkType.body(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        const Icon(Icons.edit_outlined,
                            size: 16, color: CkColors.soft),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared bits ────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: CkType.body(
          fontSize: 13, fontWeight: FontWeight.w600, color: CkColors.ink2));
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
}
