import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/profile.dart';

part 'profile_edit_state.freezed.dart';

@freezed
abstract class ProfileEditState with _$ProfileEditState {
  const factory ProfileEditState({
    @Default('') String displayName,
    @Default('') String username,
    @Default('') String bio,
    @Default('') String city,
    
    // Seeded from the loaded profile; passed through on save so we don't wipe geo
    // or trip the username cooldown on an unchanged handle.
    String? originalUsername,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,

    /// Newly-picked avatar (square-cropped, resized) awaiting upload on save.
    File? avatar,
    String? currentAvatarUrl,

    @Default(false) bool saving,
    Failure? error,
  }) = _ProfileEditState;

  factory ProfileEditState.initial(Profile? profile) {
    if (profile == null) return const ProfileEditState();
    return ProfileEditState(
      displayName: profile.displayName ?? '',
      username: profile.username ?? '',
      bio: profile.bio ?? '',
      city: profile.city ?? '',
      originalUsername: profile.username,
      placeId: profile.placeId,
      latitude: profile.latitude,
      longitude: profile.longitude,
      countryCode: profile.countryCode,
      currentAvatarUrl: profile.avatarUrl,
    );
  }
}
