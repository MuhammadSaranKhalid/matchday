// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teams_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Builds the "My teams" screen's [MyTeamsView] directly from three sources —
/// the user's teams (local stream), their active matches (online), and the
/// cached teams used to resolve opponent crests — plus the signed-in user id
/// to bucket teams by relationship. The screen stays a pure renderer
/// (CLAUDE.md §5.3 / §6.6); there is no intermediate view shape or adapter.
///
/// The filter is local UI state held here (not in the widget): [setFilter]
/// re-derives the view from the cached base data without re-fetching.

@ProviderFor(TeamsListController)
final teamsListControllerProvider = TeamsListControllerProvider._();

/// Builds the "My teams" screen's [MyTeamsView] directly from three sources —
/// the user's teams (local stream), their active matches (online), and the
/// cached teams used to resolve opponent crests — plus the signed-in user id
/// to bucket teams by relationship. The screen stays a pure renderer
/// (CLAUDE.md §5.3 / §6.6); there is no intermediate view shape or adapter.
///
/// The filter is local UI state held here (not in the widget): [setFilter]
/// re-derives the view from the cached base data without re-fetching.
final class TeamsListControllerProvider
    extends $AsyncNotifierProvider<TeamsListController, MyTeamsView> {
  /// Builds the "My teams" screen's [MyTeamsView] directly from three sources —
  /// the user's teams (local stream), their active matches (online), and the
  /// cached teams used to resolve opponent crests — plus the signed-in user id
  /// to bucket teams by relationship. The screen stays a pure renderer
  /// (CLAUDE.md §5.3 / §6.6); there is no intermediate view shape or adapter.
  ///
  /// The filter is local UI state held here (not in the widget): [setFilter]
  /// re-derives the view from the cached base data without re-fetching.
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
    r'72e1cc2d94b94e877ac31fbb08f56cff44cb19e0';

/// Builds the "My teams" screen's [MyTeamsView] directly from three sources —
/// the user's teams (local stream), their active matches (online), and the
/// cached teams used to resolve opponent crests — plus the signed-in user id
/// to bucket teams by relationship. The screen stays a pure renderer
/// (CLAUDE.md §5.3 / §6.6); there is no intermediate view shape or adapter.
///
/// The filter is local UI state held here (not in the widget): [setFilter]
/// re-derives the view from the cached base data without re-fetching.

abstract class _$TeamsListController extends $AsyncNotifier<MyTeamsView> {
  FutureOr<MyTeamsView> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MyTeamsView>, MyTeamsView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MyTeamsView>, MyTeamsView>,
              AsyncValue<MyTeamsView>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
