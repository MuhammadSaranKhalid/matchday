import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_request.dart';
import '../providers/matches_providers.dart';
import '../providers/my_matches_providers.dart';

part 'match_detail_controller.g.dart';

@riverpod
class MatchDetailController extends _$MatchDetailController {
  @override
  void build() {}

  /// Withdraw an outbound challenge that has NOT become a match yet.
  ///
  /// Challenge cancellation and confirmed-match cancellation are deliberately
  /// separate domain operations.
  Future<Either<Failure, Unit>> withdraw({
    required String requestId,
    String? note,
  }) async {
    final result = await ref
        .read(matchesRepositoryProvider)
        .withdrawMatchChallenge(
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

  /// Cancel an already-confirmed match.
  ///
  /// The button is capability-gated in the UI, but that is UX only.
  /// cricket-match-action performs the authoritative RBAC + lifecycle check.
  Future<Either<Failure, Unit>> cancelMatch({
    required String matchId,
    String? reason,
  }) async {
    final result = await ref
        .read(matchesRepositoryProvider)
        .cancelMatch(id: MatchId(matchId), reason: reason);

    switch (result) {
      case Left():
        return result;
      case Right():
        // Remove the cancelled fixture from the confirmed schedule immediately.
        ref.invalidate(myMatchesViewProvider);
        ref.invalidate(myMatchesProvider);
        return const Right(unit);
    }
  }
}
