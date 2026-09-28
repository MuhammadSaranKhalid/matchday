// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placeFacets)
final placeFacetsProvider = PlaceFacetsFamily._();

final class PlaceFacetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaceFacet>>,
          List<PlaceFacet>,
          FutureOr<List<PlaceFacet>>
        >
    with $FutureModifier<List<PlaceFacet>>, $FutureProvider<List<PlaceFacet>> {
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

  PlaceFacetsProvider call(String? countryCode) =>
      PlaceFacetsProvider._(argument: countryCode, from: this);

  @override
  String toString() => r'placeFacetsProvider';
}
