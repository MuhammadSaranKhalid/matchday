// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_interactions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single unified controller for post interactions (likes, bookmarks, comments count reconciliation, deletion).
///
/// Features:
/// 1. Optimistic updates across all surfaces observing [postStoreProvider].
/// 2. Intent coalescing: rapid taps (Like -> Unlike -> Like) queue the latest desired intent
///    so the final server state matches user intent without dropping actions or corrupting counts.
/// 3. Reconciles canonical server counts using [PostLikeResult].
/// 4. Synchronizes query membership: unbookmark immediately evicts the post ID from [savedPostsControllerProvider].

@ProviderFor(PostInteractionsController)
final postInteractionsControllerProvider =
    PostInteractionsControllerProvider._();

/// Single unified controller for post interactions (likes, bookmarks, comments count reconciliation, deletion).
///
/// Features:
/// 1. Optimistic updates across all surfaces observing [postStoreProvider].
/// 2. Intent coalescing: rapid taps (Like -> Unlike -> Like) queue the latest desired intent
///    so the final server state matches user intent without dropping actions or corrupting counts.
/// 3. Reconciles canonical server counts using [PostLikeResult].
/// 4. Synchronizes query membership: unbookmark immediately evicts the post ID from [savedPostsControllerProvider].
final class PostInteractionsControllerProvider
    extends $NotifierProvider<PostInteractionsController, void> {
  /// Single unified controller for post interactions (likes, bookmarks, comments count reconciliation, deletion).
  ///
  /// Features:
  /// 1. Optimistic updates across all surfaces observing [postStoreProvider].
  /// 2. Intent coalescing: rapid taps (Like -> Unlike -> Like) queue the latest desired intent
  ///    so the final server state matches user intent without dropping actions or corrupting counts.
  /// 3. Reconciles canonical server counts using [PostLikeResult].
  /// 4. Synchronizes query membership: unbookmark immediately evicts the post ID from [savedPostsControllerProvider].
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
    r'41f25d12cd66fd880f5d317618a7e1c7c4e15bc3';

/// Single unified controller for post interactions (likes, bookmarks, comments count reconciliation, deletion).
///
/// Features:
/// 1. Optimistic updates across all surfaces observing [postStoreProvider].
/// 2. Intent coalescing: rapid taps (Like -> Unlike -> Like) queue the latest desired intent
///    so the final server state matches user intent without dropping actions or corrupting counts.
/// 3. Reconciles canonical server counts using [PostLikeResult].
/// 4. Synchronizes query membership: unbookmark immediately evicts the post ID from [savedPostsControllerProvider].

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
