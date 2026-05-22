import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import 'matches_remote_datasource.dart';

part 'matches_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
MatchesRemoteDataSource matchesRemoteDataSource(Ref ref) =>
    MatchesRemoteDataSource(ref.watch(supabaseClientProvider));
