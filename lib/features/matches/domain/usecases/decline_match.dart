import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Opponent declines a pending match, with an optional reason.
class DeclineMatch implements UseCase<Match, DeclineMatchParams> {
  const DeclineMatch(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Match>> call(DeclineMatchParams p) {
    final reason = p.reason?.trim();
    return _repo.declineMatch(
      id: p.id,
      reason: (reason == null || reason.isEmpty) ? null : reason,
    );
  }
}

class DeclineMatchParams {
  const DeclineMatchParams({required this.id, this.reason});
  final MatchId id;
  final String? reason;
}
