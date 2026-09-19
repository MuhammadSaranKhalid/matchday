// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TeamSearchController)
final teamSearchControllerProvider = TeamSearchControllerProvider._();

final class TeamSearchControllerProvider
    extends $NotifierProvider<TeamSearchController, TeamSearchState> {
  TeamSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamSearchControllerHash();

  @$internal
  @override
  TeamSearchController create() => TeamSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamSearchState>(value),
    );
  }
}

String _$teamSearchControllerHash() =>
    r'6406734b0fd5d24580d16ef05a0129551b07719d';

abstract class _$TeamSearchController extends $Notifier<TeamSearchState> {
  TeamSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TeamSearchState, TeamSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TeamSearchState, TeamSearchState>,
              TeamSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
