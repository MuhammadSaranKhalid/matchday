import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../teams/domain/entities/team.dart';
import '../entities/match.dart';
import '../repositories/matches_repository.dart';

/// Validate a proposed friendly and send it. Business rules: the XI must be
/// exactly `playersPerTeam`, the captain must be in it, the keeper (if set) must
/// be in it, and a venue + time are required.
class CreateMatchRequest implements UseCase<Match, CreateMatchRequestParams> {
  const CreateMatchRequest(this._repo);
  final MatchesRepository _repo;

  @override
  Future<Either<Failure, Match>> call(CreateMatchRequestParams p) async {
    if (p.squad.length != p.format.playersPerTeam) {
      return Left(ValidationFailure(
          'Pick exactly ${p.format.playersPerTeam} players'));
    }
    if (!p.squad.contains(p.captain)) {
      return const Left(ValidationFailure('Captain must be in the XI'));
    }
    if (p.keeper != null && !p.squad.contains(p.keeper)) {
      return const Left(ValidationFailure('Keeper must be in the XI'));
    }
    if (p.venue == null) {
      return const Left(ValidationFailure('A venue is required'));
    }
    if (p.scheduledStartTime == null) {
      return const Left(ValidationFailure('A date and time are required'));
    }

    return _repo.createMatchRequest(
      teamAId: p.teamAId,
      teamBId: p.teamBId,
      format: p.format,
      squad: p.squad,
      captain: p.captain,
      keeper: p.keeper,
      venue: p.venue,
      scheduledStartTime: p.scheduledStartTime,
    );
  }
}

class CreateMatchRequestParams {
  const CreateMatchRequestParams({
    required this.teamAId,
    required this.teamBId,
    required this.format,
    required this.squad,
    required this.captain,
    this.keeper,
    this.venue,
    this.scheduledStartTime,
  });

  final TeamId teamAId;
  final TeamId teamBId;
  final MatchFormat format;
  final List<String> squad;
  final String captain;
  final String? keeper;
  final Venue? venue;
  final DateTime? scheduledStartTime;
}
