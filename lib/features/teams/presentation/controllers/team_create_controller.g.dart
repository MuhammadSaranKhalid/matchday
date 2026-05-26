// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_create_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the 5-step team-create wizard. AsyncNotifier so [build] can restore a
/// persisted draft before the form seeds (mirrors OnboardingController).

@ProviderFor(TeamCreateController)
final teamCreateControllerProvider = TeamCreateControllerProvider._();

/// Drives the 5-step team-create wizard. AsyncNotifier so [build] can restore a
/// persisted draft before the form seeds (mirrors OnboardingController).
final class TeamCreateControllerProvider
    extends $AsyncNotifierProvider<TeamCreateController, TeamCreateState> {
  /// Drives the 5-step team-create wizard. AsyncNotifier so [build] can restore a
  /// persisted draft before the form seeds (mirrors OnboardingController).
  TeamCreateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamCreateControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamCreateControllerHash();

  @$internal
  @override
  TeamCreateController create() => TeamCreateController();
}

String _$teamCreateControllerHash() =>
    r'e4b1a21491b94ea6a40cef1012c51953426e94d3';

/// Drives the 5-step team-create wizard. AsyncNotifier so [build] can restore a
/// persisted draft before the form seeds (mirrors OnboardingController).

abstract class _$TeamCreateController extends $AsyncNotifier<TeamCreateState> {
  FutureOr<TeamCreateState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TeamCreateState>, TeamCreateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TeamCreateState>, TeamCreateState>,
              AsyncValue<TeamCreateState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
