import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import 'explore_remote_datasource.dart';

part 'explore_datasource_providers.g.dart';

/// DI-only file (CLAUDE.md Rule 5): the data source itself takes a plain
/// constructor parameter and knows nothing about Riverpod.
@Riverpod(keepAlive: true)
ExploreRemoteDataSource exploreRemoteDataSource(Ref ref) =>
    ExploreRemoteDataSource(ref.watch(supabaseClientProvider));
