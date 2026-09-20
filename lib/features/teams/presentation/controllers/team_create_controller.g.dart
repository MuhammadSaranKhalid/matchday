// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_create_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the five-step team-create wizard.

@ProviderFor(TeamCreateController)
final teamCreateControllerProvider = TeamCreateControllerProvider._();

/// Drives the five-step team-create wizard.
final class TeamCreateControllerProvider
    extends $AsyncNotifierProvider<TeamCreateController, TeamCreateState> {
  /// Drives the five-step team-create wizard.
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
    r'c074ca17320e5ffeec38beef9e60d4bff23161cf';

/// Drives the five-step team-create wizard.

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
