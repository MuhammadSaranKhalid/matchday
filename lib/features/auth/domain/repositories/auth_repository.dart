import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../value_objects/email.dart';
import '../value_objects/otp_code.dart';

/// Auth contract for the application.
///
/// Supabase-agnostic: every method speaks Domain types in and out.
/// Swapping the implementation to Firebase Auth or a custom backend
/// would not change any signature here.
abstract class AuthRepository {
  /// Request a 6-digit OTP code be emailed to [email].
  /// Returns Unit on success — the actual sign-in completes in [verifyEmailOtp].
  Future<Either<Failure, Unit>> sendEmailOtp(Email email);

  /// Verify the code received by email and complete sign-in.
  Future<Either<Failure, User>> verifyEmailOtp({
    required Email email,
    required OtpCode code,
  });

  /// Native Google sign-in. The implementation is responsible for the
  /// platform handshake (google_sign_in package on Android/iOS) and
  /// exchanging the ID token with Supabase.
  Future<Either<Failure, User>> signInWithGoogle();

  /// Facebook OAuth sign-in via Supabase browser/custom tab flow.
  Future<Either<Failure, Unit>> signInWithFacebook();

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, Unit>> deleteAccount();

  Future<Either<Failure, User?>> getCurrentUser();

  /// Emits the current user (or null on sign-out). The implementation
  /// wraps Supabase's onAuthStateChange stream.
  Stream<User?> watchCurrentUser();
}
