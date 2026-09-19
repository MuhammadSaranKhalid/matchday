import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/place_facet.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_search_result.dart';
import '../../domain/repositories/teams_repository.dart';
import '../../domain/value_objects/team_name.dart';
import '../datasources/teams_remote_datasource.dart';

class TeamsRepositoryImpl implements TeamsRepository {
  TeamsRepositoryImpl({
    required TeamsRemoteDataSource remote,
    Uuid? uuid,
  })  : _remote = remote,
        _uuid = uuid ?? const Uuid();

  final TeamsRemoteDataSource _remote;
  final Uuid _uuid;

  @override
  Future<Either<Failure, Team?>> getTeam(TeamId id) async {
    try {
      final dto = await _remote.getTeam(id.value);
      return Right(dto?.toEntity());
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, Team>>> getTeamsByIds(
    Iterable<TeamId> ids,
  ) async {
    try {
      final uniqueIds = ids.map((id) => id.value).toSet().toList();
      final dtos = await _remote.getTeamsByIds(uniqueIds);
      return Right({for (final dto in dtos) dto.teamId: dto.toEntity()});
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Team>> createTeam({
    required TeamName name,
    required TeamType type,
    TeamPrivacy privacy = TeamPrivacy.public,
    String? description,
    String? homeGround,
    String? city,
    int? foundedYear,
    String? primaryColor,
    String? secondaryColor,
    String? tagline,
    String? logoMonogram,
    CrestKind crestKind = CrestKind.monogram,
    String? label,
    String? district,
    String? province,
    String? postcode,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
  }) async {
    try {
      final dto = await _remote.createTeam({
        'id': _uuid.v4(),
        'team_name': name.value,
        'team_type': type.wire,
        'privacy': privacy.wire,
        'description': description,
        'home_ground': homeGround,
        'city': city,
        'founded_year': foundedYear,
        'primary_color': primaryColor,
        'secondary_color': secondaryColor,
        'tagline': tagline,
        'logo_monogram': logoMonogram,
        'crest_kind': crestKind.name,
        'label': label,
        'district': district,
        'province': province,
        'postcode': postcode,
        'place_id': placeId,
        'lat': latitude,
        'lng': longitude,
        'country_code': countryCode,
      });
      return Right(dto.toEntity());
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Team>> updateTeam({
    required TeamId teamId,
    TeamName? name,
    TeamType? type,
    TeamPrivacy? privacy,
    String? description,
    String? homeGround,
    String? city,
    int? foundedYear,
    String? primaryColor,
    String? secondaryColor,
    String? tagline,
    String? logoMonogram,
    String? district,
    String? province,
    String? postcode,
    String? countryCode,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['team_name'] = name.value;
      if (type != null) payload['team_type'] = type.wire;
      if (privacy != null) payload['privacy'] = privacy.wire;
      if (description != null) payload['description'] = description;
      if (homeGround != null) payload['home_ground'] = homeGround;
      if (city != null) payload['city'] = city;
      if (foundedYear != null) payload['founded_year'] = foundedYear;
      if (primaryColor != null) payload['primary_color'] = primaryColor;
      if (secondaryColor != null) payload['secondary_color'] = secondaryColor;
      if (tagline != null) payload['tagline'] = tagline;
      if (logoMonogram != null) payload['logo_monogram'] = logoMonogram;
      if (district != null) payload['district'] = district;
      if (province != null) payload['province'] = province;
      if (postcode != null) payload['postcode'] = postcode;
      if (countryCode != null) payload['country_code'] = countryCode;

      final dto = await _remote.updateTeam(teamId.value, payload);
      return Right(dto.toEntity());
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Team>> setTeamStatus({
    required TeamId teamId,
    required TeamStatus status,
  }) async {
    try {
      await _remote.setTeamStatus(teamId.value, status.wire);
      final dto = await _remote.getTeam(teamId.value);
      if (dto == null) return const Left(NotFoundFailure('Team not found'));
      return Right(dto.toEntity());
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadTeamLogo({
    required TeamId teamId,
    required List<int> bytes,
    required String extension,
  }) async {
    try {
      return Right(
        await _remote.uploadTeamLogo(
          teamId: teamId.value,
          bytes: bytes,
          extension: extension,
        ),
      );
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, List<TeamSearchResult>>> searchTeams({
    String? query,
    double? lat,
    double? lng,
    double? radiusKm,
    double? scaleKm,
    String? countryCode,
    int? limit,
    Future<void>? cancelSignal,
  }) async {
    try {
      final dtos = await _remote.searchTeams(
        query: query,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        scaleKm: scaleKm,
        countryCode: countryCode,
        limit: limit,
        cancelSignal: cancelSignal,
      );
      return Right(dtos.map((d) => d.toEntity()).toList(growable: false));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, List<PlaceFacet>>> teamPlaceFacets({
    String? countryCode,
    Future<void>? cancelSignal,
  }) async {
    try {
      final dtos = await _remote.teamPlaceFacets(
        countryCode: countryCode,
        cancelSignal: cancelSignal,
      );
      return Right(dtos.map((d) => d.toEntity()).toList(growable: false));
    } catch (e) {
      return Left(_failureFor(e));
    }
  }

  Failure _failureFor(Object e) => switch (e) {
        OperationCancelledException(:final message) => CancelledFailure(message),
        NetworkException(:final message) => NetworkFailure(message),
        UnauthorizedException(:final message) => AuthFailure(message),
        NotFoundException(:final message) => NotFoundFailure(message),
        ServerException(:final message) => ServerFailure(message),
        _ => UnknownFailure(e.toString()),
      };
}
