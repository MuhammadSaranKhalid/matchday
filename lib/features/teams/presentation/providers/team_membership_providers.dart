import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/team_membership_datasource_providers.dart';
import '../../data/repositories/team_membership_repository_impl.dart';
import '../../domain/repositories/team_membership_repository.dart';

part 'team_membership_providers.g.dart';

@Riverpod(keepAlive: true)
TeamMembershipRepository teamMembershipRepository(Ref ref) =>
    TeamMembershipRepositoryImpl(
      remote: ref.watch(teamMembershipRemoteDataSourceProvider),
    );
