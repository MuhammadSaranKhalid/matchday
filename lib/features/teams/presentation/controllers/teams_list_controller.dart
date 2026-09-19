import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../providers/team_membership_providers.dart';
import '../state/teams_list_state.dart';

part 'teams_list_controller.g.dart';

@riverpod
class TeamsListController extends _$TeamsListController {
  @override
  Future<TeamsListState> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const TeamsListState.empty();
    }
    return _load();
  }

  Future<TeamsListState> _load() async {
    final result = await ref
        .read(teamMembershipRepositoryProvider)
        .getCurrentUserMemberships();

    return result.fold(
      (failure) => throw failure,
      TeamsListState.fromMemberships,
    );
  }

  Future<void> refresh() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = const AsyncData(TeamsListState.empty());
      return;
    }

    final result = await ref
        .read(teamMembershipRepositoryProvider)
        .getCurrentUserMemberships();

    result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
      },
      (memberships) {
        state = AsyncData(
          TeamsListState.fromMemberships(memberships),
        );
      },
    );
  }
}
