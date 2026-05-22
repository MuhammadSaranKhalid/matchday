import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/team_member.dart';
import '../repositories/teams_repository.dart';

/// Remove a member from a team's roster.
class RemoveMember implements UseCase<Unit, MembershipId> {
  const RemoveMember(this._repo);
  final TeamsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(MembershipId id) =>
      _repo.removeMember(id);
}
