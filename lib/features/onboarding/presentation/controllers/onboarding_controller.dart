import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/database/database_provider.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/usecases/complete_onboarding.dart';
import '../../domain/value_objects/username.dart';
import '../providers/onboarding_providers.dart';
import '../state/onboarding_state.dart';

part 'onboarding_controller.g.dart';

/// Drives the onboarding wizard: profile → player → welcome.
///
/// An [AsyncNotifier] so [build] can restore a persisted draft before the form
/// seeds. Once loaded, sub-states (username checking, submitting) live as
/// fields on [OnboardingState] rather than flipping the [AsyncValue] to
/// loading, so the form never disappears mid-edit.
@riverpod
class OnboardingController extends _$OnboardingController {
  Timer? _usernameDebounce;

  // Constant key is safe: AppDatabase.clear() wipes all wizard drafts on
  // sign-out, so a different user on the same device never inherits this one.
  static const _draftKey = 'onboarding';

  @override
  Future<OnboardingState> build() async {
    ref.onDispose(() => _usernameDebounce?.cancel());

    final draft = await ref.read(wizardDraftStoreProvider).load(_draftKey);
    var initial =
        draft == null ? const OnboardingState() : _fromDraft(draft);

    // A restored username needs re-verifying — availability can change between
    // sessions and we never persist the "available" verdict.
    if (initial.username.isNotEmpty &&
        Username.create(initial.username).isRight()) {
      initial = initial.copyWith(usernameStatus: UsernameStatus.checking);
      _scheduleAvailabilityCheck(initial.username);
    }
    return initial;
  }

  OnboardingState? get _s => state.value;

  void _set(OnboardingState next, {bool persist = true}) {
    state = AsyncData(next);
    if (persist && !next.completed) _persistDraft(next);
  }

  // ─── Profile step ─────────────────────────────────────────────────────────

  void setDisplayName(String value) {
    final s = _s;
    if (s == null) return;
    _set(s.copyWith(displayName: value));
  }

  void setCity(String value) {
    final s = _s;
    if (s == null) return;
    _set(s.copyWith(city: value));
  }

  /// Cleans input to the allowed charset, validates format synchronously for
  /// instant feedback, then debounces the network availability check.
  void setUsername(String raw) {
    final s = _s;
    if (s == null) return;
    final cleaned =
        raw.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '');

    if (cleaned.isEmpty) {
      _usernameDebounce?.cancel();
      _set(s.copyWith(
        username: '',
        usernameStatus: UsernameStatus.idle,
        usernameMessage: null,
      ));
      return;
    }

