import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/profile.dart';
import 'player_profile_dto.dart';

part 'profile_dto.freezed.dart';
part 'profile_dto.g.dart';

/// Wire-format `profiles` row. `location` is a jsonb blob holding the city
/// label plus structured geo:
/// `{ "city", "place_id", "lat", "lng", "country_code" }`.
/// The cricketing attributes live in a separate `player_profiles` table; the
/// data source fetches that row and injects it here under [playerProfile] so
/// [toEntity] can assemble the full domain [Profile].
@freezed
abstract class ProfileDto with _$ProfileDto {
  const factory ProfileDto({
    @JsonKey(name: 'user_id') required String userId,
    String? username,
    @JsonKey(name: 'display_name') String? displayName,
    String? bio,
    @JsonKey(name: 'profile_photo_url') String? profilePhotoUrl,
    Map<String, dynamic>? location,
    @JsonKey(name: 'onboarded_at') String? onboardedAt,
    @JsonKey(name: 'player_profile') PlayerProfileDto? playerProfile,
  }) = _ProfileDto;

  const ProfileDto._();

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  Profile toEntity() => Profile(
        userId: ProfileUserId(userId),
        username: username,
        displayName: displayName,
        bio: bio,
        avatarUrl: profilePhotoUrl,
        city: location?['city'] as String?,
        placeId: location?['place_id'] as String?,
        latitude: (location?['lat'] as num?)?.toDouble(),
        longitude: (location?['lng'] as num?)?.toDouble(),
        countryCode: location?['country_code'] as String?,
        onboardedAt:
            onboardedAt == null ? null : DateTime.tryParse(onboardedAt!),
        playerProfile: playerProfile?.toEntity(),
      );
}
