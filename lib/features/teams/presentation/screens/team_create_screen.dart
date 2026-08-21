import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../location/presentation/widgets/place_autocomplete_field.dart';
import '../../domain/entities/team.dart';
import '../controllers/team_create_controller.dart';
import '../state/team_create_state.dart';
import '../utils/team_display.dart';
import '../widgets/team_create/tc_atoms.dart';

/// "Create a team" — a 5-step wizard (Basics → Identity → Home → Crest →
/// Review), followed by a celebration screen on successful submit. Faithful
/// Flutter port of the matchday design (Team Creation Flow.html).
///
/// The Save & Exit and Ownership briefing overlays are bottom sheets
/// surfaced from this screen.
class TeamCreateScreen extends ConsumerWidget {
  const TeamCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(teamCreateControllerProvider, (prev, next) {
      final err = next.value?.submitError;
      if (err != null && prev?.value?.submitError != err) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
    });

    final async = ref.watch(teamCreateControllerProvider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: switch (async) {
        AsyncData(:final value) when value.createdTeamId != null => SafeArea(
          child: _DoneView(state: value),
        ),
        AsyncData(:final value) => SafeArea(child: _Wizard(state: value)),
        _ => const Center(
          child: CircularProgressIndicator(color: CkColors.ink),
        ),
      },
    );
  }
}

