import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/team_membership.dart';

/// Domain boundary for team-membership reads.
///
/// Membership is its own domain relationship: a user belongs to a team through
/// `team_members`, and holds one or more roles through `team_member_roles`.
///
/// This contract intentionally exposes a one-shot read. Administrative
/// membership/role state does not require a permanent realtime subscription.
abstract class TeamMembershipRepository {
  Future<Either<Failure, List<TeamMembership>>> getCurrentUserMemberships();
}
