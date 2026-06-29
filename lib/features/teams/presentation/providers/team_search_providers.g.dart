// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Top cities by team count for the search filter chips. Cached per
/// [countryCode] (null = caller's profile country, defaulted server-side).
///
/// Facets change slowly (a new team materialising in a new village isn't
/// continuous traffic), so this stays autodispose — the provider rebuilds
/// when the Search tab is opened again, and a pull-to-refresh triggers
/// `ref.invalidate`. We deliberately do NOT subscribe to a realtime stream
/// here; facet drift is fine.

@ProviderFor(placeFacets)
final placeFacetsProvider = PlaceFacetsFamily._();

/// Top cities by team count for the search filter chips. Cached per
/// [countryCode] (null = caller's profile country, defaulted server-side).
///
/// Facets change slowly (a new team materialising in a new village isn't
/// continuous traffic), so this stays autodispose — the provider rebuilds
/// when the Search tab is opened again, and a pull-to-refresh triggers
/// `ref.invalidate`. We deliberately do NOT subscribe to a realtime stream
/// here; facet drift is fine.

final class PlaceFacetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaceFacet>>,
          List<PlaceFacet>,
          FutureOr<List<PlaceFacet>>
        >
    with $FutureModifier<List<PlaceFacet>>, $FutureProvider<List<PlaceFacet>> {
  /// Top cities by team count for the search filter chips. Cached per
  /// [countryCode] (null = caller's profile country, defaulted server-side).
  ///
  /// Facets change slowly (a new team materialising in a new village isn't
  /// continuous traffic), so this stays autodispose — the provider rebuilds
  /// when the Search tab is opened again, and a pull-to-refresh triggers
  /// `ref.invalidate`. We deliberately do NOT subscribe to a realtime stream
  /// here; facet drift is fine.
  PlaceFacetsProvider._({
    required PlaceFacetsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'placeFacetsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$placeFacetsHash();

  @override
  String toString() {
    return r'placeFacetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlaceFacet>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlaceFacet>> create(Ref ref) {
    final argument = this.argument as String?;
    return placeFacets(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaceFacetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placeFacetsHash() => r'fae229894213c804e371734f84089a25be4990d9';

/// Top cities by team count for the search filter chips. Cached per
/// [countryCode] (null = caller's profile country, defaulted server-side).
///
/// Facets change slowly (a new team materialising in a new village isn't
/// continuous traffic), so this stays autodispose — the provider rebuilds
/// when the Search tab is opened again, and a pull-to-refresh triggers
/// `ref.invalidate`. We deliberately do NOT subscribe to a realtime stream
/// here; facet drift is fine.

final class PlaceFacetsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlaceFacet>>, String?> {
  PlaceFacetsFamily._()
    : super(
        retry: null,
        name: r'placeFacetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Top cities by team count for the search filter chips. Cached per
  /// [countryCode] (null = caller's profile country, defaulted server-side).
  ///
  /// Facets change slowly (a new team materialising in a new village isn't
  /// continuous traffic), so this stays autodispose — the provider rebuilds
  /// when the Search tab is opened again, and a pull-to-refresh triggers
  /// `ref.invalidate`. We deliberately do NOT subscribe to a realtime stream
  /// here; facet drift is fine.

  PlaceFacetsProvider call(String? countryCode) =>
      PlaceFacetsProvider._(argument: countryCode, from: this);

  @override
  String toString() => r'placeFacetsProvider';
}