class _Wizard extends ConsumerWidget {
  const _Wizard({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(teamCreateControllerProvider.notifier);
    final stepIndex = state.step.index;
    final isLast = state.step == TeamCreateStep.review;

    return Column(
      children: [
        _TopBar(
          onBack: () => stepIndex == 0 ? context.pop() : controller.back(),
          onSaveExit: () => _openSaveExit(context, controller, state),
          step: stepIndex + 1,
          totalSteps: TeamCreateStep.values.length,
        ),
        _Progress(
          step: stepIndex + 1,
          totalSteps: TeamCreateStep.values.length,
        ),
        Expanded(
          child: _StepBody(
            state: state,
            controller: controller,
            onOwnershipTap: () => _showOwnershipSheet(context),
          ),
        ),
        _Footer(
          stepIndex: stepIndex,
          isLast: isLast,
          state: state,
          controller: controller,
          onSubmit: () => controller.submit(),
        ),
      ],
    );
  }

  Future<void> _openSaveExit(
    BuildContext context,
    TeamCreateController controller,
    TeamCreateState s,
  ) {
    return _showSaveExitSheet(
      context,
      step: s.step.index + 1,
      totalSteps: TeamCreateStep.values.length,
      onSaveAndExit: () {
        // Draft is auto-persisted on every field change — just exit.
        if (context.mounted) context.pop();
      },
      onDiscard: () {
        controller.reset();
        if (context.mounted) context.pop();
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onSaveExit,
    required this.step,
    required this.totalSteps,
  });

  final VoidCallback onBack;
  final VoidCallback onSaveExit;
  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 14, 4),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.chevron_left, size: 22, color: CkColors.ink),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'NEW TEAM · $step/$totalSteps',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.12,
                  color: CkColors.muted,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: onSaveExit,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                'SAVE & EXIT',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.08,
                  color: CkColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.totalSteps});
  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final stepLabels = ['BASICS', 'IDENTITY', 'HOME', 'CREST', 'REVIEW'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < totalSteps; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < step ? CkColors.ink : CkColors.paper2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'STEP $step · ${stepLabels[step - 1]}',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.state,
    required this.controller,
    required this.onOwnershipTap,
  });

  final TeamCreateState state;
  final TeamCreateController controller;
  final VoidCallback onOwnershipTap;

  @override
  Widget build(BuildContext context) {
    switch (state.step) {
      case TeamCreateStep.basics:
        return _StepBasics(state: state, controller: controller);
      case TeamCreateStep.identity:
        return _StepIdentity(state: state, controller: controller);
      case TeamCreateStep.home:
        return _StepHome(state: state, controller: controller);
      case TeamCreateStep.crest:
        return _StepCrest(state: state, controller: controller);
      case TeamCreateStep.review:
        return _StepReview(
          state: state,
          onJump: (step) => controller.goToStep(step),
          onOwnershipTap: onOwnershipTap,
        );
    }
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.stepIndex,
    required this.isLast,
    required this.state,
    required this.controller,
    required this.onSubmit,
  });

  final int stepIndex;
  final bool isLast;
  final TeamCreateState state;
  final TeamCreateController controller;
  final VoidCallback onSubmit;

  bool get _canContinue {
    switch (state.step) {
      case TeamCreateStep.basics:
        return state.canContinueBasics;
      case TeamCreateStep.home:
        return state.canContinueHome;
      default:
        return true;
    }
  }

  String get _label {
    if (isLast) return state.submitting ? 'Creating…' : 'Create team';
    if (state.step == TeamCreateStep.crest) return 'Review';
    return 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !_canContinue || state.submitting;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          if (stepIndex > 0) ...[
            InkWell(
              onTap: controller.back,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Text(
                  'Back',
                  style: CkType.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: InkWell(
              onTap: disabled ? null : (isLast ? onSubmit : controller.next),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.ink.withValues(alpha: disabled ? 0.35 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _label,
                      style: CkType.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CkColors.paper,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLast ? Icons.check_rounded : Icons.arrow_forward,
                      size: 16,
                      color: CkColors.paper,
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

class _DoneView extends ConsumerWidget {
  const _DoneView({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onAddPlayers() =>
        context.go('/teams/${state.createdTeamId}/manage?justCreated=true');
    void onOpenTeam() => context.go('/teams/${state.createdTeamId}');
    void onScheduleFriendly() =>
        context.go('/matches/setup/${state.createdTeamId}');
    void onRegisterTournament() {
      // No tournament route yet — a brief snack so the tap isn't silent.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament registration coming soon.')),
      );
    }

    void onCreateAnother() =>
        ref.read(teamCreateControllerProvider.notifier).reset();

    return Container(
      color: CkColors.paper,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar: "TEAM CREATED" eyebrow right-aligned.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    'TEAM CREATED',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.12,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _Confetti(primaryHex: state.primaryColor),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF281E0F,
                                ).withValues(alpha: 0.18),
                                offset: const Offset(0, 12),
                                blurRadius: 36,
                              ),
                            ],
                          ),
                          child: TcCrestPreview(
                            crestKind: state.crestKind,
                            primaryHex: state.primaryColor,
                            monogram: state.monogram,
                            logoPath: state.logoUrl,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '${state.name.trim().isEmpty ? 'Your team' : state.name} is live.',
                    textAlign: TextAlign.center,
                    style: CkType.display(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.03,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You're the owner. Next: add your squad.",
                    textAlign: TextAlign.center,
                    style: CkType.body(
                      fontSize: 14,
                      color: CkColors.muted,
                      height: 1.4,
                    ),
                  ),
                  if (state.tagline.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Text(
                        '“${state.tagline}”',
                        textAlign: TextAlign.center,
                        style: CkType.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.01,
                          height: 1.4,
                          color: CkColors.ink2,
                        ).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _Receipt(state: state),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'WHAT NEXT',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.10,
                        color: CkColors.muted,
                      ),
                    ),
                  ),
                  _NextRow(
                    primary: true,
                    label: 'Add players',
                    sub: 'Up to 25 · search, SMS, or unclaimed',
                    icon: Icons.person_add_alt_1,
                    onTap: onAddPlayers,
                  ),
                  const SizedBox(height: 8),
                  _NextRow(
                    label: 'Open team page',
                    sub: 'See your public profile',
                    icon: Icons.east,
                    onTap: onOpenTeam,
                  ),
                  const SizedBox(height: 8),
                  _NextRow(
                    label: 'Schedule a friendly',
                    sub: 'Challenge another team',
                    icon: Icons.calendar_month,
                    onTap: onScheduleFriendly,
                  ),
                  const SizedBox(height: 8),
                  _NextRow(
                    label: 'Register for a tournament',
                    sub:
                        'Find one near ${state.city.trim().isEmpty ? 'you' : state.city}',
                    icon: Icons.emoji_events,
                    onTap: onRegisterTournament,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onCreateAnother,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Center(
                  child: Text(
                    '← CREATE ANOTHER TEAM',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.10,
                      color: CkColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Step 01 — Basics: name, team type tiles, founded year, privacy.
// Faithful port of `TCStepBasics` in design/screens/TeamCreate.jsx.
// ─────────────────────────────────────────────────────────────────────────

class _StepBasics extends StatelessWidget {
  const _StepBasics({required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 18),
            child: Text(
              'Name your team.',
              style: CkType.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
                height: 1.1,
              ),
            ),
          ),
          const TcLabel('Team name'),
          TcInput(
            value: state.name,
            onChanged: controller.setName,
            maxLength: 50,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '3–50 characters · we\'ll use first letters as a crest',
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ),
                Text(
                  '${state.name.length}/50',
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.02,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const TcLabel('Team type'),
          _TypeGrid(value: state.type, onChanged: controller.setType),
          const SizedBox(height: 16),
          _TaglineSection(state: state, controller: controller),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TcLabel('Founded'),
                    TcInput(
                      value: state.foundedYear ?? '',
                      onChanged: controller.setFoundedYear,
                      placeholder: '2019',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TcLabel('Privacy'),
                    _PrivacyToggle(
                      value: state.privacy,
                      onChanged: controller.setPrivacy,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PrivacyExplainer(privacy: state.privacy),
        ],
      ),
    );
  }
}

class _TaglineSection extends StatelessWidget {
  const _TaglineSection({required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'TAGLINE',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· optional',
                style: CkType.body(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: CkColors.soft,
                ),
              ),
              const Spacer(),
              Text(
                '${state.tagline.length}/60',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
        TcInput(
          value: state.tagline,
          onChanged: controller.setTagline,
          maxLength: 60,
          placeholder: 'e.g. Roar with the Lions.',
          textStyle: CkType.display(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.01,
          ).copyWith(
            fontStyle:
                state.tagline.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'A short motto. Shows on your team page and scorecards.',
            style: CkType.body(fontSize: 11, color: CkColors.muted),
          ),
        ),
      ],
    );
  }
}

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({required this.value, required this.onChanged});
  final TeamType value;
  final ValueChanged<TeamType> onChanged;

  static const _options = <(TeamType, String, String)>[
    (TeamType.club, 'Club', 'Persistent club with branding'),
    (TeamType.village, 'Village', 'Mohalla / community team'),
    (TeamType.casual, 'Casual', 'One-off for a tournament'),
    (TeamType.corporate, 'Corporate', 'Office / department'),
    (TeamType.school, 'School', 'School team'),
    (TeamType.university, 'University', 'Uni team'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final opt in _options)
          _TypeTile(
            label: opt.$2,
            subtitle: opt.$3,
            selected: value == opt.$1,
            onTap: () => onChanged(opt.$1),
          ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: selected ? CkColors.paper : CkColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: CkType.display(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.01,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: CkType.body(
                fontSize: 10,
                color: CkColors.muted,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyToggle extends StatelessWidget {
  const _PrivacyToggle({required this.value, required this.onChanged});
  final TeamPrivacy value;
  final ValueChanged<TeamPrivacy> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final p in TeamPrivacy.values) ...[
          if (p != TeamPrivacy.values.first) const SizedBox(width: 6),
          Expanded(
            child: _PrivacyBtn(privacy: p, value: value, onChanged: onChanged),
          ),
        ],
      ],
    );
  }
}

class _PrivacyBtn extends StatelessWidget {
  const _PrivacyBtn({
    required this.privacy,
    required this.value,
    required this.onChanged,
  });
  final TeamPrivacy privacy;
  final TeamPrivacy value;
  final ValueChanged<TeamPrivacy> onChanged;

  String get _label => privacy == TeamPrivacy.public ? 'Public' : 'Private';

  @override
  Widget build(BuildContext context) {
    final selected = value == privacy;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(privacy);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 49,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? CkColors.paper : CkColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          _label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CkColors.ink,
          ),
        ),
      ),
    );
  }
}

