import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/value_objects/display_name.dart';
import '../../domain/value_objects/username.dart';
import '../providers/onboarding_providers.dart';
import '../state/onboarding_state.dart';

part 'onboarding_controller.g.dart';

/// Drives the onboarding wizard: identity → username → welcome.
///
/// An [AsyncNotifier] so sub-states (username checking, submitting) live as
/// fields on [OnboardingState] rather than flipping the [AsyncValue] to
/// loading, so the form never disappears mid-edit.
@riverpod
class OnboardingController extends _$OnboardingController {
  Timer? _usernameDebounce;

  @override
  Future<OnboardingState> build() async {
    ref.onDispose(() {
      _usernameDebounce?.cancel();
    });

    return const OnboardingState();
  }

  OnboardingState? get _s => state.value;

  void _set(OnboardingState next) {
    state = AsyncData(next);
  }

  // ─── Step 1: Identity ─────────────────────────────────────────────────────

  void setDisplayName(String value) {
    final s = _s;
    if (s == null) return;
    _set(s.copyWith(displayName: value));
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final s = _s;
      if (s == null) return;
      _set(s.copyWith(avatarPath: file.path));
    }
  }

  void continueToUsername() {
    final s = _s;
    if (s == null || !s.canContinueIdentity) return;
    _set(s.copyWith(step: OnboardingStep.username));
  }

  // ─── Step 2: Username ─────────────────────────────────────────────────────

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
      // Re-validate format before hitting the network — caller already did,
      // but the contract is "valid Username → repo lookup".
      final usernameRes = Username.create(username);
      final result = await usernameRes.fold(
        (failure) async => Left<Failure, bool>(failure),
        (vo) async =>
            ref.read(profileRepositoryProvider).isUsernameAvailable(vo.value),
      );
      // Bail if the user kept typing while we were checking.
      final s = _s;
      if (s == null || s.username != username) return;

      result.fold(
        (failure) {
          if (failure is ValidationFailure) {
            _set(s.copyWith(
              usernameStatus: UsernameStatus.invalid,
              usernameMessage: failure.message,
            ));
          } else {
            // Couldn't reach the backend — let the user retry by editing.
            _set(s.copyWith(
              usernameStatus: UsernameStatus.idle,
              usernameMessage: "Couldn't check — check your connection",
            ));
          }
        },
        (available) => _set(s.copyWith(
          usernameStatus:
              available ? UsernameStatus.available : UsernameStatus.taken,
          usernameMessage: available ? null : 'That username is taken',
        )),
      );
    });
  }

  void back() {
    final s = _s;
    if (s == null) return;
    if (s.step == OnboardingStep.username) {
      _set(s.copyWith(step: OnboardingStep.identity));
    }
  }

  /// Persist the profile to the backend. On success
  /// advances to the welcome step (but does NOT yet open the gate — see
  /// [finish]).
  Future<void> submit() async {
    final s = _s;
    if (s == null || s.submitting || !s.canSubmitUsername) return;
    _set(s.copyWith(
      submitting: true,
      submitError: null,
    ));

    // Validate inputs via value objects; the first failure short-circuits and
    // is surfaced as the submitError so the form can render it.
    final displayNameRes = DisplayName.create(s.displayName);
    final usernameRes = Username.create(s.username);

    Failure? failure;
    for (final e in <Either<Failure, Object>>[
      displayNameRes,
      usernameRes,
    ]) {
      final f = e.getLeft().toNullable();
      if (f != null) {
        failure = f;
        break;
      }
    }
    if (failure != null) {
      final current = _s;
      if (current == null) return;
      _set(current.copyWith(submitting: false, submitError: failure.message));
      return;
    }

    final result = await ref.read(profileRepositoryProvider).completeOnboarding(
          displayName: displayNameRes.getRight().toNullable()!,
          username: usernameRes.getRight().toNullable()!,
          avatarFilePath: s.avatarPath,
        );

    final current = _s;
    if (current == null) return;
    result.fold(
      (failure) => _set(
        current.copyWith(submitting: false, submitError: failure.message),
      ),
      (_) => _set(
        current.copyWith(submitting: false, step: OnboardingStep.welcome),
      ),
    );
  }

  // ─── Welcome step ───────────────────────────────────────────────────────────

  /// Tapped "Open feed". Invalidates the onboarding-status
  /// provider so the router gate now lets the user into /home, then flips
  /// [OnboardingState.completed] for the screen to navigate on.
  Future<void> finish() async {
    final s = _s;
    if (s == null) return;
    ref.invalidate(onboardingStatusProvider);
    _set(s.copyWith(completed: true));
  }
}
