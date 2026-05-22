import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../domain/entities/player_profile.dart';
import '../controllers/onboarding_controller.dart';
import '../state/onboarding_state.dart';

/// Post-auth onboarding wizard: profile → player → welcome.
/// (Sign-in + OTP are handled by the auth feature; see Onboarding.jsx.)
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(onboardingControllerProvider, (prev, next) {
      final state = next.value;
      if (state == null) return;
      if (state.completed) {
        context.go('/home');
      } else if (state.submitError != null &&
          prev?.value?.submitError != state.submitError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.submitError!)),
        );
      }
    });

    final async = ref.watch(onboardingControllerProvider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (async) {
          AsyncData(:final value) => _OnboardingBody(state: value),
          AsyncError() => const Center(child: Text('Something went wrong')),
          _ => const Center(
              child: CircularProgressIndicator(color: CkColors.ink)),
        },
      ),
    );
  }
}

class _OnboardingBody extends ConsumerStatefulWidget {
  const _OnboardingBody({required this.state});
  final OnboardingState state;

  @override
  ConsumerState<_OnboardingBody> createState() => _OnboardingBodyState();
}

class _OnboardingBodyState extends ConsumerState<_OnboardingBody> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _city;

  @override
  void initState() {
    super.initState();
    // Seed once from the (possibly draft-restored) initial state.
    _name = TextEditingController(text: widget.state.displayName);
    _username = TextEditingController(text: widget.state.username);
    _city = TextEditingController(text: widget.state.city);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider).value ?? widget.state;
    // read(.notifier) in build is intentional: we only need the stable notifier
    // to wire its methods as callbacks, not to subscribe to state (that's the
    // watch above).
    final controller = ref.read(onboardingControllerProvider.notifier);

    // Keep the username field text in sync if the controller cleaned/changed it
    // (e.g. stripped a disallowed char) so the cursor doesn't fight the user.
    if (_username.text != state.username) {
      _username.value = TextEditingValue(
        text: state.username,
        selection: TextSelection.collapsed(offset: state.username.length),
      );
    }

    return Column(
      children: [
        _TopBar(
          showBack: state.step == OnboardingStep.player,
          onBack: controller.back,
        ),
        if (state.step != OnboardingStep.welcome)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: _StepDots(activeIndex: state.step.index),
          ),
        Expanded(
          child: switch (state.step) {
            OnboardingStep.profile => _ProfileStep(
                state: state,
                controller: controller,
                nameController: _name,
                usernameController: _username,
                cityController: _city,
              ),
            OnboardingStep.player => _PlayerStep(
                state: state,
                controller: controller,
              ),
            OnboardingStep.welcome => _WelcomeStep(
                state: state,
                controller: controller,
              ),
          },
        ),
      ],
    );
  }
}

// ─── Chrome ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showBack, required this.onBack});
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Opacity(
            opacity: showBack ? 1 : 0,
            child: IconButton(
              onPressed: showBack ? onBack : null,
              icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
            ),
          ),
          const Spacer(),
          Text.rich(TextSpan(children: [
            TextSpan(
                text: 'circk',
                style: CkType.display(fontSize: 22, letterSpacing: -0.045)),
            TextSpan(
                text: '.',
                style: CkType.display(
                    fontSize: 22, letterSpacing: -0.045, color: CkColors.red)),
          ])),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.activeIndex});
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < OnboardingStep.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i <= activeIndex ? CkColors.ink : CkColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Step 1: Profile ───────────────────────────────────────────────────────────

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.state,
    required this.controller,
    required this.nameController,
    required this.usernameController,
    required this.cityController,
  });

  final OnboardingState state;
  final OnboardingController controller;
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController cityController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            children: [
              Text('Set up your profile', style: CkType.display(fontSize: 28)),
              const SizedBox(height: 4),
              Text('So teams can find you.',
                  style: CkType.body(fontSize: 14, color: CkColors.muted)),
              const SizedBox(height: 22),
              const _FieldLabel('Display name'),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                onChanged: controller.setDisplayName,
                textInputAction: TextInputAction.next,
                style: CkType.body(fontSize: 16),
                decoration: const InputDecoration(hintText: 'Ahmed Khan'),
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Username'),
              const SizedBox(height: 8),
              _UsernameField(
                controller: usernameController,
                state: state,
                onChanged: controller.setUsername,
              ),
              const SizedBox(height: 18),
              const _FieldLabel('City / village'),
              const SizedBox(height: 8),
              TextField(
                controller: cityController,
                onChanged: controller.setCity,
                style: CkType.body(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Lahore, Punjab',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: CkColors.red, size: 20),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: CkButton(
            label: 'Continue',
            onPressed: state.canContinueProfile ? controller.continueToPlayer : null,
          ),
        ),
      ],
    );
  }
}

class _UsernameField extends StatelessWidget {
  const _UsernameField({
    required this.controller,
    required this.state,
    required this.onChanged,
  });

