import 'player_profile.dart';

/// A user's public profile. Keyed by [ProfileUserId] — a wrapper over the auth
/// user id, defined locally so the onboarding domain stays decoupled from the
/// auth feature's own `UserId`.
///
/// A freshly signed-up user has a profile row with a null [username] and null
/// [onboardedAt] (created by the `handle_new_auth_user` Supabase trigger).
/// Onboarding fills it in and stamps `onboarded_at`; [isComplete] (which reads
/// that stamp) is the signal the router's onboarding gate reads.
class Profile {
  const Profile({
    required this.userId,
    this.username,
    this.displayName,
    this.city,
    this.placeId,
    this.latitude,
    this.longitude,
    this.countryCode,
    this.avatarUrl,
    this.bio,
    this.onboardedAt,
    this.playerProfile,
  });

  final ProfileUserId userId;
  final String? username;
  final String? displayName;

  /// Human-readable "City / village" label (e.g. "Mardan, Khyber Pakhtunkhwa").
  /// Stored in the `location` jsonb alongside the structured geo below.
  final String? city;

  /// Google place id when the location came from autocomplete; null for a
  /// GPS-derived or hand-typed location.
  final String? placeId;

  /// Coordinates. Present for autocomplete- and GPS-sourced locations; null only
  /// for the rare hand-typed village that couldn't be resolved. Drives the
  /// future "teams near you" proximity search.
  final double? latitude;
  final double? longitude;

  /// ISO 3166-1 alpha-2 country code (e.g. "PK"), when known.
  final String? countryCode;

  /// Public URL of the avatar in the `avatars` bucket (`profiles.profile_photo_url`).
  final String? avatarUrl;

  /// Free-text bio (`profiles.bio`, ≤200 chars).
  final String? bio;

  /// When onboarding was completed (`profiles.onboarded_at`). Null until then.
  final DateTime? onboardedAt;

  final PlayerProfile? playerProfile;

  /// Whether this profile has resolved coordinates (eligible for proximity).
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Onboarding is complete once the server has stamped `onboarded_at`.
  bool get isComplete => onboardedAt != null;

  Profile copyWith({
    String? username,
    String? displayName,
    String? city,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
    String? avatarUrl,
    String? bio,
    DateTime? onboardedAt,
    PlayerProfile? playerProfile,
  }) =>
      Profile(
        userId: userId,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        city: city ?? this.city,
        placeId: placeId ?? this.placeId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        countryCode: countryCode ?? this.countryCode,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        onboardedAt: onboardedAt ?? this.onboardedAt,
        playerProfile: playerProfile ?? this.playerProfile,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          other.userId == userId &&
          other.username == username &&
          other.displayName == displayName &&
          other.city == city &&
          other.placeId == placeId &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.countryCode == countryCode &&
          other.avatarUrl == avatarUrl &&
          other.bio == bio &&
          other.onboardedAt == onboardedAt &&
          other.playerProfile == playerProfile;

  @override
  int get hashCode => Object.hash(
        userId,
        username,
        displayName,
        city,
        placeId,
        latitude,
        longitude,
        countryCode,
        avatarUrl,
        bio,
        onboardedAt,
        playerProfile,
      );
}

/// The owning user's id (the `profiles.user_id` PK, which references
/// `auth.users`). Wrapped per the "IDs are never raw strings" rule.
class ProfileUserId {
  const ProfileUserId(this.value);
  final String value;

  @override
  bool operator ==(Object other) =>
      other is ProfileUserId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
