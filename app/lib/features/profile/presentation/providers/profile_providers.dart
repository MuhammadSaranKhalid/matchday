import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/supabase/supabase_auth_state_provider.dart';
import '../../data/datasources/avatar_picker_impl.dart';
import '../../data/datasources/profile_datasource_providers.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/avatar_picker.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
AvatarPicker avatarPicker(Ref ref) => const AvatarPickerImpl();

/// The signed-in user's profile, for the Pavilion header. Throws a
/// [FailureWrapper] on error so the UI can render it via AsyncError.
/// keepAlive so it's fetched once and shared, not refetched per screen.
@Riverpod(keepAlive: true)
Future<Profile?> myProfile(Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  final result = await ref.read(profileRepositoryProvider).getMyProfile();
  return result.fold((f) => throw FailureWrapper(f), (p) => p);
}

/// Any user's public profile by [username] — backs the `/u/:username` route
/// and shared-link landing (a tapped `joinmatchday.com/u/<username>` opens
/// here). Resolves to null when the username isn't found, so the screen can
/// render a "not found" state. Throws a [FailureWrapper] on a fetch error
/// (rendered via AsyncError). Autodispose: a viewed profile shouldn't pin
/// memory once the screen is gone.
@riverpod
Future<Profile?> profileByUsername(Ref ref, String username) async {
  final result =
      await ref.read(profileRepositoryProvider).getByUsername(username);
  return result.fold((f) => throw FailureWrapper(f), (p) => p);
}
