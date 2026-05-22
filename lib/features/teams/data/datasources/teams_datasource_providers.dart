import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import 'teams_local_datasource.dart';
import 'teams_remote_datasource.dart';

part 'teams_datasource_providers.g.dart';

/// Own file so the sync provider and the repository provider can both depend
/// on these without an import cycle (mirrors the todos pattern).

@Riverpod(keepAlive: true)
TeamsLocalDataSource teamsLocalDataSource(Ref ref) =>
    TeamsLocalDataSource(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
TeamsRemoteDataSource teamsRemoteDataSource(Ref ref) =>
    TeamsRemoteDataSource(ref.watch(supabaseClientProvider));
