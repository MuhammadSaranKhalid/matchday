import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

part 'onboarding_providers.g.dart';

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

  final result = await ref.read(profileRepositoryProvider).getMyProfile();
  return result.fold(
    // On a transient fetch error, don't trap the user on /onboarding — treat
    // as "unknown" and let them through; the next refresh re-evaluates.
    (_) => true,
    (profile) => profile?.isComplete ?? false,
  );
}
