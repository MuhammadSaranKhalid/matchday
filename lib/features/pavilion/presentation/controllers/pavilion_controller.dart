import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../matches/domain/entities/match_request.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../../../matches/presentation/providers/my_matches_providers.dart';

part 'pavilion_controller.g.dart';

/// Action coordinator for the Pavilion v2 workspace.
///
/// Pavilion is a presentation-only aggregation feature (CLAUDE.md §6.6) — it
/// owns no domain/data layer. This controller hosts the few cross-feature
/// write actions the workspace dispatches (currently: withdrawing an outbound
/// match challenge) so the screen stays a pure renderer. View state
/// (segment, open match, toast) remains in the screen — it's local to one
/// route and not worth promoting.
///
/// Actions return `Either<Failure, T>` so the screen can show per-action
/// snackbars without polluting controller state.
@riverpod
class PavilionController extends _$PavilionController {
  @override
  void build() {}

  /// Withdraw an outbound match challenge. On success, invalidate the two
  /// providers the workspace renders from so the row disappears immediately.
  Future<Either<Failure, Unit>> withdraw({
    required String requestId,
    String? note,
  }) async {
    final result =
        await ref.read(matchesRepositoryProvider).withdrawMatchChallenge(
              requestId: MatchRequestId(requestId),
              decisionNote: note,
            );
    switch (result) {
      case Left():
        return result;
      case Right():
        ref.invalidate(myMatchChallengesProvider);
        ref.invalidate(myMatchesViewProvider);
        return const Right(unit);
    }
  }
}
