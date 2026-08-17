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

String _$myMatchesViewHash() => r'bdca5d2ff2d28b58b0d9cd5a3b7e48ddfbfcc8f6';
