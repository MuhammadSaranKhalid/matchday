import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../value_objects/email.dart';
import '../value_objects/otp_code.dart';

/// Auth command contract for the application.
///
/// Pure commands: each operation returns Unit on success.
/// Session state is observed reactively via authStateProvider.
abstract class AuthRepository {
  /// Request a 6-digit OTP code be emailed to [email].
  Future<Either<Failure, Unit>> sendEmailOtp(Email email);

  /// Verify the code received by email and complete sign-in.
  Future<Either<Failure, Unit>> verifyEmailOtp({
    required Email email,
    required OtpCode code,
  });

  /// Native Google sign-in. The implementation is responsible for the
  /// platform handshake (google_sign_in package on Android/iOS) and
  /// exchanging the ID token with Supabase.
  Future<Either<Failure, Unit>> signInWithGoogle();

  /// Facebook OAuth sign-in via Supabase browser/custom tab flow.
  Future<Either<Failure, Unit>> signInWithFacebook();

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, Unit>> deleteAccount();
}