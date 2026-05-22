import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/team_member.dart';
import '../repositories/teams_repository.dart';

/// Change a member's role (captain / vice-captain / keeper / player).
/// The one-captain-per-team rule is enforced in the repository.
class SetMemberRole implements UseCase<Unit, SetMemberRoleParams> {
  const SetMemberRole(this._repo);
  final TeamsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(SetMemberRoleParams p) =>
      _repo.setMemberRole(p.id, p.role);
}

class SetMemberRoleParams {
  const SetMemberRoleParams({required this.id, required this.role});
  final MembershipId id;
  final MemberRole role;
}
