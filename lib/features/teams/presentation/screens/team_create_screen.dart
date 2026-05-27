import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../controllers/team_create_controller.dart';
import '../state/team_create_state.dart';
import '../widgets/team_create/tc_done.dart';
import '../widgets/team_create/tc_overlays.dart';
import '../widgets/team_create/tc_step_basics.dart';
import '../widgets/team_create/tc_step_crest.dart';
import '../widgets/team_create/tc_step_home.dart';
import '../widgets/team_create/tc_step_identity.dart';
import '../widgets/team_create/tc_step_review.dart';

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    });

    final async = ref.watch(teamCreateControllerProvider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: switch (async) {
        AsyncData(:final value) when value.createdTeamId != null =>
          SafeArea(child: _DoneView(state: value)),
        AsyncData(:final value) => SafeArea(child: _Wizard(state: value)),
        _ => const Center(
            child: CircularProgressIndicator(color: CkColors.ink)),
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
        _Progress(step: stepIndex + 1, totalSteps: TeamCreateStep.values.length),
        Expanded(
          child: _StepBody(
            state: state,
            controller: controller,
            onOwnershipTap: () => showOwnershipSheet(context),
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

  Future<void> _openSaveExit(BuildContext context,
      TeamCreateController controller, TeamCreateState s) {
    return showSaveExitSheet(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
    final stepLabels =
        ['BASICS', 'IDENTITY', 'HOME', 'CREST', 'REVIEW'];
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
        return TcStepBasics(state: state, controller: controller);
      case TeamCreateStep.identity:
        return TcStepIdentity(state: state, controller: controller);
      case TeamCreateStep.home:
        return TcStepHome(state: state, controller: controller);
      case TeamCreateStep.crest:
        return TcStepCrest(state: state, controller: controller);
      case TeamCreateStep.review:
        return TcStepReview(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
              onTap: disabled
                  ? null
                  : (isLast ? onSubmit : controller.next),
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
    return TcDone(
      state: state,
      onAddPlayers: () => context.go(
        '/teams/${state.createdTeamId}/manage?justCreated=true',
      ),
      onOpenTeam: () => context.go('/teams/${state.createdTeamId}'),
      onScheduleFriendly: () => context.go(
        '/matches/setup/${state.createdTeamId}',
      ),
      onRegisterTournament: () {
        // No tournament route yet — a brief snack so the tap isn't silent.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament registration coming soon.')),
        );
      },
      onCreateAnother: () =>
          ref.read(teamCreateControllerProvider.notifier).reset(),
    );
  }
}
