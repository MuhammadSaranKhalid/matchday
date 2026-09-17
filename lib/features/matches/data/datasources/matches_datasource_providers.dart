import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/realtime/ably_provider.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import 'format_presets_remote_datasource.dart';
import 'match_requests_remote_datasource.dart';
import 'matches_remote_datasource.dart';

part 'matches_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
MatchesRemoteDataSource matchesRemoteDataSource(Ref ref) =>
    MatchesRemoteDataSource(
      ref.watch(supabaseClientProvider),
      ref.watch(ablyServiceProvider),
    );

@Riverpod(keepAlive: true)
MatchRequestsRemoteDataSource matchRequestsRemoteDataSource(Ref ref) =>
    MatchRequestsRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
FormatPresetsRemoteDataSource formatPresetsRemoteDataSource(Ref ref) =>
    FormatPresetsRemoteDataSource(ref.watch(supabaseClientProvider));
