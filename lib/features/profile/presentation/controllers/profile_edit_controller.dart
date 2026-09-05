import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../profile/domain/value_objects/display_name.dart';
import '../../../profile/domain/value_objects/username.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../state/profile_edit_state.dart';

part 'profile_edit_controller.g.dart';

const _maxBio = 200;

/// "400 ms after typing stops" — artboard 2a.
const _usernameDebounce = Duration(milliseconds: 400);

@riverpod
class ProfileEditController extends _$ProfileEditController {
  Timer? _usernameDebounceTimer;

  /// Guards against a slow early response overwriting a later one: only the
  /// most recent request may publish a result.
  int _usernameRequest = 0;

  @override
  ProfileEditState build() {
    ref.onDispose(() => _usernameDebounceTimer?.cancel());
    final profile = ref.read(myProfileProvider).value;
    return ProfileEditState.initial(profile);
  }

  void setDisplayName(String value) => state = state.copyWith(
        displayName: value,
        nameError: null,
      );

  void setBio(String value) => state = state.copyWith(bio: value);

  /// Every keystroke restarts the debounce. Reverting to the server value
  /// clears the chip entirely rather than asking whether you may keep your own
  /// handle.
  void setUsername(String value) {
    _usernameDebounceTimer?.cancel();
    state = state.copyWith(username: value, usernameError: null);

    if (!state.usernameChanged) {
      state = state.copyWith(usernameStatus: UsernameStatus.untouched);
      return;
    }

    final parsed = Username.create(value);
    if (parsed.isLeft()) {
      state = state.copyWith(
        usernameStatus: UsernameStatus.invalid,
        usernameError: parsed.getLeft().toNullable()?.message,
      );
      return;
    }

    state = state.copyWith(usernameStatus: UsernameStatus.checking);
    _usernameDebounceTimer = Timer(_usernameDebounce, _checkUsername);
  }

  Future<void> _checkUsername() async {
    final request = ++_usernameRequest;
    final candidate = Username.create(state.username);
    final vo = candidate.getRight().toNullable();
    if (vo == null) return;

    final result =
        await ref.read(profileRepositoryProvider).isUsernameAvailable(vo.value);
    if (!ref.mounted || request != _usernameRequest) return;

    state = result.fold(
      // A failed check must not read as "taken" — that would block a save over
      // a network blip. It reverts to untouched so Save stays reachable and
      // the server has the last word.
      (_) => state.copyWith(usernameStatus: UsernameStatus.untouched),
      (free) => state.copyWith(
        usernameStatus:
            free ? UsernameStatus.available : UsernameStatus.taken,
        usernameError: free ? null : 'That username is taken.',
      ),
    );
  }

  Future<void> pickAvatar() async {
    final file = await ref.read(avatarPickerProvider).pickSquare();
    if (file == null || !ref.mounted) return;
    state = state.copyWith(avatar: file);
  }

  Future<void> pickCover() async {
    final file = await ref.read(avatarPickerProvider).pickCover();
    if (file == null || !ref.mounted) return;
    state = state.copyWith(cover: file);
  }

  Future<bool> save() async {
    state = state.copyWith(saving: true, error: null, nameError: null);

    final nameRes = DisplayName.create(state.displayName);
    if (nameRes.isLeft()) {
      state = state.copyWith(
        saving: false,
        // 1a puts the reason on the offending field, not in a banner.
        nameError: state.displayName.trim().isEmpty
            ? "Your name can't be empty."
            : nameRes.getLeft().toNullable()?.message,
      );
      return false;
    }

    Username? usernameVo;
    if (state.usernameChanged) {
      final uRes = Username.create(state.username);
      if (uRes.isLeft()) {
        state = state.copyWith(
          saving: false,
          usernameError: uRes.getLeft().toNullable()?.message,
          usernameStatus: UsernameStatus.invalid,
        );
        return false;
      }
      usernameVo = uRes.getRight().toNullable();
    }

    final bioTrimmed = _collapse(state.bio);
    if (bioTrimmed.length > _maxBio) {
      state = state.copyWith(
        saving: false,
        error: const ValidationFailure(
          'Bio is too long (max $_maxBio characters).',
        ),
      );
      return false;
    }

    // No city, no geo: artboard 1a removes location from this form, and the
    // repository leaves the stored value alone when none is passed.
    final result = await ref.read(profileRepositoryProvider).updateProfile(
          displayName: nameRes.getRight().toNullable()!,
          username: usernameVo,
          bio: bioTrimmed.isEmpty ? null : bioTrimmed,
          avatar: state.avatar,
          cover: state.cover,
        );
    if (!ref.mounted) return false;
    return result.fold(
      (failure) {
        // "Stay on the form, keep every edit" — nothing is cleared here.
        state = state.copyWith(saving: false, error: failure);
        return false;
      },
      (_) {
        ref.invalidate(myProfileProvider);
        return true;
      },
    );
  }

  /// "newlines collapsed to spaces" — artboard 2a.
  String _collapse(String input) =>
      input.replaceAll(RegExp(r'\s*\n+\s*'), ' ').trim();
}
