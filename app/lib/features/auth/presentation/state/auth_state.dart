import '../../../../core/error/failures.dart';
import '../../domain/value_objects/email.dart';

/// Sealed UI state for the sign-in flow screen.
///
/// Distinct from Supabase's [AuthState] (session lifecycle) — this models the
/// sign-in UI's own sub-states: which form is visible, which action is pending,
/// and whether an error has occurred.
///
/// The OTP flow requires more states than a single loading flag because the UI
/// must show different forms at different points (email entry vs. code entry).
/// A single AuthLoading would force the screen to guess which action is pending.
sealed class AuthFlowState {
  const AuthFlowState();
}

class AuthInitial extends AuthFlowState {
  const AuthInitial();
}

/// Email submitted, waiting for Supabase to dispatch the OTP.
class AuthSendingOtp extends AuthFlowState {
  const AuthSendingOtp();
}

/// OTP dispatched. UI now shows the code input.
class AuthOtpSent extends AuthFlowState {
  const AuthOtpSent(this.email);
  final Email email;
}

/// Code submitted, waiting for verification.
class AuthVerifyingOtp extends AuthFlowState {
  const AuthVerifyingOtp(this.email);
  final Email email;
}

/// A replacement code is being sent while the user remains on the OTP screen.
class AuthResendingOtp extends AuthFlowState {
  const AuthResendingOtp(this.email);
  final Email email;
}

/// Google OAuth in progress (picker, ID token exchange).
class AuthSigningInWithGoogle extends AuthFlowState {
  const AuthSigningInWithGoogle();
}

/// Facebook OAuth in progress.
class AuthSigningInWithFacebook extends AuthFlowState {
  const AuthSigningInWithFacebook();
}

/// Any failure. UI shows the message + a way to retry the same flow.
class AuthFailed extends AuthFlowState {
  const AuthFailed(this.failure, {this.email, this.showOtpForm = false});
  final Failure failure;

  /// Preserved so the UI can prefill the email input or re-render the OTP
  /// entry screen after a bad code.
  final Email? email;

  /// Sending a code can fail before an OTP screen is meaningful. Verification
  /// and resend failures, on the other hand, should leave the user in place.
  final bool showOtpForm;
}
