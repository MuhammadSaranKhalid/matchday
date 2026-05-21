import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/entities/user.dart';
import '../../domain/value_objects/email.dart';

/// Wire-format user.
///
/// Built from Supabase's `User` object. Notice the metadata fields:
/// for OTP users displayName is whatever they later set on a `profiles`
/// table; for Google users it comes from the OAuth identity payload.
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  /// Build a DTO from a Supabase auth user.
  /// Reads displayName/avatar from userMetadata when present (Google),
  /// falls back to the email's local part for OTP-only users.
  factory UserDto.fromSupabaseUser(sb.User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = metadata['full_name'] as String?;
    final name = metadata['name'] as String?;
    final avatar = metadata['avatar_url'] as String? ??
        metadata['picture'] as String?;

    return UserDto(
      id: user.id,
      email: user.email ?? '',
      displayName: fullName ?? name ?? (user.email?.split('@').first ?? 'User'),
      avatarUrl: avatar,
    );
  }

  /// DTO → Entity.
  User toEntity() {
    final emailVO = Email.create(email).getOrElse(
      (_) => throw StateError('Supabase returned malformed email: $email'),
    );
    return User(
      id: UserId(id),
      email: emailVO,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}
