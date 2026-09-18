import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../widgets/match_detail/pv_v2_data.dart';
import '../widgets/match_detail/pv_v2_map.dart';
import 'matches_providers.dart';
import 'my_matches_providers.dart';

part 'match_detail_provider.g.dart';

@riverpod
Future<PvMatch?> matchDetail(
  Ref ref,
  String matchId,
) async {
  // Listen for realtime match updates. If the underlying match row changes
  // (e.g. status goes from scheduled to toss), invalidate the workspace provider
  // so the screen fetches the fresh state.
  ref.listen(liveMatchProvider(matchId), (prev, next) {
    if (next.hasValue && next.value != null && prev?.value != next.value) {
      ref.invalidate(myMatchesViewProvider);
    }
  });

  final view = await ref.watch(myMatchesViewProvider.future);
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
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
