import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/value_objects/email.dart';

/// Sealed UI state for the auth flow.
///
/// The OTP flow has more states than a single signIn() call because the
/// UI needs to show different forms at different points (email entry vs
/// code entry). A single AuthLoading would force the screen to guess
/// which action is pending.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Email submitted, waiting for Supabase to dispatch the OTP.
class AuthSendingOtp extends AuthState {
  const AuthSendingOtp();
}

/// OTP dispatched. UI now shows the code input.
class AuthOtpSent extends AuthState {
  const AuthOtpSent(this.email);
  final Email email;
}

/// Code submitted, waiting for verification.
class AuthVerifyingOtp extends AuthState {
  const AuthVerifyingOtp(this.email);
  final Email email;
}

/// A replacement code is being sent while the user remains on the OTP screen.
class AuthResendingOtp extends AuthState {
  const AuthResendingOtp(this.email);
  final Email email;
}

/// Google OAuth in progress (picker, ID token exchange).
class AuthSigningInWithGoogle extends AuthState {
  const AuthSigningInWithGoogle();
}

/// Facebook OAuth in progress.
class AuthSigningInWithFacebook extends AuthState {
  const AuthSigningInWithFacebook();
}

/// Sign-in succeeded. Router redirects on this transition.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}

/// Any failure. UI shows the message + a way to retry the same flow.
class AuthFailed extends AuthState {
  const AuthFailed(this.failure, {this.email, this.showOtpForm = false});
  final Failure failure;

  /// Preserved so the UI can prefill the email input or re-render the OTP
  /// entry screen after a bad code.
  final Email? email;

  /// Sending a code can fail before an OTP screen is meaningful. Verification
  /// and resend failures, on the other hand, should leave the user in place.
  final bool showOtpForm;
}
