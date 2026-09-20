import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/place_facet.dart';
import '../entities/team.dart';
import '../entities/team_search_result.dart';
import '../value_objects/team_name.dart';

/// Team profile/discovery boundary.
///
/// Membership, roster, invitations and role commands intentionally live in
/// [TeamMembershipRepository]. No realtime team streams are exposed here.
abstract class TeamsRepository {
  Future<Either<Failure, Team?>> getTeam(TeamId id);

  Future<Either<Failure, Map<String, Team>>> getTeamsByIds(
    Iterable<TeamId> ids,
  );

  Future<Either<Failure, Team>> createTeam({
    required TeamName name,
    required TeamType type,
    TeamPrivacy privacy = TeamPrivacy.public,
    String? description,
    String? homeGround,
    int? foundedYear,
    String? primaryColor,
    String? secondaryColor,
    String? tagline,
    String? logoMonogram,
    CrestKind crestKind = CrestKind.monogram,
  });

  Future<Either<Failure, Team>> updateTeam({
    required TeamId teamId,
    TeamName? name,
    TeamType? type,
    TeamPrivacy? privacy,
    String? description,
    String? homeGround,
    int? foundedYear,
    String? primaryColor,
    String? secondaryColor,
    String? tagline,
    String? logoMonogram,
  });

  Future<Either<Failure, Team>> setTeamStatus({
    required TeamId teamId,
    required TeamStatus status,
  });

  Future<Either<Failure, String>> uploadTeamLogo({
    required TeamId teamId,
    required List<int> bytes,
    required String extension,
  });

  Future<Either<Failure, List<TeamSearchResult>>> searchTeams({
    String? query,
    double? lat,
    double? lng,
    double? radiusKm,
    double? scaleKm,
    String? countryCode,
    int? limit,
    Future<void>? cancelSignal,
  });

  Future<Either<Failure, List<PlaceFacet>>> teamPlaceFacets({
    String? countryCode,
    Future<void>? cancelSignal,
  });
}
