import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

class CounterMatchChallenge
    implements UseCase<Unit, CounterMatchChallengeParams> {
  const CounterMatchChallenge(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(CounterMatchChallengeParams p) {
    final changesAny = p.counteredStartTime != null ||
        (p.counteredVenue != null && p.counteredVenue!.trim().isNotEmpty) ||
        p.counteredFormat != null ||
        p.counteredPlayersPerSide != null;
    if (!changesAny) {
      return Future.value(const Left(
        ValidationFailure('A counter must change at least one field'),
      ));
    }
    if (p.counteredPlayersPerSide != null &&
        (p.counteredPlayersPerSide! < 5 || p.counteredPlayersPerSide! > 15)) {
      return Future.value(const Left(
        ValidationFailure('Players per side must be between 5 and 15'),
      ));
    }
    return _repo.counterMatchChallenge(
      requestId: p.requestId,
      counteredStartTime: p.counteredStartTime,
      counteredVenue: p.counteredVenue,
      counteredFormat: p.counteredFormat,
      counteredPlayersPerSide: p.counteredPlayersPerSide,
      decisionNote: p.decisionNote?.trim(),
    );
  }
}

class CounterMatchChallengeParams {
  const CounterMatchChallengeParams({
    required this.requestId,
    this.counteredStartTime,
    this.counteredVenue,
    this.counteredFormat,
    this.counteredPlayersPerSide,
    this.decisionNote,
  });

  final MatchRequestId requestId;
  final DateTime? counteredStartTime;
  final String? counteredVenue;
  final MatchFormat? counteredFormat;
  final int? counteredPlayersPerSide;
  final String? decisionNote;
}
