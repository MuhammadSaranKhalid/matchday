import '../value_objects/email.dart';

/// Business representation of a user.
///
/// avatarUrl is optional because email-OTP users won't have one until they
/// upload, while Google sign-in users get it from their Google profile.
class User {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  final UserId id;
  final Email email;
  final String displayName;
  final String? avatarUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          other.id == id &&
          other.email == email &&
          other.displayName == displayName &&
          other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, email, displayName, avatarUrl);
}

class UserId {
  const UserId(this.value);
  final String value;
  @override
  bool operator ==(Object other) => other is UserId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
