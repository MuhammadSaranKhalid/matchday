import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../profile/domain/value_objects/city.dart';
import '../../../profile/domain/value_objects/display_name.dart';
import '../../../profile/domain/value_objects/username.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../state/profile_edit_state.dart';

part 'profile_edit_controller.g.dart';

const _maxBio = 200;

@riverpod
class ProfileEditController extends _$ProfileEditController {
  @override
  ProfileEditState build() {
    final profile = ref.read(myProfileProvider).value;
    return ProfileEditState.initial(profile);
  }

  void setDisplayName(String value) => state = state.copyWith(displayName: value);
  void setUsername(String value) => state = state.copyWith(username: value);
  void setBio(String value) => state = state.copyWith(bio: value);
  void setCity(String value) => state = state.copyWith(city: value);

  Future<void> useGps() async {
    // Fake GPS delay
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!ref.mounted) return;
    state = state.copyWith(city: 'Korangi, Karachi');
  }

  Future<void> pickAvatar() async {
    final file = await ref.read(avatarPickerProvider).pickSquare();
    if (file == null || !ref.mounted) return;
    state = state.copyWith(avatar: file);
  }

  Future<bool> save() async {
    state = state.copyWith(saving: true, error: null);

    final nameRes = DisplayName.create(state.displayName);
    if (nameRes.isLeft()) {
      state = state.copyWith(saving: false, error: nameRes.getLeft().toNullable());
      return false;
    }
    final cityRes = City.create(state.city);
    if (cityRes.isLeft()) {
      state = state.copyWith(saving: false, error: cityRes.getLeft().toNullable());
      return false;
    }

    final usernameChanged = state.username.trim() != (state.originalUsername ?? '');
    Username? usernameVo;
    if (usernameChanged) {
      final uRes = Username.create(state.username);
      if (uRes.isLeft()) {
        state = state.copyWith(saving: false, error: uRes.getLeft().toNullable());
        return false;
      }
      usernameVo = uRes.getRight().toNullable();
    }

    final bioTrimmed = state.bio.trim();
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
          placeId: state.placeId,
          latitude: state.latitude,
          longitude: state.longitude,
          countryCode: state.countryCode,
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
