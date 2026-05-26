import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import 'teams_remote_datasource.dart';

part 'teams_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
TeamsRemoteDataSource teamsRemoteDataSource(Ref ref) =>
    TeamsRemoteDataSource(ref.watch(supabaseClientProvider));
