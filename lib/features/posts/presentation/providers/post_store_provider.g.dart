// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// L1 Session-level normalized Post cache: `Map<PostId, Post>`.
/// All queries (Home Feed, Profile Posts, Saved Posts, Post Detail) point into this store.
/// When interaction state (isLiked, isBookmarked, counts) mutates, every screen viewing the post updates simultaneously.

@ProviderFor(PostStore)
final postStoreProvider = PostStoreProvider._();

/// L1 Session-level normalized Post cache: `Map<PostId, Post>`.
/// All queries (Home Feed, Profile Posts, Saved Posts, Post Detail) point into this store.
/// When interaction state (isLiked, isBookmarked, counts) mutates, every screen viewing the post updates simultaneously.
final class PostStoreProvider
    extends $NotifierProvider<PostStore, Map<PostId, Post>> {
  /// L1 Session-level normalized Post cache: `Map<PostId, Post>`.
  /// All queries (Home Feed, Profile Posts, Saved Posts, Post Detail) point into this store.
  /// When interaction state (isLiked, isBookmarked, counts) mutates, every screen viewing the post updates simultaneously.
  PostStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postStoreHash();

  @$internal
  @override
  PostStore create() => PostStore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<PostId, Post> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<PostId, Post>>(value),
    );
  }
}

String _$postStoreHash() => r'f4da1e6873ed37e357375bed483e39b36aaf836b';

/// L1 Session-level normalized Post cache: `Map<PostId, Post>`.
/// All queries (Home Feed, Profile Posts, Saved Posts, Post Detail) point into this store.
/// When interaction state (isLiked, isBookmarked, counts) mutates, every screen viewing the post updates simultaneously.

abstract class _$PostStore extends $Notifier<Map<PostId, Post>> {
  Map<PostId, Post> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<PostId, Post>, Map<PostId, Post>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<PostId, Post>, Map<PostId, Post>>,
              Map<PostId, Post>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Selector provider to watch an individual Post reactively from the normalized store.

@ProviderFor(postFromStore)
final postFromStoreProvider = PostFromStoreFamily._();

/// Selector provider to watch an individual Post reactively from the normalized store.

final class PostFromStoreProvider
    extends $FunctionalProvider<Post?, Post?, Post?>
    with $Provider<Post?> {
  /// Selector provider to watch an individual Post reactively from the normalized store.
  PostFromStoreProvider._({
    required PostFromStoreFamily super.from,
    required PostId super.argument,
  }) : super(
         retry: null,
         name: r'postFromStoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postFromStoreHash();

  @override
  String toString() {
    return r'postFromStoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Post?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Post? create(Ref ref) {
    final argument = this.argument as PostId;
    return postFromStore(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Post? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Post?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostFromStoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postFromStoreHash() => r'bf33dbcab532748dbec38aaee2e48e11fcc0e9aa';

/// Selector provider to watch an individual Post reactively from the normalized store.

final class PostFromStoreFamily extends $Family
    with $FunctionalFamilyOverride<Post?, PostId> {
  PostFromStoreFamily._()
    : super(
        retry: null,
        name: r'postFromStoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Selector provider to watch an individual Post reactively from the normalized store.

  PostFromStoreProvider call(PostId id) =>
      PostFromStoreProvider._(argument: id, from: this);

  @override
  String toString() => r'postFromStoreProvider';
}
