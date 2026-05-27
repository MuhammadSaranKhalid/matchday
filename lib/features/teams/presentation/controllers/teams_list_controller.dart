import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../matches/domain/entities/match.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../providers/teams_providers.dart';
import '../state/teams_list_view.dart';

part 'teams_list_controller.g.dart';

/// Composes the "My teams" view from three sources — the user's teams (local),
/// their active matches (online), and the cached teams used to resolve opponent
/// names. Keeps the screen a pure renderer (CLAUDE.md §5.3 / §6.6).
@riverpod
class TeamsListController extends _$TeamsListController {
  @override
  Future<TeamsListView> build() async {
    // Teams + the opponent cache are the local sources — await their streams.
    final teams = await ref.watch(myTeamsProvider.future);
    final cached = await ref.watch(allTeamsProvider.future);

    // Matches are online-only. Call the use case directly and pattern-match
    // the Either so a failure/offline fetch yields no active matches instead
    // of erroring the whole view (the use case never throws). Watching the
    // use-case provider keeps the seam to the matches feature (CLAUDE.md §6.6).
    final matchesResult =
        await ref.read(listMyMatchesUseCaseProvider).call(const NoParams());
    final matches = switch (matchesResult) {
      Right(value: final v) => v,
      Left() => const <Match>[],
    };

    final teamIds = teams.map((t) => t.id).toSet();
    final byId = {for (final t in [...teams, ...cached]) t.id: t};

    final entries = matches.where((m) => m.isActive).map((m) {
      final iAmTeamA = teamIds.contains(m.teamAId);
      final incoming = !iAmTeamA && teamIds.contains(m.teamBId);
      final opponentId = iAmTeamA ? m.teamBId : m.teamAId;
      return TeamMatchEntry(
        match: m,
        incoming: incoming,
        opponent: byId[opponentId],
      );
    }).toList();

    return TeamsListView(teams: teams, activeMatches: entries);
  }

  /// Pull-to-refresh: re-run the composition (re-fetches the online matches).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
