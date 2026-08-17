import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../../../matches/presentation/providers/my_matches_providers.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../widgets/pavilion_v2/pv_v2_data.dart';
import '../widgets/pavilion_v2/pv_v2_map.dart';

part 'pavilion_match_detail_provider.g.dart';

@riverpod
Future<PvMatch?> pavilionMatchDetail(
  Ref ref,
  String matchId,
) async {
  // Listen for realtime match updates. If the underlying match row changes
  // (e.g. status goes from scheduled to toss), invalidate the workspace provider
  // so the Pavilion fetches the fresh state.
  ref.listen(liveMatchProvider(matchId), (prev, next) {
    if (next.hasValue && next.value != null && prev?.value != next.value) {
      ref.invalidate(myMatchesViewProvider);
    }
  });

  final view = await ref.watch(myMatchesViewProvider.future);
  final userId = ref.watch(currentUserStreamProvider).value?.id.value;
  final teams = await ref.watch(myTeamsProvider.future);

  final pvTeams = pvTeamsFromTeams(teams, userId: userId);
  final meFallback = pvTeams.isNotEmpty ? pvTeams.first.crest : kPvUnknownCrest;

  for (final m in pvMatchesFromView(view, meFallback: meFallback)) {
    if (m.id == matchId) {
      return m;
    }
  }
  return null;
}
