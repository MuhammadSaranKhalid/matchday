import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_membership.dart';
import '../../domain/repositories/team_membership_repository.dart';
import '../datasources/team_membership_remote_datasource.dart';

class TeamMembershipRepositoryImpl implements TeamMembershipRepository {
  TeamMembershipRepositoryImpl({
    required TeamMembershipRemoteDataSource remote,
  }) : _remote = remote;

  final TeamMembershipRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<TeamMembership>>>
      getCurrentUserMemberships() async {
    try {
      final records = await _remote.getCurrentUserMemberships();
      final memberships = <TeamMembership>[];

      for (final record in records) {
        final member = record.member.toEntity();

        // The database guarantees every active member holds at least one role.
        // Treat missing role data as a read/integrity failure instead of
        // silently downgrading the user to PLAYER.
        if (member.roles.isEmpty) {
          return const Left(
            ServerFailure(
              'An active team membership has no role assignment',
            ),
          );
        }

        final team = record.team.toEntity();

        // "My Teams" is the user's active working set. Archived/disbanded
        // teams are records, not active memberships to operate from here.
        if (team.status != TeamStatus.active) {
          continue;
        }

        memberships.add(
          TeamMembership(
            team: team,
            member: member,
          ),
        );
      }

      memberships.sort(
        (a, b) => a.team.name.toLowerCase().compareTo(
              b.team.name.toLowerCase(),
            ),
      );

      return Right(List<TeamMembership>.unmodifiable(memberships));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
