import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/profile.dart';

part 'profile_dto.freezed.dart';
part 'profile_dto.g.dart';

/// Wire-format `profiles` row. `location` is a jsonb blob holding the city
/// label plus structured geo:
/// `{ "city", "place_id", "lat", "lng", "country_code" }`.
///
/// Cricket-specific attributes live in a separate `cricket_player_profiles`
/// table and are loaded independently via [CricketPlayerProfileRemoteDataSource].
@freezed
abstract class ProfileDto with _$ProfileDto {
  const factory ProfileDto({
    @JsonKey(name: 'user_id') required String userId,
    String? username,
    @JsonKey(name: 'display_name') String? displayName,
    String? bio,
    @JsonKey(name: 'profile_photo_url') String? profilePhotoUrl,
    @JsonKey(name: 'cover_photo_url') String? coverPhotoUrl,
    Map<String, dynamic>? location,
    @JsonKey(name: 'onboarded_at') String? onboardedAt,
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
        coverUrl: coverPhotoUrl,
        city: location?['city'] as String?,
        placeId: location?['place_id'] as String?,
        latitude: (location?['lat'] as num?)?.toDouble(),
        longitude: (location?['lng'] as num?)?.toDouble(),
        countryCode: location?['country_code'] as String?,
        onboardedAt:
            onboardedAt == null ? null : DateTime.tryParse(onboardedAt!),
      );
}
