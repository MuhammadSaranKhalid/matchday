import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/value_objects/city.dart';
import '../../domain/value_objects/display_name.dart';
import '../../domain/value_objects/username.dart';
import '../datasources/onboarding_remote_datasource.dart';
import '../models/player_profile_dto.dart';

/// Online-only profile repository. The single place where the onboarding data
/// source's raw exceptions are translated into [Failure]s.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);
  final OnboardingRemoteDataSource _remote;

  @override
  Future<Either<Failure, Profile?>> getMyProfile() async {
    try {
      final dto = await _remote.fetchMyProfile();
      return Right(dto?.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isUsernameAvailable(String username) async {
    try {
      final available = await _remote.isUsernameAvailable(username);
      return Right(available);
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile>> completeOnboarding({
    required DisplayName displayName,
    required Username username,
    required City city,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
    PlayerProfile? playerProfile,
  }) async {
    try {
      final dto = await _remote.completeOnboarding(
        username: username.value,
        displayName: displayName.value,
        city: city.value,
        placeId: placeId,
        latitude: latitude,
        longitude: longitude,
        countryCode: countryCode,
        playerProfile: (playerProfile != null && playerProfile.hasAny)
            ? PlayerProfileDto.toWritePayload(playerProfile)
            : null,
      );
      return Right(dto.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
