import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import 'team_membership_remote_datasource.dart';

part 'team_membership_datasource_providers.g.dart';

@Riverpod(keepAlive: true)
TeamMembershipRemoteDataSource teamMembershipRemoteDataSource(Ref ref) =>
    TeamMembershipRemoteDataSource(ref.watch(supabaseClientProvider));
