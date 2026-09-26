// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_posts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Normalized controller for the Saved / Bookmarked Posts query.
/// Owns membership list of [PostId]s and keyset cursors.
/// Post entities live in [PostStore].

@ProviderFor(SavedPostsController)
final savedPostsControllerProvider = SavedPostsControllerProvider._();

/// Normalized controller for the Saved / Bookmarked Posts query.
/// Owns membership list of [PostId]s and keyset cursors.
/// Post entities live in [PostStore].
final class SavedPostsControllerProvider
    extends $AsyncNotifierProvider<SavedPostsController, PostQueryState> {
  /// Normalized controller for the Saved / Bookmarked Posts query.
  /// Owns membership list of [PostId]s and keyset cursors.
  /// Post entities live in [PostStore].
  SavedPostsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedPostsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedPostsControllerHash();

  @$internal
  @override
  SavedPostsController create() => SavedPostsController();
}

String _$savedPostsControllerHash() =>
    r'ab2b35b355d12c72f0bcb1b251eb48642f95b042';

/// Normalized controller for the Saved / Bookmarked Posts query.
/// Owns membership list of [PostId]s and keyset cursors.
/// Post entities live in [PostStore].

abstract class _$SavedPostsController extends $AsyncNotifier<PostQueryState> {
  FutureOr<PostQueryState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PostQueryState>, PostQueryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PostQueryState>, PostQueryState>,
              AsyncValue<PostQueryState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
