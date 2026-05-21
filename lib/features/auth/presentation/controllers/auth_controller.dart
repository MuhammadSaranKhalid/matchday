import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/send_email_otp.dart';
import '../../domain/usecases/verify_email_otp.dart';
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
  AuthState build() => const AuthInitial();

  // ─── Email OTP ──────────────────────────────────────────────────────────

  Future<void> sendOtp(String rawEmail) async {
    final emailResult = Email.create(rawEmail);
    switch (emailResult) {
      case Left(value: final failure):
        state = AuthFailed(failure);
      case Right(value: final email):
        state = const AuthSendingOtp();
        final result = await ref.read(sendEmailOtpUseCaseProvider).call(email);
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
            .read(verifyEmailOtpUseCaseProvider)
            .call(VerifyEmailOtpParams(email: email, code: code));
        state = result.fold(
          (f) => AuthFailed(f, email: email),
          AuthAuthenticated.new,
        );
    }
  }

  /// Resend the OTP from the OtpSent / Failed states.
  Future<void> resendOtp() async {
    final email = switch (state) {
      AuthOtpSent(:final email) => email,
      AuthFailed(email: final e?) => e,
      _ => null,
    };
    if (email == null) return;
    await sendOtp(email.value);
  }

  /// Drop back to the email screen.
  void cancelOtpFlow() {
    state = const AuthInitial();
  }

  // ─── Google OAuth ───────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = const AuthSigningInWithGoogle();
    final result = await ref
        .read(signInWithGoogleUseCaseProvider)
        .call(const NoParams());
    state = result.fold(AuthFailed.new, AuthAuthenticated.new);
  }

  // ─── Sign out ───────────────────────────────────────────────────────────

  Future<void> signOut() async {
    final result =
        await ref.read(signOutUseCaseProvider).call(const NoParams());
    state = result.fold(
      AuthFailed.new,
      (_) => const AuthInitial(),
    );
  }
}
