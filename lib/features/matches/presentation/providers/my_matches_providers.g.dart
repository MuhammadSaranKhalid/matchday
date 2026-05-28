// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_matches_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(listInningsForMatchesUseCase)
final listInningsForMatchesUseCaseProvider =
    ListInningsForMatchesUseCaseProvider._();

final class ListInningsForMatchesUseCaseProvider
    extends
        $FunctionalProvider<
          ListInningsForMatches,
          ListInningsForMatches,
          ListInningsForMatches
        >
    with $Provider<ListInningsForMatches> {
  ListInningsForMatchesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listInningsForMatchesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listInningsForMatchesUseCaseHash();

  @$internal
  @override
  $ProviderElement<ListInningsForMatches> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ListInningsForMatches create(Ref ref) {
    return listInningsForMatchesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListInningsForMatches value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListInningsForMatches>(value),
    );
  }
}

String _$listInningsForMatchesUseCaseHash() =>
    r'59e1640b5650d5fd7bf7d4847eea74735ef766b4';

/// Composes matches + teams + currentUser + innings into a pre-rendered
/// [MyMatchesView] for the Pavilion screen. Online-only one-shot fetch;
/// pull-to-refresh invalidates self.

@ProviderFor(myMatchesView)
final myMatchesViewProvider = MyMatchesViewProvider._();

/// Composes matches + teams + currentUser + innings into a pre-rendered
/// [MyMatchesView] for the Pavilion screen. Online-only one-shot fetch;
/// pull-to-refresh invalidates self.

final class MyMatchesViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<MyMatchesView>,
          MyMatchesView,
          FutureOr<MyMatchesView>
        >
    with $FutureModifier<MyMatchesView>, $FutureProvider<MyMatchesView> {
  /// Composes matches + teams + currentUser + innings into a pre-rendered
  /// [MyMatchesView] for the Pavilion screen. Online-only one-shot fetch;
  /// pull-to-refresh invalidates self.
  MyMatchesViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myMatchesViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myMatchesViewHash();

  @$internal
  @override
  $FutureProviderElement<MyMatchesView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MyMatchesView> create(Ref ref) {
    return myMatchesView(ref);
  }
}

String _$myMatchesViewHash() => r'ee301178babd6699dbbf9c07d606fa7d94fa2dee';