    Username.create(cleaned).fold(
      (failure) {
        _usernameDebounce?.cancel();
        _set(s.copyWith(
          username: cleaned,
          usernameStatus: UsernameStatus.invalid,
          usernameMessage: failure.message,
        ));
      },
      (_) {
        _set(s.copyWith(
          username: cleaned,
          usernameStatus: UsernameStatus.checking,
          usernameMessage: null,
        ));
        _scheduleAvailabilityCheck(cleaned);
      },
    );
  }

  void _scheduleAvailabilityCheck(String username) {
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final result =
          await ref.read(checkUsernameAvailableUseCaseProvider).call(username);
      // Bail if the user kept typing while we were checking.
      final s = _s;
      if (s == null || s.username != username) return;

      result.fold(
        (failure) {
          if (failure is ValidationFailure) {
            _set(s.copyWith(
              usernameStatus: UsernameStatus.invalid,
              usernameMessage: failure.message,
            ), persist: false);
          } else {
            // Couldn't reach the backend — let the user retry by editing.
            _set(s.copyWith(
              usernameStatus: UsernameStatus.idle,
              usernameMessage: "Couldn't check — check your connection",
            ), persist: false);
          }
        },
        (available) => _set(s.copyWith(
          usernameStatus:
              available ? UsernameStatus.available : UsernameStatus.taken,
          usernameMessage: available ? null : 'That username is taken',
        ), persist: false),
      );
    });
  }

  void continueToPlayer() {
    final s = _s;
    if (s == null || !s.canContinueProfile) return;
    _set(s.copyWith(step: OnboardingStep.player));
  }

  // ─── Player step ──────────────────────────────────────────────────────────

  void setRole(PlayerRole role) =>
      _toggle((s) => s.copyWith(role: s.role == role ? null : role));
  void setBatting(BattingStyle b) => _toggle(
      (s) => s.copyWith(battingStyle: s.battingStyle == b ? null : b));
  void setBowling(BowlingStyle b) => _toggle(
      (s) => s.copyWith(bowlingStyle: s.bowlingStyle == b ? null : b));
  void setPreferredBall(BallType b) => _toggle(
      (s) => s.copyWith(preferredBall: s.preferredBall == b ? null : b));

  void _toggle(OnboardingState Function(OnboardingState) f) {
    final s = _s;
    if (s == null) return;
    _set(f(s));
  }

  void back() {
    final s = _s;
    if (s == null) return;
    if (s.step == OnboardingStep.player) {
      _set(s.copyWith(step: OnboardingStep.profile));
    }
  }

  /// Persist the profile to the backend. Called by both "Save profile"
  /// ([asPlayer] true) and "Skip — I just watch" ([asPlayer] false). On success
  /// advances to the welcome step (but does NOT yet open the gate — see
  /// [finish]).
  Future<void> submit({required bool asPlayer}) async {
    final s = _s;
    if (s == null || s.submitting) return;
    _set(s.copyWith(submitting: true, submitError: null, isPlayer: asPlayer),
        persist: false);

    final params = CompleteOnboardingParams(
      displayName: s.displayName,
      username: s.username,
      city: s.city,
      playerProfile: asPlayer ? s.playerProfile : null,
    );
    final result =
        await ref.read(completeOnboardingUseCaseProvider).call(params);

    final current = _s;
    if (current == null) return;
    result.fold(
      (failure) => _set(
        current.copyWith(submitting: false, submitError: failure.message),
        persist: false,
      ),
      (_) => _set(
        current.copyWith(submitting: false, step: OnboardingStep.welcome),
        persist: false,
      ),
    );
  }

  // ─── Welcome step ───────────────────────────────────────────────────────────

  /// Tapped "Open feed". Clears the draft and invalidates the onboarding-status
  /// provider so the router gate now lets the user into /home, then flips
  /// [OnboardingState.completed] for the screen to navigate on.
  Future<void> finish() async {
    final s = _s;
    if (s == null) return;
    await ref.read(wizardDraftStoreProvider).clear(_draftKey);
    ref.invalidate(onboardingStatusProvider);
    _set(s.copyWith(completed: true), persist: false);
  }

  // ─── Draft (de)serialization ──────────────────────────────────────────────

  void _persistDraft(OnboardingState s) {
    // Fire-and-forget; the store swallows failures.
    ref.read(wizardDraftStoreProvider).save(_draftKey, _toDraft(s));
  }

  Map<String, dynamic> _toDraft(OnboardingState s) => {
        'step': s.step.name,
        'displayName': s.displayName,
        'username': s.username,
        'city': s.city,
        'isPlayer': s.isPlayer,
        'role': s.role?.wire,
        'battingStyle': s.battingStyle?.wire,
        'bowlingStyle': s.bowlingStyle?.wire,
        'preferredBall': s.preferredBall?.wire,
      };

  OnboardingState _fromDraft(Map<String, dynamic> m) => OnboardingState(
        step: OnboardingStep.values.firstWhere(
          (e) => e.name == m['step'],
          orElse: () => OnboardingStep.profile,
        ),
        displayName: m['displayName'] as String? ?? '',
        username: m['username'] as String? ?? '',
        city: m['city'] as String? ?? '',
        isPlayer: m['isPlayer'] as bool? ?? false,
        role: PlayerRole.fromWire(m['role'] as String?),
        battingStyle: BattingStyle.fromWire(m['battingStyle'] as String?),
        bowlingStyle: BowlingStyle.fromWire(m['bowlingStyle'] as String?),
        preferredBall: BallType.fromWire(m['preferredBall'] as String?),
      );
}
