import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/profile.dart';

part 'profile_edit_state.freezed.dart';

/// Where the live uniqueness check has got to (artboard 1a, chip states).
enum UsernameStatus {
  /// Unchanged from the server value — the chip is not shown at all.
  untouched,

  /// Format is wrong, so no request was made.
  invalid,

  /// 400 ms debounce elapsed, request in flight.
  checking,
  available,
  taken,
}

@freezed
abstract class ProfileEditState with _$ProfileEditState {
  const factory ProfileEditState({
    @Default('') String displayName,
    @Default('') String username,
    @Default('') String bio,

    /// Seeded from the loaded profile. Save compares against these to decide
    /// whether anything actually changed, and passes the username through only
    /// when it differs so an unchanged handle never trips the cooldown.
    @Default('') String originalDisplayName,
    @Default('') String originalUsername,
    @Default('') String originalBio,

    /// Newly-picked images awaiting upload on save.
    File? avatar,
    File? cover,
    String? currentAvatarUrl,
    String? currentCoverUrl,
    @Default(UsernameStatus.untouched) UsernameStatus usernameStatus,

    /// Set when the username is invalid or taken, or when a save came back
    /// with a field-specific reason. Rendered under the offending field.
    String? usernameError,
    String? nameError,
    @Default(false) bool saving,
    Failure? error,
  }) = _ProfileEditState;

  const ProfileEditState._();

  factory ProfileEditState.initial(Profile? profile) {
    if (profile == null) return const ProfileEditState();
    return ProfileEditState(
      displayName: profile.displayName ?? '',
      username: profile.username ?? '',
      bio: profile.bio ?? '',
      originalDisplayName: profile.displayName ?? '',
      originalUsername: profile.username ?? '',
      originalBio: profile.bio ?? '',
      currentAvatarUrl: profile.avatarUrl,
      currentCoverUrl: profile.coverUrl,
    );
  }

  bool get usernameChanged => username.trim() != originalUsername;

  /// "Save enables on the first character that differs from the server value,
  /// and disables again if the user reverts it. Photo/cover picks count as
  /// dirty." — artboard 2a.
  bool get dirty =>
      displayName != originalDisplayName ||
      usernameChanged ||
      bio != originalBio ||
      avatar != null ||
      cover != null;

  /// Save is live only when something changed *and* the handle is settled.
  /// A checking or taken username holds it down (2a).
  bool get canSave =>
      dirty &&
      !saving &&
      usernameStatus != UsernameStatus.checking &&
      usernameStatus != UsernameStatus.taken &&
      usernameStatus != UsernameStatus.invalid;
}
