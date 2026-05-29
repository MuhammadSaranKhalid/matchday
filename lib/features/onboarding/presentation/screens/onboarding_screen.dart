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
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _city = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _city.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.submitError!)),
        );
      }
    });

    final async = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final state = async.value;
    final hasGeo =
        state != null && state.profile.lat != null && state.profile.lng != null;
    final labelStyle = CkType.body(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: CkColors.ink2,
    );

    // Side-effect on every build with data: seed text fields once and keep
    // them in sync with controller-driven mutations (stripped char, GPS label).
    if (state != null) {
      if (!_seeded) {
        _name.text = state.profile.displayName;
        _username.text = state.profile.username;
        _city.text = state.profile.city;
        _seeded = true;
      }
      if (_username.text != state.profile.username) {
        _username.value = TextEditingValue(
          text: state.profile.username,
          selection: TextSelection.collapsed(
              offset: state.profile.username.length),
        );
      }
      if (_city.text != state.profile.city) {
        _city.value = TextEditingValue(
          text: state.profile.city,
          selection:
              TextSelection.collapsed(offset: state.profile.city.length),
        );
      }
    }

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (async) {
          AsyncError() =>
            const Center(child: Text('Something went wrong')),
          AsyncData(:final value) => Column(
              children: [
            // ─── Top bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Opacity(
                    opacity: value.step == OnboardingStep.player ? 1 : 0,
                    child: IconButton(
                      onPressed: value.step == OnboardingStep.player
                          ? controller.back
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: CkColors.ink),
                    ),
                  ),
                  const Spacer(),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'circk',
                        style: CkType.display(
                            fontSize: 22, letterSpacing: -0.045)),
                    TextSpan(
                        text: '.',
                        style: CkType.display(
                            fontSize: 22,
                            letterSpacing: -0.045,
                            color: CkColors.red)),
                  ])),
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
                    for (var i = 0;
                        i < OnboardingStep.values.length;
                        i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: i <= value.step.index
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
                // ── Step 1: Profile ────────────────────────────────────────
                OnboardingStep.profile => Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                          children: [
                            Text('Set up your profile',
                                style: CkType.display(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text('So teams can find you.',
                                style: CkType.body(
                                    fontSize: 14, color: CkColors.muted)),
                            const SizedBox(height: 22),

                            // Display name
                            Text('Display name', style: labelStyle),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _name,
                              onChanged: controller.setDisplayName,
                              textInputAction: TextInputAction.next,
                              style: CkType.body(fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Ahmed Khan',
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Username
                            Text('Username', style: labelStyle),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _username,
                              onChanged: controller.setUsername,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(20),
                                FilteringTextInputFormatter.allow(
                                    RegExp('[a-zA-Z0-9_]')),
                              ],
                              style: CkType.body(fontSize: 16),
                              decoration: InputDecoration(
                                prefixText: '@',
                                prefixStyle: CkType.body(
                                    fontSize: 16, color: CkColors.soft),
                                hintText: 'ahmed_khan',
                                suffixIcon: switch (value.profile.usernameStatus) {
                                  UsernameStatus.checking => const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: CkColors.soft),
                                      ),
                                    ),
                                  UsernameStatus.available => const Icon(
                                      Icons.check_circle,
                                      color: CkColors.green,
                                      size: 20),
                                  UsernameStatus.taken ||
                                  UsernameStatus.invalid =>
                                    const Icon(Icons.error_outline,
                                        color: CkColors.red, size: 20),
                                  UsernameStatus.idle => null,
                                },
                              ),
                            ),
                            if (value.profile.usernameStatus !=
                                    UsernameStatus.checking &&
                                (value.profile.usernameStatus ==
                                        UsernameStatus.available ||
                                    value.profile.usernameMessage != null)) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    value.profile.usernameStatus ==
                                            UsernameStatus.available
                                        ? Icons.check_circle
                                        : Icons.error_outline,
                                    size: 14,
                                    color: value.profile.usernameStatus ==
                                            UsernameStatus.available
                                        ? CkColors.green
                                        : CkColors.red,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    value.profile.usernameStatus ==
                                            UsernameStatus.available
                                        ? '@${value.profile.username} is available'
                                        : value.profile.usernameMessage!,
                                    style: CkType.body(
                                      fontSize: 12,
                                      color: value.profile.usernameStatus ==
                                              UsernameStatus.available
                                          ? CkColors.green
                                          : CkColors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 18),

                            // City
                            Text('City / village', style: labelStyle),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _city,
                              onChanged: controller.setCity,
                              style: CkType.body(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Start typing your city or village',
                                prefixIcon: const Icon(
                                    Icons.location_on_outlined,
                                    color: CkColors.red,
                                    size: 20),
                                suffixIcon: value.profile.citySearching
                                    ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: CkColors.soft),
                                        ),
                                      )
                                    : (hasGeo
                                        ? const Icon(Icons.check_circle,
                                            color: CkColors.green, size: 20)
                                        : null),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: value.profile.locating
                                    ? null
                                    : controller.useMyLocation,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: value.profile.locating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: CkColors.soft),
                                      )
                                    : const Icon(Icons.my_location,
                                        size: 16, color: CkColors.ink2),
                                label: Text(
                                  value.profile.locating
                                      ? 'Locating…'
                                      : 'Use my current location',
                                  style: CkType.body(
                                      fontSize: 13, color: CkColors.ink2),
                                ),
                              ),
                            ),
                            if (value.profile.cityError != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 2, left: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 14, color: CkColors.red),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(value.profile.cityError!,
                                          style: CkType.body(
                                              fontSize: 12,
                                              color: CkColors.red)),
                                    ),
                                  ],
                                ),
                              ),
                            if (value.profile.city.trim().isNotEmpty &&
                                !hasGeo &&
                                !value.profile.citySearching &&
                                !value.profile.locating &&
                                value.profile.cityError == null &&
                                value.profile.citySuggestions.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, left: 4),
                                child: Text(
                                  "We'll pinpoint this when you continue — or pick a suggestion / use your current location.",
                                  style: CkType.body(
                                      fontSize: 12, color: CkColors.muted),
                                ),
                              ),
                            if (value.profile.citySuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: CkColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: CkColors.line),
                                ),
                                child: Column(
                                  children: [
                                    for (var i = 0;
                                        i < value.profile.citySuggestions.length;
                                        i++) ...[
                                      if (i > 0)
                                        const Divider(
                                            height: 1,
                                            color: CkColors.hairline),
                                      InkWell(
                                        onTap: () =>
                                            controller.selectCitySuggestion(
                                                value.profile.citySuggestions[i]),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 12),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.place_outlined,
                                                  size: 18,
                                                  color: CkColors.soft),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      value.profile.citySuggestions[i]
                                                          .primaryText,
                                                      style: CkType.body(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                    if (value.profile
                                                            .citySuggestions[
                                                                i]
                                                            .secondaryText !=
                                                        null) ...[
                                                      const SizedBox(
                                                          height: 2),
                                                      Text(
                                                        value.profile
                                                            .citySuggestions[
                                                                i]
                                                            .secondaryText!,
                                                        style: CkType.body(
                                                            fontSize: 12,
                                                            color: CkColors
                                                                .muted),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        child: CkButton(
                          label: 'Continue',
                          busy: value.profile.resolvingLocation,
                          onPressed: (value.canContinueProfile &&
                                  !value.profile.resolvingLocation)
                              ? controller.continueToPlayer
                              : null,
                        ),
                      ),
                    ],
                  ),

                // ── Step 2: Player ─────────────────────────────────────────
                OnboardingStep.player => Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: CkColors.cream,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('Optional',
                                  style: CkType.mono(
                                      fontSize: 10, color: CkColors.ink2)),
                            ),
                            const SizedBox(height: 10),
                            Text('Are you a cricket player?',
                                style: CkType.display(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(
                                'Add your style so teams can scout you. You can edit later.',
                                style: CkType.body(
                                    fontSize: 14, color: CkColors.muted)),
                            const SizedBox(height: 22),

                            Text('Role', style: labelStyle),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final e in const {
                                  PlayerRole.batter: 'Batter',
                                  PlayerRole.bowler: 'Bowler',
                                  PlayerRole.allRounder: 'All-rounder',
                                  PlayerRole.wicketKeeper: 'Keeper',
                                }.entries)
                                  _pill(
                                    label: e.value,
                                    active: value.player.role == e.key,
                                    onTap: () => controller.setRole(e.key),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 18),
                            Text('Batting', style: labelStyle),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final e in const {
                                  BattingStyle.rightHand: 'Right-hand',
                                  BattingStyle.leftHand: 'Left-hand',
                                }.entries)
                                  _pill(
                                    label: e.value,
                                    active: value.player.battingStyle == e.key,
                                    onTap: () => controller.setBatting(e.key),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 18),
                            Text('Bowling', style: labelStyle),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final e in const {
                                  BowlingStyle.rightArmFast: 'Right-arm fast',
                                  BowlingStyle.rightArmMedium:
                                      'Right-arm medium',
                                  BowlingStyle.rightArmSpin: 'Right-arm spin',
                                  BowlingStyle.leftArmFast: 'Left-arm fast',
                                  BowlingStyle.leftArmSpin: 'Left-arm spin',
                                  BowlingStyle.doesntBowl: "Doesn't bowl",
                                }.entries)
                                  _pill(
                                    label: e.value,
                                    active: value.player.bowlingStyle == e.key,
                                    onTap: () => controller.setBowling(e.key),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 18),
                            Text('Preferred ball', style: labelStyle),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final e in const {
                                  BallType.leather: 'Leather',
                                  BallType.tape: 'Tape',
                                  BallType.tennis: 'Tennis',
                                }.entries)
                                  _pill(
                                    label: e.value,
                                    active: value.player.preferredBall == e.key,
                                    onTap: () =>
                                        controller.setPreferredBall(e.key),
                                  ),
                              ],
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
                              busy: value.submitting,
                              onPressed: () =>
                                  controller.submit(asPlayer: true),
                            ),
                            const SizedBox(height: 8),
                            CkButton.ghost(
                              label: 'Skip — I just watch',
                              onPressed: value.submitting
                                  ? null
                                  : () => controller.submit(asPlayer: false),
                            ),
                          ],
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
                              child: const Icon(Icons.check_rounded,
                                  color: CkColors.green, size: 38),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "You're in,\n${(value.profile.displayName.trim().split(' ').first).isEmpty ? 'player' : value.profile.displayName.trim().split(' ').first}.",
                              textAlign: TextAlign.center,
                              style:
                                  CkType.display(fontSize: 30, height: 1.05),
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
              child: CircularProgressIndicator(color: CkColors.ink)),
        },
      ),
    );
  }

  /// Pill button used 15× across the player step. Kept as a method (not a
  /// widget class) so the screen stays a single tree.
  Widget _pill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
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
