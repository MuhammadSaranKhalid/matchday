import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/blocked_account.dart';
import '../../domain/repositories/safety_repository.dart';
import '../../data/datasources/safety_remote_datasource.dart';
import '../../data/repositories/safety_repository_impl.dart';
part 'safety_providers.g.dart';
@riverpod
SafetyRepository safetyRepository(Ref ref) => SafetyRepositoryImpl(SafetyRemoteDataSource(ref.watch(supabaseClientProvider)));
@riverpod
Future<List<BlockedAccount>> blockedAccounts(Ref ref) async {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return [];
  final result = await ref.watch(safetyRepositoryProvider).blockedAccounts();
  return result.fold((f) => throw FailureWrapper(f), (accounts) => accounts);
}
