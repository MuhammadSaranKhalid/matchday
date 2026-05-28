import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match_request.dart';
import '../repositories/matches_repository.dart';

/// One-shot list of all challenges the user can see — both inbound (their
/// team is the recipient) and outbound (their team is the sender). The
/// presentation layer partitions by `from_team_id ∈ myTeams` vs `to_team_id
/// ∈ myTeams`.
///
/// Not a stream: realtime updates ride the user:notifications broadcast
/// channel. When a `match_request` or `match_request_decision` notification
/// arrives, the consumer invalidates its list provider.
class ListMyMatchChallenges implements UseCase<List<MatchRequest>, NoParams> {
  const ListMyMatchChallenges(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, List<MatchRequest>>> call(NoParams params) =>
      _repo.listMyMatchChallenges();
}