class _PrivacyExplainer extends StatelessWidget {
  const _PrivacyExplainer({required this.privacy});
  final TeamPrivacy privacy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 16, color: CkColors.ink2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: CkType.body(
                  fontSize: 11,
                  color: CkColors.ink2,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Private',
                    style: CkType.body(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' teams hide their roster from non-members and are invite-only. You can change this later.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Step 02 — Identity: live preview + primary + secondary swatches + monogram.
// ─────────────────────────────────────────────────────────────────────────

class _StepIdentity extends StatelessWidget {
  const _StepIdentity({required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 18),
            child: Text(
              'Your colors.',
              style: CkType.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
                height: 1.1,
              ),
            ),
          ),
          _LivePreview(state: state),
          const SizedBox(height: 22),
          const TcLabel('Primary'),
          TcColorGrid(
            palette: kTeamCreatePalette,
            value: state.primaryColor,
            onChanged: controller.setPrimaryColor,
          ),
          const SizedBox(height: 18),
          const TcLabel('Secondary / accent'),
          TcColorGrid(
            palette: kTeamCreatePalette,
            value: state.secondaryColor,
            onChanged: controller.setSecondaryColor,
          ),
          const SizedBox(height: 14),
          const TcLabel('Monogram'),
          TcInput(
            value: state.monogram,
            onChanged: controller.setMonogram,
            maxLength: 3,
            textAlign: TextAlign.center,
            maxWidth: 120,
            textStyle: CkType.display(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context) {
    final primary = parseHexColor(state.primaryColor, fallback: CkColors.ink);
    final secondary = parseHexColor(
      state.secondaryColor,
      fallback: CkColors.paper,
    );
    final fg = onColor(primary);

    return Container(
      height: 168,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Faint pitch motif bottom-right.
          Positioned(
            right: -40,
            bottom: -44,
            child: Opacity(
              opacity: 0.18,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _PitchMotif(stroke: fg),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      state.monogram,
                      style: CkType.display(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02,
                        color: onColor(secondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.name.trim().isEmpty
                              ? 'Your team name'
                              : state.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.display(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.02,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${state.type.label.toUpperCase()}'
                          '${state.city.trim().isEmpty ? '' : ' · ${state.city.toUpperCase()}'}',
                          style: CkType.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.06,
                            color: fg.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.tagline.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      '“${state.tagline}”',
                      style: CkType.display(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.01,
                        height: 1.3,
                        color: fg.withValues(alpha: 0.85),
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                'PREVIEW · KIT',
                style: CkType.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PitchMotif extends CustomPainter {
  _PitchMotif({required this.stroke});
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(Rect.fromCenter(center: c, width: 190, height: 120), paint);
    canvas.drawOval(Rect.fromCenter(center: c, width: 110, height: 68), paint);
    canvas.drawRect(Rect.fromCenter(center: c, width: 32, height: 120), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

extension on TeamType {
  String get label {
    switch (this) {
      case TeamType.club:
        return 'Club';
      case TeamType.village:
        return 'Village';
      case TeamType.casual:
        return 'Casual';
      case TeamType.corporate:
        return 'Corporate';
      case TeamType.school:
        return 'School';
      case TeamType.university:
        return 'University';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Step 03 — Home: city + area + ground + stripe-pattern map placeholder.
// ─────────────────────────────────────────────────────────────────────────

class _StepHome extends StatelessWidget {
  const _StepHome({required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Text(
              'Where do you play?',
              style: CkType.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
                height: 1.1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(
              'Helps players nearby find you and disambiguates teams with '
              'similar names.',
              style: CkType.body(
                fontSize: 13,
                color: CkColors.muted,
                height: 1.4,
              ),
            ),
          ),
          // Resolving picker, not a free-text box: this is the ONLY place a
          // team acquires coordinates, and without them it can never surface
          // in a proximity search or a city facet chip.
          PlaceAutocompleteField(
            field: 'team_create_city',
            label: 'City or village',
            hintText: 'Lahore, Hair, Chak 47…',
            initialText: state.city,
            onResolved: controller.setResolvedPlace,
          ),
          if (state.hasCoordinates)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Nearby players will be able to find this team.',
                style: CkType.body(fontSize: 11, color: CkColors.muted),
              ),
            ),
          const SizedBox(height: 14),
          const TcLabel('Area / mohalla / locality'),
          TcInput(
            value: state.area,
            onChanged: controller.setArea,
            placeholder: 'Model Town',
          ),
          const SizedBox(height: 14),
          const TcLabel('Home ground (optional)'),
          TcInput(
            value: state.homeGround,
            onChanged: controller.setHomeGround,
            placeholder: 'Gaddafi B Ground',
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 22),
            child: Text(
              'Free text — no need to be a registered venue.',
              style: CkType.body(fontSize: 11, color: CkColors.muted),
            ),
          ),
          _MapPlaceholder(state: state),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        state.area.trim().isNotEmpty || state.city.trim().isNotEmpty;
    final lineCity =
        hasLocation
            ? [
              state.area.trim(),
              state.city.trim(),
            ].where((s) => s.isNotEmpty).join(', ')
            : '—';
    return Container(
      height: 132,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: _StripePainter(),
            size: const Size(double.infinity, double.infinity),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place, size: 22, color: CkColors.red),
                const SizedBox(height: 6),
                Text(
                  lineCity,
                  style: CkType.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MAP PREVIEW',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = CkColors.paper2;
    const stripe = 8.0;
    const period = 16.0;
    // Draw 135deg stripes.
    final diag = size.width + size.height;
    for (var d = -size.height; d < diag; d += period) {
      final path =
          Path()
            ..moveTo(d, 0)
            ..lineTo(d + size.height, size.height)
            ..lineTo(d + size.height - stripe, size.height)
            ..lineTo(d - stripe, 0)
            ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────
// Step 04 — Crest: upload OR three generated styles.
// ─────────────────────────────────────────────────────────────────────────

class _StepCrest extends StatelessWidget {
  const _StepCrest({required this.state, required this.controller});
  final TeamCreateState state;
  final TeamCreateController controller;

  bool get _hasLogo =>
      state.crestKind == CrestKind.upload &&
      (state.logoUrl?.isNotEmpty ?? false);

  Future<void> _pickLogo(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;
    final size = await File(file.path).length();
    if (size > 2 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max 2 MB. Crop or compress and try again.'),
          ),
        );
      }
      return;
    }
    controller.setLogo(url: file.path, name: file.name, size: size);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Text(
              'Set a crest.',
              style: CkType.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
                height: 1.1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              "Upload your club's logo if you have one, or pick a generated "
              'style.',
              style: CkType.body(
                fontSize: 13,
                color: CkColors.muted,
                height: 1.4,
              ),
            ),
          ),

          // Big preview centred.
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: TcCrestPreview(
                crestKind: state.crestKind,
                primaryHex: state.primaryColor,
                monogram: state.monogram,
                logoPath: state.logoUrl,
              ),
            ),
          ),

          const TcLabel('Your logo'),
          _hasLogo
              ? _UploadedRow(
                state: state,
                onReplace: () => _pickLogo(context),
                onRemove: controller.removeLogo,
              )
              : _UploadPrompt(onTap: () => _pickLogo(context)),
          const SizedBox(height: 18),
          _Divider(hasLogo: _hasLogo),
          const SizedBox(height: 12),
          _GeneratedStyles(state: state, controller: controller, dim: _hasLogo),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _hasLogo
                  ? "Your uploaded logo will appear on scorecards, team pages "
                      "and the bracket. We'll auto-tint it to your team colors "
                      'where contrast is needed.'
                  : 'Crest auto-syncs with your team colors. You can replace '
                      'it with an upload anytime.',
              style: CkType.body(
                fontSize: 11,
                color: CkColors.ink2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPrompt extends StatelessWidget {
  const _UploadPrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: _DottedBorderBox(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: CkColors.hairline),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.file_upload_outlined,
                  size: 18,
                  color: CkColors.ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload a logo',
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.01,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'PNG, JPG or SVG · max 2 MB · transparent background '
                      'recommended',
                      style: CkType.body(
                        fontSize: 11,
                        color: CkColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadedRow extends StatelessWidget {
  const _UploadedRow({
    required this.state,
    required this.onReplace,
    required this.onRemove,
  });
  final TeamCreateState state;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CkColors.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(4),
            child:
                state.logoUrl == null
                    ? const SizedBox.shrink()
                    : Image.file(File(state.logoUrl!), fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        state.logoName ?? 'team-logo.png',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CkColors.greenSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'UPLOADED',
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08,
                          color: CkInk.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.logoSize == null ? '—' : '${(state.logoSize! / 1024).round()} KB'} '
                  '· auto-cropped square',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.04,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _GhostBtn(label: 'Replace', onTap: onReplace),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: CkColors.hairline),
              ),
              child: const Icon(Icons.close, size: 13, color: CkColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CkColors.ink,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.hasLogo});
  final bool hasLogo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: CkColors.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            hasLogo ? 'OR GENERATE ONE' : 'OR USE A GENERATED CREST',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: CkColors.hairline)),
      ],
    );
  }
}

class _GeneratedStyles extends StatelessWidget {
  const _GeneratedStyles({
    required this.state,
    required this.controller,
    required this.dim,
  });
  final TeamCreateState state;
  final TeamCreateController controller;
  final bool dim;

  static const _kinds = [
    (CrestKind.monogram, 'Monogram'),
    (CrestKind.initials, 'Initials'),
    (CrestKind.shield, 'Shield'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final entry in _kinds)
          TcSelectTile(
            title: entry.$2,
            selected: !dim && state.crestKind == entry.$1,
            dim: dim,
            onTap: () => controller.setCrestKind(entry.$1),
            leading: TcCrestPreview(
              crestKind: entry.$1,
              primaryHex: state.primaryColor,
              monogram: state.monogram,
              size: 26,
              radius: 7,
            ),
          ),
      ],
    );
  }
}

/// Dashed-border rectangle for the upload prompt.
class _DottedBorderBox extends StatelessWidget {
  const _DottedBorderBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: const BoxDecoration(color: CkColors.paper2),
          child: child,
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = CkColors.soft
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 5).clamp(0, m.length)), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────
// Step 05 — Review: hero card + summary rows that jump back to their step,
// owner block, terms blurb.
// ─────────────────────────────────────────────────────────────────────────

class _StepReview extends StatelessWidget {
  const _StepReview({
    required this.state,
    required this.onJump,
    required this.onOwnershipTap,
  });

  final TeamCreateState state;
  final ValueChanged<TeamCreateStep> onJump;

  /// Tapping the owner block opens the ownership briefing overlay.
  final VoidCallback onOwnershipTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              'Looks good?',
              style: CkType.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
                height: 1.1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(
              'Tap any row to jump back and edit.',
              style: CkType.body(
                fontSize: 13,
                color: CkColors.muted,
                height: 1.4,
              ),
            ),
          ),
          _HeroCard(state: state),
          const SizedBox(height: 14),
          _SummaryList(state: state, onJump: onJump),
          const SizedBox(height: 16),
          _OwnerBlock(onTap: onOwnershipTap),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "By creating this team you agree to Matchday's community "
              "guidelines. You'll be able to add players from the team page "
              'next.',
              style: CkType.body(
                fontSize: 11,
                color: CkColors.muted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context) {
    final primary = parseHexColor(state.primaryColor, fallback: CkColors.ink);
    final secondary = parseHexColor(
      state.secondaryColor,
      fallback: CkColors.paper,
    );
    final fg = onColor(primary);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              state.monogram,
              style: CkType.display(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.03,
                color: onColor(secondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.name.trim().isEmpty ? 'Your team name' : state.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025,
                    height: 1.05,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _eyebrow(state),
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                    color: fg.withValues(alpha: 0.8),
                  ),
                ),
                if (state.tagline.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      '“${state.tagline}”',
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.01,
                        height: 1.35,
                        color: fg.withValues(alpha: 0.9),
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _eyebrow(TeamCreateState s) {
    final parts = <String>[s.type.wire.toUpperCase()];
    final loc =
        [
          s.area,
          s.city,
        ].where((p) => p.trim().isNotEmpty).join(', ').toUpperCase();
    if (loc.isNotEmpty) parts.add(loc);
    if ((s.foundedYear ?? '').trim().isNotEmpty) {
      parts.add('EST. ${s.foundedYear}');
    }
    return parts.join(' · ');
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.state, required this.onJump});
  final TeamCreateState state;
  final ValueChanged<TeamCreateStep> onJump;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'BASICS',
            value: Text(
              [
                state.name.trim().isEmpty ? 'Unnamed' : state.name,
                state.type.wire,
                state.privacy.wire,
                'est. ${(state.foundedYear ?? '').trim().isEmpty ? '—' : state.foundedYear}',
              ].join(' · '),
              style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            onTap: () => onJump(TeamCreateStep.basics),
            isFirst: true,
          ),
          if (state.tagline.trim().isNotEmpty)
            _SummaryRow(
              label: 'TAGLINE',
              value: Text(
                '“${state.tagline}”',
                style: CkType.display(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.01,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
              onTap: () => onJump(TeamCreateStep.basics),
            ),
          _SummaryRow(
            label: 'IDENTITY',
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Swatch(hex: state.primaryColor),
                const SizedBox(width: 6),
                _Swatch(hex: state.secondaryColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Monogram "${state.monogram}"',
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => onJump(TeamCreateStep.identity),
          ),
          _SummaryRow(
            label: 'HOME',
            value: Text(
              [
                [
                  state.area,
                  state.city,
                ].where((p) => p.trim().isNotEmpty).join(', '),
                if (state.homeGround.trim().isNotEmpty) state.homeGround,
              ].where((s) => s.isNotEmpty).join(' · '),
              style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            onTap: () => onJump(TeamCreateStep.home),
          ),
          _SummaryRow(
            label: 'CREST',
            value: Text(
              state.crestKind == CrestKind.upload && state.logoUrl != null
                  ? 'Logo uploaded · ${state.logoName ?? 'logo'}'
                  : '${_kindLabel(state.crestKind)} style · auto-synced colors',
              style: CkType.body(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            onTap: () => onJump(TeamCreateStep.crest),
          ),
        ],
      ),
    );
  }

  static String _kindLabel(CrestKind k) {
    switch (k) {
      case CrestKind.monogram:
        return 'Monogram';
      case CrestKind.initials:
        return 'Initials';
      case CrestKind.shield:
        return 'Shield';
      case CrestKind.upload:
        return 'Upload';
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.isFirst = false,
  });
  final String label;
  final Widget value;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border:
              isFirst
                  ? null
                  : const Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: Text(
                label,
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: value),
            const SizedBox(width: 8),
            const Icon(Icons.east, size: 14, color: CkColors.muted),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.hex});
  final String hex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: parseHexColor(hex, fallback: CkColors.ink),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CkColors.hairline),
      ),
    );
  }
}

class _OwnerBlock extends StatelessWidget {
  const _OwnerBlock({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: CkColors.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'YO',
                style: CkType.display(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.03,
                  color: CkColors.paper,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You'll be the team owner",
                    style: CkType.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You can add co-managers and transfer ownership later.',
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.info_outline, size: 16, color: CkColors.muted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Done screen sub-widgets — confetti hero crest, receipt, next-steps stack.
// ─────────────────────────────────────────────────────────────────────────

class _Receipt extends StatelessWidget {
  const _Receipt({required this.state});
  final TeamCreateState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        children: [
          _ReceiptRow(
            iconColor: CkColors.green,
            label: 'Team profile created',
            detail: '${state.type.wire} · ${state.privacy.wire}',
            isFirst: true,
          ),
          _ReceiptRow(
            iconColor: CkColors.green,
            label: 'Located in',
            detail: [
              state.area,
              state.city,
            ].where((p) => p.trim().isNotEmpty).join(', '),
          ),
          _ReceiptRow(
            iconColor: CkColors.green,
            label:
                state.crestKind == CrestKind.upload
                    ? 'Logo uploaded'
                    : 'Crest set',
            detail:
                state.crestKind == CrestKind.upload
                    ? (state.logoName ?? 'team-logo.png')
                    : '${_kindLabel(state.crestKind)} style',
          ),
          const _ReceiptRow(
            iconColor: CkColors.muted,
            iconIsDot: true,
            label: 'Squad pending',
            detail: 'Add players from the team page',
          ),
        ],
      ),
    );
  }

  static String _kindLabel(CrestKind k) {
    switch (k) {
      case CrestKind.monogram:
        return 'Monogram';
      case CrestKind.initials:
        return 'Initials';
      case CrestKind.shield:
        return 'Shield';
      case CrestKind.upload:
        return 'Upload';
    }
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.iconColor,
    required this.label,
    required this.detail,
    this.iconIsDot = false,
    this.isFirst = false,
  });

  final Color iconColor;
  final String label;
  final String detail;
  final bool iconIsDot;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border:
            isFirst
                ? null
                : const Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Icon(
              iconIsDot ? Icons.circle_outlined : Icons.check_rounded,
              size: iconIsDot ? 12 : 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CkType.body(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextRow extends StatelessWidget {
  const _NextRow({
    required this.label,
    required this.sub,
    required this.icon,
    this.primary = false,
    this.onTap,
  });

  final String label;
  final String sub;
  final IconData icon;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primary ? CkColors.ink : CkColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: primary ? null : Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    primary
                        ? CkColors.paper.withValues(alpha: 0.12)
                        : CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 16,
                color: primary ? CkColors.paper : CkColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: CkType.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primary ? CkColors.paper : CkColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: CkType.body(
                      fontSize: 11,
                      color:
                          primary
                              ? CkColors.paper.withValues(alpha: 0.7)
                              : CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color:
                  primary
                      ? CkColors.paper.withValues(alpha: 0.7)
                      : CkColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Confetti extends StatelessWidget {
  const _Confetti({required this.primaryHex});
  final String primaryHex;

  @override
  Widget build(BuildContext context) {
    final primary = parseHexColor(primaryHex, fallback: CkColors.ink);
    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _ConfettiPainter(
          palette: [primary, CkColors.amber, CkColors.ink],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.palette});
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <(double, double, double, int)>[
      (0.10, 0.18, 4, 0),
      (0.22, 0.62, 3, 1),
      (0.38, 0.08, 5, 2),
      (0.55, 0.78, 4, 0),
      (0.78, 0.34, 3, 1),
      (0.92, 0.12, 4, 2),
      (0.18, 0.84, 3, 0),
      (0.68, 0.58, 5, 1),
      (0.46, 0.92, 3, 2),
      (0.04, 0.48, 4, 1),
    ];
    for (final p in positions) {
      final paint = Paint()..color = palette[p.$4 % palette.length];
      canvas.drawCircle(
        Offset(size.width * p.$1, size.height * p.$2),
        p.$3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────
// Bottom-sheet overlays (Save & Exit, Ownership briefing).
// ─────────────────────────────────────────────────────────────────────────

/// Save & exit bottom sheet (Guard B from the design source).
/// Three actions: save draft + exit, keep going, discard.
Future<void> _showSaveExitSheet(
  BuildContext context, {
  required int step,
  required int totalSteps,
  required VoidCallback onSaveAndExit,
  required VoidCallback onDiscard,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder:
        (_) => _SheetShell(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Grab(),
                const SizedBox(height: 12),
                Text(
                  'Save your draft?',
                  style: CkType.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "You're on step $step of $totalSteps. We'll keep your draft "
                  'under Pavilion → Drafts so you can pick up where you left off.',
                  style: CkType.body(
                    fontSize: 13,
                    color: CkColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                _SheetBtn(
                  label: 'Save draft & exit',
                  primary: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSaveAndExit();
                  },
                ),
                const SizedBox(height: 8),
                _SheetBtn(
                  label: 'Keep going',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onDiscard();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        'Discard changes',
                        style: CkType.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CkColors.red,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

/// Ownership briefing bottom sheet (Guard C).
/// Tabular capability list — what owners can do that members/managers can't.
Future<void> _showOwnershipSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder:
        (_) => _SheetShell(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Grab(),
                const SizedBox(height: 12),
                Text(
                  "What it means to own a team",
                  style: CkType.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A quick rundown of what you can do — and what you share with '
                  'co-managers and players.',
                  style: CkType.body(
                    fontSize: 13,
                    color: CkColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                const _CapabilityHeader(),
                const _CapRow(
                  label: 'Edit team profile',
                  owner: true,
                  manager: true,
                  player: false,
                ),
                const _CapRow(
                  label: 'Add & remove players',
                  owner: true,
                  manager: true,
                  player: false,
                ),
                const _CapRow(
                  label: 'Score matches',
                  owner: true,
                  manager: true,
                  player: false,
                ),
                const _CapRow(
                  label: 'Approve join requests',
                  owner: true,
                  manager: true,
                  player: false,
                ),
                const _CapRow(
                  label: 'Transfer ownership',
                  owner: true,
                  manager: false,
                  player: false,
                  irreversible: true,
                ),
                const _CapRow(
                  label: 'Delete the team',
                  owner: true,
                  manager: false,
                  player: false,
                  irreversible: true,
                ),
                const SizedBox(height: 18),
                _SheetBtn(
                  label: 'Got it',
                  primary: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
  );
}

class _CapabilityHeader extends StatelessWidget {
  const _CapabilityHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: SizedBox.shrink()),
          _HeaderCell('OWNER'),
          _HeaderCell('MANAGER'),
          _HeaderCell('PLAYER'),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Center(
        child: Text(
          label,
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: CkColors.muted,
          ),
        ),
      ),
    );
  }
}

class _CapRow extends StatelessWidget {
  const _CapRow({
    required this.label,
    required this.owner,
    required this.manager,
    required this.player,
    this.irreversible = false,
  });
  final String label;
  final bool owner;
  final bool manager;
  final bool player;
  final bool irreversible;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: CkType.body(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (irreversible) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Irreversible',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _CapCell(value: owner),
          _CapCell(value: manager),
          _CapCell(value: player),
        ],
      ),
    );
  }
}

class _CapCell extends StatelessWidget {
  const _CapCell({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Center(
        child: Icon(
          value ? Icons.check_rounded : Icons.remove,
          size: 16,
          color: value ? CkColors.green : CkColors.muted,
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _Grab extends StatelessWidget {
  const _Grab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: CkColors.line,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _SheetBtn extends StatelessWidget {
  const _SheetBtn({
    required this.label,
    this.primary = false,
    required this.onTap,
  });
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: primary ? CkColors.paper : CkColors.ink,
          ),
        ),
      ),
    );
  }
}
