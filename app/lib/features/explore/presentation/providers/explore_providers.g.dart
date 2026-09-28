// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns the ABSTRACT type — consumers never see the impl (CLAUDE.md §5.3).

@ProviderFor(exploreRepository)
final exploreRepositoryProvider = ExploreRepositoryProvider._();

/// Returns the ABSTRACT type — consumers never see the impl (CLAUDE.md §5.3).

final class ExploreRepositoryProvider
    extends
        $FunctionalProvider<
          ExploreRepository,
          ExploreRepository,
          ExploreRepository
        >
    with $Provider<ExploreRepository> {
  /// Returns the ABSTRACT type — consumers never see the impl (CLAUDE.md §5.3).
  ExploreRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExploreRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExploreRepository create(Ref ref) {
    return exploreRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExploreRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExploreRepository>(value),
    );
  }
}

String _$exploreRepositoryHash() => r'be6cb19373cf7bf3d4fbed6677be3c22361d20d5';

/// The empty-query discovery content: live matches, recent teams, players to
/// follow.
///
/// A plain async provider rather than a method on [ExploreController],
/// because browse is a pure read with no imperative actions and no race to
/// defeat. Keeping it here also keeps the controller's `build()` free of the
/// state mutation that kicking it off from there would require — which
/// Riverpod rejects outright ("a provider rebuilt while the previous build
/// was still pending").
///
/// Refresh with `ref.invalidate(exploreBrowseProvider)`.

@ProviderFor(exploreBrowse)
final exploreBrowseProvider = ExploreBrowseProvider._();

/// The empty-query discovery content: live matches, recent teams, players to
/// follow.
///
/// A plain async provider rather than a method on [ExploreController],
/// because browse is a pure read with no imperative actions and no race to
/// defeat. Keeping it here also keeps the controller's `build()` free of the
/// state mutation that kicking it off from there would require — which
/// Riverpod rejects outright ("a provider rebuilt while the previous build
/// was still pending").
///
/// Refresh with `ref.invalidate(exploreBrowseProvider)`.

final class ExploreBrowseProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExploreBrowse>,
          ExploreBrowse,
          FutureOr<ExploreBrowse>
        >
    with $FutureModifier<ExploreBrowse>, $FutureProvider<ExploreBrowse> {
  /// The empty-query discovery content: live matches, recent teams, players to
  /// follow.
  ///
  /// A plain async provider rather than a method on [ExploreController],
  /// because browse is a pure read with no imperative actions and no race to
  /// defeat. Keeping it here also keeps the controller's `build()` free of the
  /// state mutation that kicking it off from there would require — which
  /// Riverpod rejects outright ("a provider rebuilt while the previous build
  /// was still pending").
  ///
  /// Refresh with `ref.invalidate(exploreBrowseProvider)`.
  ExploreBrowseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreBrowseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreBrowseHash();

  @$internal
  @override
  $FutureProviderElement<ExploreBrowse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExploreBrowse> create(Ref ref) {
    return exploreBrowse(ref);
  }
}

String _$exploreBrowseHash() => r'882895559097523d388bc5676a68d4d47e7cc3c7';
