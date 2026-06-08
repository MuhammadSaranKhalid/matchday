import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import 'follows_remote_datasource.dart';

part 'follows_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
FollowsRemoteDataSource followsRemoteDataSource(Ref ref) =>
    FollowsRemoteDataSource(ref.watch(supabaseClientProvider));
