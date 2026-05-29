import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) =>
    AuthRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));

/// Stream of the current user — drives router redirects + global UI.
///
/// keepAlive: this is the app-lifetime auth session stream (a Supabase
/// realtime channel). Letting it autodispose would tear down and re-subscribe
/// the channel whenever listeners momentarily drop to zero, risking a missed
/// auth event in the gap.
@Riverpod(keepAlive: true)
Stream<User?> currentUserStream(Ref ref) =>
    ref.watch(authRepositoryProvider).watchCurrentUser();
