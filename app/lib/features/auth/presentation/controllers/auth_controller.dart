import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../notifications/presentation/controllers/push_registrar.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/otp_code.dart';
import '../providers/auth_providers.dart';
import '../state/auth_state.dart';

part 'auth_controller.g.dart';

/// Auth controller for email-OTP + Google sign-in.
///
/// Notifier (not AsyncNotifier) because the initial state is synchronous
/// (AuthInitial) and the multiple sub-states of the OTP flow are better
/// represented by a sealed class than by AsyncValue.
@riverpod
class AuthController extends _$AuthController {
  @override
  AuthFlowState build() => const AuthInitial();

  // ─── Email OTP ──────────────────────────────────────────────────────────

  Future<void> sendOtp(String rawEmail) async {
    final emailResult = Email.create(rawEmail);
    switch (emailResult) {
      case Left(value: final failure):
        state = AuthFailed(failure);
      case Right(value: final email):
        state = const AuthSendingOtp();
        final result = await ref
            .read(authRepositoryProvider)
            .sendEmailOtp(email);
        state = result.fold(
          (f) => AuthFailed(f, email: email),
          (_) => AuthOtpSent(email),
        );
    }
  }

  Future<void> verifyOtp(String rawCode) async {
    // Pull the email out of the current state — the user has already
    // submitted it.
    final email = switch (state) {
      AuthOtpSent(:final email) => email,
      AuthFailed(email: final e?) => e,
      AuthVerifyingOtp(:final email) => email,
      _ => null,
    };
    if (email == null) {
      state = const AuthFailed(
        ValidationFailure('Send the code first before verifying'),
      );
      return;
    }

    final codeResult = OtpCode.create(rawCode);
    switch (codeResult) {
      case Left(value: final failure):
        state = AuthFailed(failure, email: email);
      case Right(value: final code):
        state = AuthVerifyingOtp(email);
        final result = await ref
            .read(authRepositoryProvider)
            .verifyEmailOtp(email: email, code: code);
        state = result.fold(
          (f) => AuthFailed(f, email: email, showOtpForm: true),
          (_) => const AuthInitial(),
        );
    }
  }

  /// Resend the OTP without throwing the user back to the email screen.
  Future<void> resendOtp() async {
    final email = switch (state) {
      AuthOtpSent(:final email) => email,
      AuthFailed(email: final e?) => e,
      _ => null,
    };
    if (email == null) return;
    state = AuthResendingOtp(email);
    final result = await ref.read(authRepositoryProvider).sendEmailOtp(email);
    state = result.fold(
      (f) => AuthFailed(f, email: email, showOtpForm: true),
      (_) => AuthOtpSent(email),
    );
  }

  /// Drop back to the email screen.
  void cancelOtpFlow() {
    state = const AuthInitial();
  }

  // ─── Google OAuth ───────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = const AuthSigningInWithGoogle();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    state = result.fold((failure) {
      // Silently abort if the user simply closed the Google popup
      if (failure.message.toLowerCase().contains('cancelled')) {
        return const AuthInitial();
      }
      return AuthFailed(failure);
    }, (_) => const AuthInitial());
  }

  Future<void> signInWithFacebook() async {
    state = const AuthSigningInWithFacebook();
    final result = await ref.read(authRepositoryProvider).signInWithFacebook();
    state = result.fold((failure) {
      if (failure.message.toLowerCase().contains('cancelled')) {
        return const AuthInitial();
      }
      return AuthFailed(failure);
    }, (_) => const AuthInitial());
  }

  // ─── Sign out ───────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // Resolve the repository BEFORE the first await. Sign-out is triggered from
    // the app drawer, which pops itself immediately — that removes the only
    // listener on this autodispose provider, so `ref` is dead by the time the
    // unregister() gap below resumes. Reading it late threw
    // "Cannot use the Ref of authControllerProvider after it has been
    // disposed", which aborted sign-out entirely.
    final repository = ref.read(authRepositoryProvider);

    // Revoke this device's push token while still authenticated (the RLS
    // delete on device_tokens needs auth.uid()). Best-effort — never block
    // sign-out on it.
    try {
      await ref.read(pushRegistrarProvider.notifier).unregister();
    } catch (_) {
      /* ignore — stale tokens self-heal on next sign-in */
    }

    final result = await repository.signOut();
    // Same reason: this notifier may already be gone. The redirect is driven by
    // the auth stream, not by this state, so dropping the write is harmless —
    // a rebuilt controller starts at AuthInitial anyway.
    if (!ref.mounted) return;
    state = result.fold(AuthFailed.new, (_) => const AuthInitial());
  }
}
