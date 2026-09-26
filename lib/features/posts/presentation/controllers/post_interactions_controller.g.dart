// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_interactions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single unified controller for post interactions (likes, bookmarks, comments count reconciliation).
///
/// Features:
/// 1. Optimistic updates across all surfaces observing [postStoreProvider].
/// 2. In-flight race prevention (serializes rapid taps per post).
/// 3. Reconciles canonical server counts using [PostLikeResult].

@ProviderFor(PostInteractionsController)
final postInteractionsControllerProvider =
    PostInteractionsControllerProvider._();

/// Single unified controller for post interactions (likes, bookmarks, comments count reconciliation).
///
/// Features:
/// 1. Optimistic updates across all surfaces observing [postStoreProvider].
/// 2. In-flight race prevention (serializes rapid taps per post).
/// 3. Reconciles canonical server counts using [PostLikeResult].
final class PostInteractionsControllerProvider
    extends $NotifierProvider<PostInteractionsController, void> {
  /// Single unified controller for post interactions (likes, bookmarks, comments count reconciliation).
  ///
  /// Features:
  /// 1. Optimistic updates across all surfaces observing [postStoreProvider].
  /// 2. In-flight race prevention (serializes rapid taps per post).
  /// 3. Reconciles canonical server counts using [PostLikeResult].
  PostInteractionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postInteractionsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postInteractionsControllerHash();

  @$internal
  @override
  PostInteractionsController create() => PostInteractionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$postInteractionsControllerHash() =>
    r'16f570ab132bffab6d4dea434c91a92e61786d41';

/// Single unified controller for post interactions (likes, bookmarks, comments count reconciliation).
///
/// Features:
/// 1. Optimistic updates across all surfaces observing [postStoreProvider].
/// 2. In-flight race prevention (serializes rapid taps per post).
/// 3. Reconciles canonical server counts using [PostLikeResult].

abstract class _$PostInteractionsController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
