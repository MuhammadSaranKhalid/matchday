import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/value_objects/city.dart';
import '../../domain/value_objects/display_name.dart';
import '../../domain/value_objects/username.dart';
import '../datasources/profile_remote_datasource.dart';

/// Online-only profile repository. The single place where the onboarding data
/// source's raw exceptions are translated into [Failure]s.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;

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
  Future<Either<Failure, Profile?>> getByUsername(String username) async {
    try {
      final dto = await _remote.fetchProfileByUsername(username);
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
    String? avatarFilePath,
    String? existingAvatarUrl,
  }) async {
    try {
      // A photo picked in the app replaces the Google-provided URL. Otherwise
      // retain the Google avatar selected during the identity step.
      String? photoUrl = _validRemoteAvatarUrl(existingAvatarUrl);
      if (avatarFilePath != null) {
        final tempDir = await getTemporaryDirectory();
        final targetPath =
            '${tempDir.path}/avatar_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          avatarFilePath,
          targetPath,
          quality: 80,
          minWidth: 500,
          minHeight: 500,
          format: CompressFormat.jpeg,
        );

        photoUrl = await _remote.uploadAvatar(
          File(compressedFile?.path ?? avatarFilePath),
        );
      }
      final dto = await _remote.completeOnboarding(
        username: username.value,
        displayName: displayName.value,
        photoUrl: photoUrl,
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

  static String? _validRemoteAvatarUrl(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null && uri.hasAuthority && uri.scheme == 'https'
        ? uri.toString()
        : null;
  }

  @override
  Future<Either<Failure, Profile>> updateProfile({
    required DisplayName displayName,
    Username? username,
    String? bio,
    City? city,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
    File? avatar,
    File? cover,
  }) async {
    try {
      // Upload images first (if any) so their URLs go into the row UPDATE.
      String? photoUrl;
      if (avatar != null) {
        photoUrl = await _remote.uploadAvatar(avatar);
      }
      String? coverUrl;
      if (cover != null) {
        coverUrl = await _remote.uploadCover(cover);
      }
      final dto = await _remote.updateProfile({
        'display_name': displayName.value,
        if (username != null) 'username': username.value,
        // null clears the bio column.
        'bio': bio,
        if (photoUrl != null) 'profile_photo_url': photoUrl,
        if (coverUrl != null) 'cover_photo_url': coverUrl,
        // Omitted entirely when the caller has no city to offer, so the
        // existing location survives the update untouched.
        if (city != null)
          'location': {
            'city': city.value,
            if (placeId != null) 'place_id': placeId,
            if (latitude != null) 'lat': latitude,
            if (longitude != null) 'lng': longitude,
            if (countryCode != null) 'country_code': countryCode,
          },
      });
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
