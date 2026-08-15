import 'dart:io';

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/profile.dart';
import '../value_objects/city.dart';
import '../value_objects/display_name.dart';
import '../value_objects/username.dart';

/// Profile/onboarding contract. Online-only (Phase 1): reads and writes talk to
/// the remote profile row directly — there is no local mirror. The only local
/// persistence is the wizard *draft*, handled outside this contract.
abstract class ProfileRepository {
  /// The signed-in user's profile, or null if no row exists yet. Used by the
  /// router's onboarding gate (`profile.isComplete`).
  Future<Either<Failure, Profile?>> getMyProfile();

  /// Any user's public profile by [username], or null when no active profile
  /// holds it. Online-only direct read (profiles are publicly readable).
  /// Backs the public `/u/:username` profile route + shared-link landing.
  Future<Either<Failure, Profile?>> getByUsername(String username);

  /// Whether [username] is free to claim. Format is assumed already valid.
  Future<Either<Failure, bool>> isUsernameAvailable(String username);

  /// Persist the completed onboarding profile and return the updated entity.
  Future<Either<Failure, Profile>> completeOnboarding({
    required DisplayName displayName,
    required Username username,
    String? avatarFilePath,
  });

  /// Update an existing profile (the edit screen). Only [displayName] and
  /// [city] are required; pass [username] only when it actually changed (the
  /// server enforces a 30-day change cooldown). If [avatar] is non-null it is
  /// uploaded to the `avatars` bucket and its URL stored on the row.
  Future<Either<Failure, Profile>> updateProfile({
    required DisplayName displayName,
    Username? username,
    String? bio,
    required City city,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
    File? avatar,
  });
}
