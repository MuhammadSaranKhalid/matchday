import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/avatar_picker_impl.dart';
import '../../data/datasources/onboarding_datasource_providers.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/avatar_picker.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/check_username_available.dart';
import '../../domain/usecases/complete_onboarding.dart';
import '../../domain/usecases/get_my_profile.dart';
import '../../domain/usecases/update_profile.dart';

part 'onboarding_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepositoryImpl(ref.watch(onboardingRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
AvatarPicker avatarPicker(Ref ref) => const AvatarPickerImpl();

@riverpod
UpdateProfile updateProfileUseCase(Ref ref) =>
    UpdateProfile(ref.watch(profileRepositoryProvider));

@riverpod
GetMyProfile getMyProfileUseCase(Ref ref) =>
    GetMyProfile(ref.watch(profileRepositoryProvider));

@riverpod
CheckUsernameAvailable checkUsernameAvailableUseCase(Ref ref) =>
    CheckUsernameAvailable(ref.watch(profileRepositoryProvider));

@riverpod
CompleteOnboarding completeOnboardingUseCase(Ref ref) =>
    CompleteOnboarding(ref.watch(profileRepositoryProvider));

/// Whether the signed-in user has finished onboarding (has a username).
///
/// The router's redirect reads this via `.value` to gate `/onboarding`. It
/// depends on [currentUserStreamProvider] so it recomputes on sign-in/out, and
/// is invalidated by the onboarding controller when the user finishes, which
/// pokes the router's refreshListenable to re-run the redirect.
@Riverpod(keepAlive: true)
Future<bool> onboardingStatus(Ref ref) async {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return false;

  // read (not watch): a one-shot fetch. Watching would pin the autodispose
  // use-case provider alive for this keepAlive provider's lifetime.
  final result = await ref.read(getMyProfileUseCaseProvider).call(
        const NoParams(),
      );
  return result.fold(
    // On a transient fetch error, don't trap the user on /onboarding — treat
    // as "unknown" and let them through; the next refresh re-evaluates.
    (_) => true,
    (profile) => profile?.isComplete ?? false,
  );
}

/// The signed-in user's profile, for the Pavilion header. Throws a
/// [FailureWrapper] on error so the UI can render it via AsyncError.
/// keepAlive so it's fetched once and shared, not refetched per screen.
@Riverpod(keepAlive: true)
Future<Profile?> myProfile(Ref ref) async {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return null;
  final result = await ref.read(getMyProfileUseCaseProvider).call(const NoParams());
  return result.fold((f) => throw FailureWrapper(f), (p) => p);
}
