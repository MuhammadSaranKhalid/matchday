import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../onboarding/domain/usecases/update_profile.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';

part 'profile_edit_controller.g.dart';

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
    final result = await ref.read(updateProfileUseCaseProvider).call(
          UpdateProfileParams(
            displayName: displayName,
            username: username,
            usernameChanged: username.trim() != (originalUsername ?? ''),
            bio: bio,
            city: city,
            placeId: placeId,
            latitude: latitude,
            longitude: longitude,
            countryCode: countryCode,
            avatar: state.avatar,
          ),
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
