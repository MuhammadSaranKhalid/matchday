import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/send_email_otp.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/verify_email_otp.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) =>
    AuthRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));

// Use cases — one line each.

@riverpod
SendEmailOtp sendEmailOtpUseCase(Ref ref) =>
    SendEmailOtp(ref.watch(authRepositoryProvider));

@riverpod
VerifyEmailOtp verifyEmailOtpUseCase(Ref ref) =>
    VerifyEmailOtp(ref.watch(authRepositoryProvider));

@riverpod
SignInWithGoogle signInWithGoogleUseCase(Ref ref) =>
    SignInWithGoogle(ref.watch(authRepositoryProvider));

@riverpod
SignOut signOutUseCase(Ref ref) =>
    SignOut(ref.watch(authRepositoryProvider));

@riverpod
GetCurrentUser getCurrentUserUseCase(Ref ref) =>
    GetCurrentUser(ref.watch(authRepositoryProvider));

@riverpod
WatchCurrentUser watchCurrentUserUseCase(Ref ref) =>
    WatchCurrentUser(ref.watch(authRepositoryProvider));

/// Stream of the current user — drives router redirects + global UI.
///
/// keepAlive: this is the app-lifetime auth session stream (a Supabase
/// realtime channel). Letting it autodispose would tear down and re-subscribe
/// the channel whenever listeners momentarily drop to zero, risking a missed
/// auth event in the gap.
@Riverpod(keepAlive: true)
Stream<User?> currentUserStream(Ref ref) =>
    ref.watch(watchCurrentUserUseCaseProvider).call(const NoParams());
