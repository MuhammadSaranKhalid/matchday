import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';

/// Speaks Supabase. Returns DTOs. Throws low-level exceptions.
///
/// Note: GoogleSignIn.instance is initialized once at app boot in main.dart.
/// This data source just calls authenticate() / authorizeScopes() on it.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  // ─── Email OTP ──────────────────────────────────────────────────────────

  Future<void> sendEmailOtp(String email) async {
    try {
      // shouldCreateUser:true auto-registers first-time emails.
      // Email template configured in Supabase Dashboard → Auth → Templates.
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: true);
    } on AuthException catch (e) {
      // Includes 'Email rate limit exceeded' etc.
      throw UnauthorizedException(e.message);
    } catch (e) {
      throw ServerException('Failed to send code: $e');
    }
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
    } on AuthException catch (e) {
      // 'Token has expired or is invalid' lands here.
      throw UnauthorizedException(e.message);
    } catch (e) {
      throw ServerException('Verification failed: $e');
    }
  }

  // ─── Google OAuth (native) ──────────────────────────────────────────────

  /// Performs native Google sign-in via google_sign_in v7+ and exchanges
  /// the ID token with Supabase. GoogleSignIn.instance must have been
  /// initialized at app startup (see main.dart).
  Future<void> signInWithGoogle() async {
    try {
      final google = GoogleSignIn.instance;

      // authenticate() opens the picker on Android / system sheet on iOS.
      // On web it throws — apps targeting web should use the rendered
      // button via google_sign_in_web instead.
      final account = await google.authenticate();

      // Request the scopes we need. authorizationForScopes returns the
      // existing grant if any; if null, we prompt with authorizeScopes.
      const scopes = ['email', 'profile'];
      final authorization =
          await account.authorizationClient.authorizationForScopes(scopes) ??
          await account.authorizationClient.authorizeScopes(scopes);

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw ServerException('Google did not return an ID token');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
    } on AuthException catch (e) {
      debugPrint('[GoogleSignIn] Supabase AuthException: ${e.message}');
      throw UnauthorizedException(e.message);
    } on GoogleSignInException catch (e) {
      debugPrint(
        '[GoogleSignIn] GoogleSignInException code=${e.code}, description=${e.description}',
      );
      // Distinguish a deliberate user cancellation (maps to AuthFailure, a
      // benign "you cancelled" message) from genuine config/network failures
      // (ServerFailure, "something's wrong"). Lumping them together shows
      // "Server error" when the user simply dismissed the sheet.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw UnauthorizedException('Google sign-in was cancelled');
      }
      throw ServerException(
        'Google sign-in is unavailable right now (${e.code.name}: ${e.description ?? "unknown error"}). Try email instead or try again later.',
      );
    } catch (e, st) {
      debugPrint('[GoogleSignIn] Unexpected error: $e\n$st');
      throw ServerException('Google sign-in failed: $e');
    }
  }

  // ─── Facebook OAuth ─────────────────────────────────────────────────────

  /// Launches Facebook OAuth via Supabase browser/custom tab flow.
  Future<void> signInWithFacebook() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'com.joinmatchday.app://login-callback',
      );
    } on AuthException catch (e) {
      debugPrint('[FacebookSignIn] Supabase AuthException: ${e.message}');
      throw UnauthorizedException(e.message);
    } catch (e, st) {
      debugPrint('[FacebookSignIn] Unexpected error: $e\n$st');
      throw ServerException('Facebook sign-in failed: $e');
    }
  }

  // ─── Session lifecycle ──────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      // A normal sign-out should affect this phone only. A separate explicit
      // "sign out everywhere" control can use the global scope later.
      await _supabase.auth.signOut(scope: SignOutScope.local);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> deleteAccount() async {
    try {
      final response = await _supabase.functions.invoke(
        'delete-account',
        body: {'confirmation': 'DELETE'},
      );
      if (response.status != 200) {
        throw ServerException(
          'Account deletion failed. Please retry or contact support.',
        );
      }
      // Local sign-out clears the persisted session after the server deletes it.
      await _supabase.auth.signOut(scope: SignOutScope.local);
    } on FunctionsFetchException catch (e) {
      throw NetworkException(
        e.reasonPhrase ?? 'Network failure during account deletion',
      );
    } on FunctionException catch (e) {
      throw ServerException(
        e.reasonPhrase ?? 'Account deletion failed (${e.status}).',
      );
    }
  }

  User? currentUser() => _supabase.auth.currentUser;

  /// Returns the in-memory session synchronously, or null if none exists.
  Session? currentSession() => _supabase.auth.currentSession;

  /// Asynchronously retrieves the current session, automatically refreshing
  /// an expired access token if necessary.
  Future<Session?> getSession() async {
    try {
      return await _supabase.auth.getSession();
    } on AuthException catch (e) {
      throw UnauthorizedException(e.message);
    } catch (e) {
      throw ServerException('Failed to get session: $e');
    }
  }

  /// Emits native Supabase [AuthState] events containing the event type,
  /// session, token state, and sign-out context.
  Stream<AuthState> watchAuthState() => _supabase.auth.onAuthStateChange;
}


