import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';
import '../value_objects/city.dart';
import '../value_objects/display_name.dart';
import '../value_objects/username.dart';

/// Edit an existing profile. Takes raw strings and validates them into value
/// objects here (so callers don't depend on the VOs); enforces the bio-length
/// rule; only forwards [username] when the caller marked it changed.
class UpdateProfile implements UseCase<Profile, UpdateProfileParams> {
  const UpdateProfile(this._repo);
  final ProfileRepository _repo;

  static const maxBio = 200;

  @override
  Future<Either<Failure, Profile>> call(UpdateProfileParams p) async {
    final nameRes = DisplayName.create(p.displayName);
    if (nameRes.isLeft()) return Left(nameRes.getLeft().toNullable()!);

    final cityRes = City.create(p.city);
    if (cityRes.isLeft()) return Left(cityRes.getLeft().toNullable()!);

    Username? username;
    if (p.usernameChanged) {
      final uRes = Username.create(p.username ?? '');
      if (uRes.isLeft()) return Left(uRes.getLeft().toNullable()!);
      username = uRes.getRight().toNullable();
    }

    final bio = p.bio?.trim();
    if (bio != null && bio.length > maxBio) {
      return const Left(
        ValidationFailure('Bio is too long (max $maxBio characters).'),
      );
    }

    return _repo.updateProfile(
      displayName: nameRes.getRight().toNullable()!,
      username: username,
      bio: (bio == null || bio.isEmpty) ? null : bio,
      city: cityRes.getRight().toNullable()!,
      placeId: p.placeId,
      latitude: p.latitude,
      longitude: p.longitude,
      countryCode: p.countryCode,
      avatar: p.avatar,
    );
  }
}

class UpdateProfileParams {
  const UpdateProfileParams({
    required this.displayName,
    this.username,
    this.usernameChanged = false,
    this.bio,
    required this.city,
    this.placeId,
    this.latitude,
    this.longitude,
    this.countryCode,
    this.avatar,
  });

  final String displayName;
  final String? username;

  /// True only when the user actually changed the username (server enforces a
  /// 30-day cooldown, so we don't re-send an unchanged value).
  final bool usernameChanged;
  final String? bio;
  final String city;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final String? countryCode;
  final File? avatar;
}
