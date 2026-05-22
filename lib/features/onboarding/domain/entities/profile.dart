import 'player_profile.dart';

/// A user's public profile. Keyed by [ProfileUserId] — a wrapper over the auth
/// user id, defined locally so the onboarding domain stays decoupled from the
/// auth feature's own `UserId`.
///
/// A freshly signed-up user has a profile row with a null [username] (created
/// by the `handle_new_user` Supabase trigger). Onboarding fills it in;
/// [isComplete] is the signal the router's onboarding gate reads.
class Profile {
  const Profile({
    required this.userId,
    this.username,
    this.displayName,
    this.city,
    this.playerProfile,
  });

  final ProfileUserId userId;
  final String? username;
  final String? displayName;

  /// Free-text "City / village" as entered (e.g. "Lahore, Punjab"). Stored as
  /// `location` jsonb (`{ "city": ... }`) per the design's single-field step.
  final String? city;

  final PlayerProfile? playerProfile;

  /// Onboarding is complete once a username has been claimed.
  bool get isComplete => username != null && username!.isNotEmpty;

  Profile copyWith({
    String? username,
    String? displayName,
    String? city,
    PlayerProfile? playerProfile,
  }) =>
      Profile(
        userId: userId,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        city: city ?? this.city,
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
          other.playerProfile == playerProfile;

  @override
  int get hashCode =>
      Object.hash(userId, username, displayName, city, playerProfile);
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
