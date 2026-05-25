import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/profile.dart';
import '../entities/player_profile.dart';
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

  /// Whether [username] is free to claim. Format is assumed already valid.
  Future<Either<Failure, bool>> isUsernameAvailable(String username);

  /// Persist the completed onboarding profile and return the updated entity.
  /// The optional geo ([placeId], [latitude], [longitude], [countryCode]) is
  /// stored alongside the [city] label and powers proximity features later.
  Future<Either<Failure, Profile>> completeOnboarding({
    required DisplayName displayName,
    required Username username,
    required City city,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
    PlayerProfile? playerProfile,
  });
}
