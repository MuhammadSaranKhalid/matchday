// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teams_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads the signed-in user's current team memberships.
///
/// My Teams is intentionally one-shot rather than realtime. The controller
/// reloads when it is first built and when the screen explicitly refreshes
/// after returning from a team flow or via pull-to-refresh.

@ProviderFor(TeamsListController)
final teamsListControllerProvider = TeamsListControllerProvider._();

/// Loads the signed-in user's current team memberships.
///
/// My Teams is intentionally one-shot rather than realtime. The controller
/// reloads when it is first built and when the screen explicitly refreshes
/// after returning from a team flow or via pull-to-refresh.
final class TeamsListControllerProvider
    extends $AsyncNotifierProvider<TeamsListController, TeamsListState> {
  /// Loads the signed-in user's current team memberships.
  ///
  /// My Teams is intentionally one-shot rather than realtime. The controller
  /// reloads when it is first built and when the screen explicitly refreshes
  /// after returning from a team flow or via pull-to-refresh.
  TeamsListControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamsListControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamsListControllerHash();

  @$internal
  @override
  TeamsListController create() => TeamsListController();
}

String _$teamsListControllerHash() =>
    r'799b553a596def5d7a0ed1fcc792d52884046b56';

/// Loads the signed-in user's current team memberships.
///
/// My Teams is intentionally one-shot rather than realtime. The controller
/// reloads when it is first built and when the screen explicitly refreshes
/// after returning from a team flow or via pull-to-refresh.

abstract class _$TeamsListController extends $AsyncNotifier<TeamsListState> {
  FutureOr<TeamsListState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TeamsListState>, TeamsListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TeamsListState>, TeamsListState>,
              AsyncValue<TeamsListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
