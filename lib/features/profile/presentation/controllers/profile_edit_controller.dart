import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../onboarding/domain/value_objects/city.dart';
import '../../../onboarding/domain/value_objects/display_name.dart';
import '../../../onboarding/domain/value_objects/username.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';

part 'profile_edit_controller.g.dart';

const _maxBio = 200;

class ProfileEditState {
  const ProfileEditState({this.avatar, this.saving = false, this.error});

  /// Newly-picked avatar (square-cropped, resized) awaiting upload on save.
  final File? avatar;
  final bool saving;
  final Failure? error;

  ProfileEditState copyWith({
    File? avatar,
    bool? saving,
    Failure? error,
    bool clearError = false,
  }) =>
      ProfileEditState(
        avatar: avatar ?? this.avatar,
        saving: saving ?? this.saving,
        error: clearError ? null : (error ?? this.error),
      );
}

@riverpod
class ProfileEditController extends _$ProfileEditController {
  @override
  ProfileEditState build() => const ProfileEditState();

  Future<void> pickAvatar() async {
    final file = await ref.read(avatarPickerProvider).pickSquare();
    if (file == null || !ref.mounted) return;
    state = state.copyWith(avatar: file);
  }

  /// Save the edits. Returns true on success (and refreshes [myProfileProvider]).
  /// [originalUsername] avoids re-sending an unchanged username (30-day cooldown).
  Future<bool> save({
    required String displayName,
    required String username,
    required String? originalUsername,
    required String bio,
    required String city,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
  }) async {
    state = state.copyWith(saving: true, clearError: true);

    final nameRes = DisplayName.create(displayName);
    if (nameRes.isLeft()) {
      state = state.copyWith(saving: false, error: nameRes.getLeft().toNullable());
      return false;
    }
    final cityRes = City.create(city);
    if (cityRes.isLeft()) {
      state = state.copyWith(saving: false, error: cityRes.getLeft().toNullable());
      return false;
    }

    final usernameChanged = username.trim() != (originalUsername ?? '');
    Username? usernameVo;
    if (usernameChanged) {
      final uRes = Username.create(username);
      if (uRes.isLeft()) {
        state = state.copyWith(saving: false, error: uRes.getLeft().toNullable());
        return false;
      }
      usernameVo = uRes.getRight().toNullable();
    }

    final bioTrimmed = bio.trim();
    if (bioTrimmed.length > _maxBio) {
      state = state.copyWith(
        saving: false,
        error: const ValidationFailure('Bio is too long (max $_maxBio characters).'),
      );
      return false;
    }

    final result = await ref.read(profileRepositoryProvider).updateProfile(
          displayName: nameRes.getRight().toNullable()!,
          username: usernameVo,
          bio: bioTrimmed.isEmpty ? null : bioTrimmed,
          city: cityRes.getRight().toNullable()!,
          placeId: placeId,
          latitude: latitude,
          longitude: longitude,
          countryCode: countryCode,
          avatar: state.avatar,
        );
    if (!ref.mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(saving: false, error: failure);
        return false;
      },
      (_) {
        ref.invalidate(myProfileProvider);
        return true;
      },
    );
  }
}
