import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/player_profile.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';
import '../value_objects/city.dart';
import '../value_objects/display_name.dart';
import '../value_objects/username.dart';

/// Validate the onboarding inputs (display name, username, city) and persist
/// the profile. Business rules live here: value-object construction plus the
/// requirement that a city is provided. The player profile is optional and is
/// only forwarded when the user actually picked something.
class CompleteOnboarding implements UseCase<Profile, CompleteOnboardingParams> {
  const CompleteOnboarding(this._repo);
  final ProfileRepository _repo;

  @override
  Future<Either<Failure, Profile>> call(CompleteOnboardingParams p) {
    // Validate each input via its value object; the first failure short-circuits.
    return DisplayName.create(p.displayName).fold(
      (f) async => Left(f),
      (displayName) => Username.create(p.username).fold(
        (f) async => Left(f),
        (username) => City.create(p.city).fold(
          (f) async => Left(f),
          (city) {
            final player =
                (p.playerProfile?.hasAny ?? false) ? p.playerProfile : null;
            return _repo.completeOnboarding(
              displayName: displayName,
              username: username,
              city: city,
              placeId: p.placeId,
              latitude: p.latitude,
              longitude: p.longitude,
              countryCode: p.countryCode,
              playerProfile: player,
            );
          },
        ),
      ),
    );
  }
}

class CompleteOnboardingParams {
  const CompleteOnboardingParams({
    required this.displayName,
    required this.username,
    required this.city,
    this.placeId,
    this.latitude,
    this.longitude,
    this.countryCode,
    this.playerProfile,
  });

  final String displayName;
  final String username;
  final String city;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final String? countryCode;
  final PlayerProfile? playerProfile;
}
