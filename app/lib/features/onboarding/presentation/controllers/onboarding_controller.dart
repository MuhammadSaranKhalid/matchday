import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../profile/domain/value_objects/display_name.dart';
import '../../../profile/domain/value_objects/username.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
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

    // The profile shell is created by the auth trigger. For a freshly-created
    // account, prefer the current identity metadata because it is available
    // immediately even when a project still has the older profile trigger.
    // This metadata is presentation data only; it is never used for access
    // control or authorization.
    final profileResult =
        await ref.read(profileRepositoryProvider).getMyProfile();
    final profile = profileResult.getRight().toNullable();
    final metadata =
        ref.read(supabaseClientProvider).auth.currentUser?.userMetadata ??
        const <String, dynamic>{};
    // Supabase's documented Google identity fields. The current account's
    // payload also contains these exact keys; do not fall back to provider
    // aliases because that would make the profile contract ambiguous.
    final authName = _metadataText(metadata['full_name']);
    final authAvatar = _httpsUrl(_metadataText(metadata['avatar_url']));
    final storedName = _usableName(profile?.displayName);
    final isNewProfile = profile?.onboardedAt == null;

    return OnboardingState(
      displayName:
          isNewProfile ? (authName ?? storedName ?? '') : (storedName ?? ''),
      remoteAvatarUrl: _httpsUrl(profile?.avatarUrl) ?? authAvatar,
    );
  }

  static String? _metadataText(Object? value) {
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  static String? _usableName(String? value) {
    final name = value?.trim();
    return name == null || name.isEmpty || name == 'New User' ? null : name;
  }

  static String? _httpsUrl(String? value) {
    final uri = value == null ? null : Uri.tryParse(value.trim());
    return uri != null && uri.hasAuthority && uri.scheme == 'https'
        ? uri.toString()
        : null;
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

    final cleaned = raw.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '');

    if (cleaned.isEmpty) {
      _usernameDebounce?.cancel();
      _set(
        s.copyWith(
          username: '',
          usernameStatus: UsernameStatus.idle,
          usernameMessage: null,
        ),
      );
      return;
    }

    Username.create(cleaned).fold(
      (failure) {
        _usernameDebounce?.cancel();
        _set(
          s.copyWith(
            username: cleaned,
            usernameStatus: UsernameStatus.invalid,
            usernameMessage: failure.message,
          ),
        );
      },
      (_) {
        _set(
          s.copyWith(
            username: cleaned,
            usernameStatus: UsernameStatus.checking,
            usernameMessage: null,
          ),
        );
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
            _set(
              s.copyWith(
                usernameStatus: UsernameStatus.invalid,
                usernameMessage: failure.message,
              ),
            );
          } else {
            // Couldn't reach the backend — let the user retry by editing.
            _set(
              s.copyWith(
                usernameStatus: UsernameStatus.idle,
                usernameMessage: "Couldn't check — check your connection",
              ),
            );
          }
        },
        (available) => _set(
          s.copyWith(
            usernameStatus:
                available ? UsernameStatus.available : UsernameStatus.taken,
            usernameMessage: available ? null : 'That username is taken',
          ),
        ),
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
    _set(s.copyWith(submitting: true, submitError: null));

    // Validate inputs via value objects; the first failure short-circuits and
    // is surfaced as the submitError so the form can render it.
    final displayNameRes = DisplayName.create(s.displayName);
    final usernameRes = Username.create(s.username);

    Failure? failure;
    for (final e in <Either<Failure, Object>>[displayNameRes, usernameRes]) {
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

    final result = await ref
        .read(profileRepositoryProvider)
        .completeOnboarding(
          displayName: displayNameRes.getRight().toNullable()!,
          username: usernameRes.getRight().toNullable()!,
          avatarFilePath: s.avatarPath,
          existingAvatarUrl: s.remoteAvatarUrl,
        );

    final current = _s;
    if (current == null) return;
    result.fold(
      (failure) => _set(
        current.copyWith(submitting: false, submitError: failure.message),
      ),
      (_) {
        // The profile is now complete on the server. Do not add a redundant
        // success screen and another tap before the user can reach Home.
        ref.invalidate(onboardingStatusProvider);
        _set(current.copyWith(submitting: false, completed: true));
      },
    );
  }

  // ─── Welcome step ───────────────────────────────────────────────────────────

  /// Retained for the success-state UI while the route is transitioning.
  Future<void> finish() async {
    final s = _s;
    if (s == null) return;
    ref.invalidate(onboardingStatusProvider);
    _set(s.copyWith(completed: true));
  }
}
