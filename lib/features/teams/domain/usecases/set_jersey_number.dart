import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/team_member.dart';
import '../repositories/teams_repository.dart';
import '../value_objects/jersey_number.dart';

/// Set or clear a member's jersey number. A null [number] clears it; otherwise
/// it's validated via [JerseyNumber] before reaching the repository.
class SetJerseyNumber implements UseCase<Unit, SetJerseyNumberParams> {
  const SetJerseyNumber(this._repo);
  final TeamsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(SetJerseyNumberParams p) async {
    if (p.number == null) {
      return _repo.setJerseyNumber(p.id, null);
    }
    return JerseyNumber.create(p.number!).fold(
      (f) async => Left(f),
      (jersey) => _repo.setJerseyNumber(p.id, jersey),
    );
  }
}

class SetJerseyNumberParams {
  const SetJerseyNumberParams({required this.id, required this.number});
  final MembershipId id;
  final int? number;
}
