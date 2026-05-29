// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_matches_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$myMatchesViewHash() => r'6a1f8d4776f0d6305c57ba931c6641de268621e6';
