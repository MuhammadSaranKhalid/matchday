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

String _$myMatchesViewHash() => r'd1635c0156d28b0eae4a71fb0841befbaaabe774';

/// The one live match the side panel promotes into its hero card, with the
/// current innings numbers attached. Null when nothing of the user's is live.
///
/// Autodispose: the drawer only builds while it is open (Flutter's
/// `DrawerController` short-circuits its child when dismissed), so this
/// resolves on open and is torn down on close.
///
/// Scope note (design open question 2): when more than one of the user's
/// matches is live the panel shows a single card rather than growing — the
/// rest stay counted on the My Matches row.

@ProviderFor(livePanelMatch)
final livePanelMatchProvider = LivePanelMatchProvider._();

/// The one live match the side panel promotes into its hero card, with the
/// current innings numbers attached. Null when nothing of the user's is live.
///
/// Autodispose: the drawer only builds while it is open (Flutter's
/// `DrawerController` short-circuits its child when dismissed), so this
/// resolves on open and is torn down on close.
///
/// Scope note (design open question 2): when more than one of the user's
/// matches is live the panel shows a single card rather than growing — the
/// rest stay counted on the My Matches row.

final class LivePanelMatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<LivePanelMatch?>,
          LivePanelMatch?,
          FutureOr<LivePanelMatch?>
        >
    with $FutureModifier<LivePanelMatch?>, $FutureProvider<LivePanelMatch?> {
  /// The one live match the side panel promotes into its hero card, with the
  /// current innings numbers attached. Null when nothing of the user's is live.
  ///
  /// Autodispose: the drawer only builds while it is open (Flutter's
  /// `DrawerController` short-circuits its child when dismissed), so this
  /// resolves on open and is torn down on close.
  ///
  /// Scope note (design open question 2): when more than one of the user's
  /// matches is live the panel shows a single card rather than growing — the
  /// rest stay counted on the My Matches row.
  LivePanelMatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'livePanelMatchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$livePanelMatchHash();

  @$internal
  @override
  $FutureProviderElement<LivePanelMatch?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LivePanelMatch?> create(Ref ref) {
    return livePanelMatch(ref);
  }
}

String _$livePanelMatchHash() => r'2e50b486046b380ec05540bfcbd2298ee1a4708a';
