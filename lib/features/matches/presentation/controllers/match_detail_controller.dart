import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/match_request.dart';
import '../providers/matches_providers.dart';
import '../providers/my_matches_providers.dart';

part 'match_detail_controller.g.dart';

@riverpod
class MatchDetailController extends _$MatchDetailController {
  @override
  void build() {}

  /// Withdraw an outbound match challenge. On success, invalidate the two
  /// providers the matches workspace renders from so the row disappears immediately.
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
