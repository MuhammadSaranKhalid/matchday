// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_see_all_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs the single-category drill-down ("See all — Teams").
///
/// A plain [AsyncNotifier] family rather than a stateful Notifier: this
/// screen has a fixed query and category for its whole lifetime, so there is
/// no debounce and no race to defeat — the two things that forced
/// [ExploreController] to hand-roll its state.

@ProviderFor(ExploreSeeAll)
final exploreSeeAllProvider = ExploreSeeAllFamily._();

/// Backs the single-category drill-down ("See all — Teams").
///
/// A plain [AsyncNotifier] family rather than a stateful Notifier: this
/// screen has a fixed query and category for its whole lifetime, so there is
/// no debounce and no race to defeat — the two things that forced
/// [ExploreController] to hand-roll its state.
final class ExploreSeeAllProvider
    extends $AsyncNotifierProvider<ExploreSeeAll, ExploreResults> {
  /// Backs the single-category drill-down ("See all — Teams").
  ///
  /// A plain [AsyncNotifier] family rather than a stateful Notifier: this
  /// screen has a fixed query and category for its whole lifetime, so there is
  /// no debounce and no race to defeat — the two things that forced
  /// [ExploreController] to hand-roll its state.
  ExploreSeeAllProvider._({
    required ExploreSeeAllFamily super.from,
    required (String, ExploreCategory) super.argument,
  }) : super(
         retry: null,
         name: r'exploreSeeAllProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exploreSeeAllHash();

  @override
  String toString() {
    return r'exploreSeeAllProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ExploreSeeAll create() => ExploreSeeAll();

  @override
  bool operator ==(Object other) {
    return other is ExploreSeeAllProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exploreSeeAllHash() => r'0f9e92ee010e6114d468e5f031b3a2154d5d0fd9';

/// Backs the single-category drill-down ("See all — Teams").
///
/// A plain [AsyncNotifier] family rather than a stateful Notifier: this
/// screen has a fixed query and category for its whole lifetime, so there is
/// no debounce and no race to defeat — the two things that forced
/// [ExploreController] to hand-roll its state.

final class ExploreSeeAllFamily extends $Family
    with
        $ClassFamilyOverride<
          ExploreSeeAll,
          AsyncValue<ExploreResults>,
          ExploreResults,
          FutureOr<ExploreResults>,
          (String, ExploreCategory)
        > {
  ExploreSeeAllFamily._()
    : super(
        retry: null,
        name: r'exploreSeeAllProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Backs the single-category drill-down ("See all — Teams").
  ///
  /// A plain [AsyncNotifier] family rather than a stateful Notifier: this
  /// screen has a fixed query and category for its whole lifetime, so there is
  /// no debounce and no race to defeat — the two things that forced
  /// [ExploreController] to hand-roll its state.

  ExploreSeeAllProvider call(String query, ExploreCategory category) =>
      ExploreSeeAllProvider._(argument: (query, category), from: this);

  @override
  String toString() => r'exploreSeeAllProvider';
}

/// Backs the single-category drill-down ("See all — Teams").
///
/// A plain [AsyncNotifier] family rather than a stateful Notifier: this
/// screen has a fixed query and category for its whole lifetime, so there is
/// no debounce and no race to defeat — the two things that forced
/// [ExploreController] to hand-roll its state.

abstract class _$ExploreSeeAll extends $AsyncNotifier<ExploreResults> {
  late final _$args = ref.$arg as (String, ExploreCategory);
  String get query => _$args.$1;
  ExploreCategory get category => _$args.$2;

  FutureOr<ExploreResults> build(String query, ExploreCategory category);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ExploreResults>, ExploreResults>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExploreResults>, ExploreResults>,
              AsyncValue<ExploreResults>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