  final TextEditingController controller;
  final OnboardingState state;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          inputFormatters: [
            LengthLimitingTextInputFormatter(20),
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]')),
          ],
          style: CkType.body(fontSize: 16),
          decoration: InputDecoration(
            prefixText: '@',
            prefixStyle: CkType.body(fontSize: 16, color: CkColors.soft),
            hintText: 'ahmed_khan',
            suffixIcon: _suffix(),
          ),
        ),
        if (_message() != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(_messageIcon(), size: 14, color: _messageColor()),
              const SizedBox(width: 6),
              Text(_message()!,
                  style: CkType.body(fontSize: 12, color: _messageColor())),
            ],
          ),
        ],
      ],
    );
  }

  Widget? _suffix() => switch (state.usernameStatus) {
        UsernameStatus.checking => const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: CkColors.soft),
            ),
          ),
        UsernameStatus.available =>
          const Icon(Icons.check_circle, color: CkColors.green, size: 20),
        UsernameStatus.taken || UsernameStatus.invalid =>
          const Icon(Icons.error_outline, color: CkColors.red, size: 20),
        UsernameStatus.idle => null,
      };

  String? _message() => switch (state.usernameStatus) {
        UsernameStatus.available => '@${state.username} is available',
        UsernameStatus.taken ||
        UsernameStatus.invalid =>
          state.usernameMessage,
        UsernameStatus.idle => state.usernameMessage,
        UsernameStatus.checking => null,
      };

  Color _messageColor() => state.usernameStatus == UsernameStatus.available
      ? CkColors.green
      : CkColors.red;

  IconData _messageIcon() => state.usernameStatus == UsernameStatus.available
      ? Icons.check_circle
      : Icons.error_outline;
}

// ─── Step 2: Player ─────────────────────────────────────────────────────────────

class _PlayerStep extends StatelessWidget {
  const _PlayerStep({required this.state, required this.controller});
  final OnboardingState state;
  final OnboardingController controller;

  static const _roles = {
    PlayerRole.batter: 'Batter',
    PlayerRole.bowler: 'Bowler',
    PlayerRole.allRounder: 'All-rounder',
    PlayerRole.keeper: 'Keeper',
  };
  static const _batting = {
    BattingStyle.rightHand: 'Right-hand',
    BattingStyle.leftHand: 'Left-hand',
  };
  static const _bowling = {
    BowlingStyle.rightArmFast: 'Right-arm fast',
    BowlingStyle.rightArmSpin: 'Right-arm spin',
    BowlingStyle.leftArmFast: 'Left-arm fast',
    BowlingStyle.leftArmSpin: 'Left-arm spin',
    BowlingStyle.doesntBowl: "Doesn't bowl",
  };
  static const _balls = {
    BallType.leather: 'Leather',
    BallType.tape: 'Tape',
    BallType.tennis: 'Tennis',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: CkColors.cream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Optional',
                    style: CkType.mono(fontSize: 10, color: CkColors.ink2)),
              ),
              const SizedBox(height: 10),
              Text('Are you a cricket player?',
                  style: CkType.display(fontSize: 28)),
              const SizedBox(height: 4),
              Text('Add your style so teams can scout you. You can edit later.',
                  style: CkType.body(fontSize: 14, color: CkColors.muted)),
              const SizedBox(height: 22),
              const _FieldLabel('Role'),
              const SizedBox(height: 10),
              _PillGroup(
                entries: _roles,
                selected: state.role,
                onTap: controller.setRole,
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Batting'),
              const SizedBox(height: 10),
              _PillGroup(
                entries: _batting,
                selected: state.battingStyle,
                onTap: controller.setBatting,
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Bowling'),
              const SizedBox(height: 10),
              _PillGroup(
                entries: _bowling,
                selected: state.bowlingStyle,
                onTap: controller.setBowling,
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Preferred ball'),
              const SizedBox(height: 10),
              _PillGroup(
                entries: _balls,
                selected: state.preferredBall,
                onTap: controller.setPreferredBall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              CkButton(
                label: 'Save profile',
                busy: state.submitting,
                onPressed: () => controller.submit(asPlayer: true),
              ),
              const SizedBox(height: 8),
              CkButton.ghost(
                label: 'Skip — I just watch',
                onPressed: state.submitting
                    ? null
                    : () => controller.submit(asPlayer: false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single-select group of pill buttons over an enum→label map.
class _PillGroup<T> extends StatelessWidget {
  const _PillGroup({
    required this.entries,
    required this.selected,
    required this.onTap,
  });

  final Map<T, String> entries;
  final T? selected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in entries.entries)
          _Pill(
            label: entry.value,
            active: entry.key == selected,
            onTap: () => onTap(entry.key),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? CkColors.ink : CkColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? CkColors.ink : CkColors.line,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? CkColors.paper : CkColors.ink,
          ),
        ),
      ),
    );
  }
}

// ─── Step 3: Welcome ─────────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.state, required this.controller});
  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final firstName = state.displayName.trim().split(' ').first;
    return Column(
      children: [
        const SizedBox(height: 24),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: CkColors.greenSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: CkColors.green, size: 38),
              ),
              const SizedBox(height: 16),
              Text(
                "You're in,\n${firstName.isEmpty ? 'player' : firstName}.",
                textAlign: TextAlign.center,
                style: CkType.display(fontSize: 30, height: 1.05),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: CkButton(
            label: 'Go to home',
            busy: state.completed,
            onPressed: controller.finish,
          ),
        ),
      ],
    );
  }
}

// ─── Shared ─────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: CkType.body(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CkColors.ink2,
        ),
      );
}
