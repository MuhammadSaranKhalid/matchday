import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../controllers/onboarding_controller.dart';
import '../state/onboarding_state.dart';

/// Post-auth onboarding wizard: identity → username → welcome.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onboardingControllerProvider, (prev, next) {
      final s = next.value;
      if (s == null) return;
      if (s.completed) {
        context.go('/home');
      } else if (s.submitError != null &&
          prev?.value?.submitError != s.submitError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.submitError!)));
      }
    });

    final async = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final state = async.value;
    final labelStyle = CkType.body(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: CkColors.ink2,
    );

    // Side-effect on every build with data: seed text fields once and keep
    // them in sync with controller-driven mutations (stripped char).
    if (state != null) {
      if (!_seeded) {
        _name.text = state.displayName;
        _username.text = state.username;
        _seeded = true;
      }
      if (_username.text != state.username) {
        _username.value = TextEditingValue(
          text: state.username,
          selection: TextSelection.collapsed(offset: state.username.length),
        );
      }
    }

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (async) {
          AsyncError() => const Center(child: Text('Something went wrong')),
          AsyncData(:final value) => Column(
            children: [
              // ─── Top bar ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    Opacity(
                      opacity: value.step == OnboardingStep.username ? 1 : 0,
                      child: IconButton(
                        onPressed:
                            value.step == OnboardingStep.username
                                ? controller.back
                                : null,
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'matchday',
                            style: CkType.display(
                              fontSize: 22,
                              letterSpacing: -0.045,
                            ),
                          ),
                          TextSpan(
                            text: '.',
                            style: CkType.display(
                              fontSize: 22,
                              letterSpacing: -0.045,
                              color: CkColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ─── Step dots ──────────────────────────────────────────────────
              if (value.step != OnboardingStep.welcome)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: Row(
                    children: [
                      for (
                        var i = 0;
                        i < OnboardingStep.values.length;
                        i++
                      ) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color:
                                  i <= value.step.index
                                      ? CkColors.ink
                                      : CkColors.hairline,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // ─── Step body ──────────────────────────────────────────────────
              Expanded(
                child: switch (value.step) {
                  // ── Step 1: Identity ───────────────────────────────────────
                  OnboardingStep.identity => Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                          children: [
                            Text(
                              'Set up your profile',
                              style: CkType.display(fontSize: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Let teams know who you are.',
                              style: CkType.body(
                                fontSize: 14,
                                color: CkColors.muted,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Avatar Upload
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Semantics(
                                    button: true,
                                    label: 'Add a profile photo, optional',
                                    child: GestureDetector(
                                      onTap: controller.pickAvatar,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 96,
                                            height: 96,
                                            decoration: BoxDecoration(
                                              color: CkColors.surface,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: CkColors.line,
                                              ),
                                              image:
                                                  value.avatarPath != null
                                                      ? DecorationImage(
                                                        image: FileImage(
                                                          File(
                                                            value.avatarPath!,
                                                          ),
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                      : value.remoteAvatarUrl !=
                                                          null
                                                      ? DecorationImage(
                                                        image: NetworkImage(
                                                          value
                                                              .remoteAvatarUrl!,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                      : null,
                                            ),
                                            child:
                                                value.avatarPath == null &&
                                                        value.remoteAvatarUrl ==
                                                            null
                                                    ? const Icon(
                                                      Icons.person_outline,
                                                      size: 42,
                                                      color: CkColors.soft,
                                                    )
                                                    : null,
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: CkColors.ink,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: CkColors.paper,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                size: 16,
                                                color: CkColors.paper,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Profile photo (optional)',
                                    style: CkType.body(
                                      fontSize: 12,
                                      color: CkColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Display name
                            Text('Display name', style: labelStyle),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _name,
                              onChanged: controller.setDisplayName,
                              textInputAction: TextInputAction.done,
                              style: CkType.body(fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Ahmed Khan',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        child: CkButton(
                          label: 'Continue',
                          onPressed:
                              value.canContinueIdentity
                                  ? controller.continueToUsername
                                  : null,
                        ),
                      ),
                    ],
                  ),

                  // ── Step 2: Username ───────────────────────────────────────
                  OnboardingStep.username => Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                          children: [
                            Text(
                              'Pick a username',
                              style: CkType.display(fontSize: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This is how others will find you and mention you.',
                              style: CkType.body(
                                fontSize: 14,
                                color: CkColors.muted,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Username
                            Text('Username', style: labelStyle),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _username,
                              onChanged: controller.setUsername,
                              autofocus: true,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(20),
                                FilteringTextInputFormatter.allow(
                                  RegExp('[a-zA-Z0-9_]'),
                                ),
                              ],
                              style: CkType.body(fontSize: 16),
                              decoration: InputDecoration(
                                prefixText: '@',
                                prefixStyle: CkType.body(
                                  fontSize: 16,
                                  color: CkColors.soft,
                                ),
                                hintText: 'ahmed_khan',
                                suffixIcon: switch (value.usernameStatus) {
                                  UsernameStatus.checking => const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: CkColors.soft,
                                      ),
                                    ),
                                  ),
                                  UsernameStatus.available => const Icon(
                                    Icons.check_circle,
                                    color: CkColors.green,
                                    size: 20,
                                  ),
                                  UsernameStatus.taken ||
                                  UsernameStatus.invalid => const Icon(
                                    Icons.error_outline,
                                    color: CkColors.red,
                                    size: 20,
                                  ),
                                  UsernameStatus.idle => null,
                                },
                              ),
                            ),
                            if (value.usernameStatus !=
                                    UsernameStatus.checking &&
                                (value.usernameStatus ==
                                        UsernameStatus.available ||
                                    value.usernameMessage != null)) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    value.usernameStatus ==
                                            UsernameStatus.available
                                        ? Icons.check_circle
                                        : Icons.error_outline,
                                    size: 14,
                                    color:
                                        value.usernameStatus ==
                                                UsernameStatus.available
                                            ? CkColors.green
                                            : CkColors.red,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    value.usernameStatus ==
                                            UsernameStatus.available
                                        ? '@${value.username} is available'
                                        : value.usernameMessage!,
                                    style: CkType.body(
                                      fontSize: 12,
                                      color:
                                          value.usernameStatus ==
                                                  UsernameStatus.available
                                              ? CkColors.green
                                              : CkColors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        child: CkButton(
                          label: 'Save profile',
                          busy: value.submitting,
                          onPressed:
                              value.canSubmitUsername
                                  ? controller.submit
                                  : null,
                        ),
                      ),
                    ],
                  ),

                  // ── Step 3: Welcome ────────────────────────────────────────
                  OnboardingStep.welcome => Column(
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
                              child: const Icon(
                                Icons.check_rounded,
                                color: CkColors.green,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "You're in,\n${(value.displayName.trim().split(' ').first).isEmpty ? 'player' : value.displayName.trim().split(' ').first}.",
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
                          busy: value.completed,
                          onPressed: controller.finish,
                        ),
                      ),
                    ],
                  ),
                },
              ),
            ],
          ),
          _ => const Center(
            child: CircularProgressIndicator(color: CkColors.ink),
          ),
        },
      ),
    );
  }
}
