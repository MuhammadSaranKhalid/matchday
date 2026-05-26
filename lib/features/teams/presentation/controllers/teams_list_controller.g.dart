// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teams_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Composes the "My teams" view from three sources — the user's teams (local),
/// their active matches (online), and the cached teams used to resolve opponent
/// names. Keeps the screen a pure renderer (CLAUDE.md §5.3 / §6.6).

@ProviderFor(TeamsListController)
final teamsListControllerProvider = TeamsListControllerProvider._();

/// Composes the "My teams" view from three sources — the user's teams (local),
/// their active matches (online), and the cached teams used to resolve opponent
/// names. Keeps the screen a pure renderer (CLAUDE.md §5.3 / §6.6).
final class TeamsListControllerProvider
    extends $AsyncNotifierProvider<TeamsListController, TeamsListView> {
  /// Composes the "My teams" view from three sources — the user's teams (local),
  /// their active matches (online), and the cached teams used to resolve opponent
  /// names. Keeps the screen a pure renderer (CLAUDE.md §5.3 / §6.6).
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
    r'7d5d57346fb8815613031843a62c11b37e019d22';

/// Composes the "My teams" view from three sources — the user's teams (local),
/// their active matches (online), and the cached teams used to resolve opponent
/// names. Keeps the screen a pure renderer (CLAUDE.md §5.3 / §6.6).

abstract class _$TeamsListController extends $AsyncNotifier<TeamsListView> {
  FutureOr<TeamsListView> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TeamsListView>, TeamsListView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TeamsListView>, TeamsListView>,
              AsyncValue<TeamsListView>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
