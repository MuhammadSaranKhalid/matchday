// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(postsRepository)
final postsRepositoryProvider = PostsRepositoryProvider._();

final class PostsRepositoryProvider
    extends
        $FunctionalProvider<PostsRepository, PostsRepository, PostsRepository>
    with $Provider<PostsRepository> {
  PostsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PostsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PostsRepository create(Ref ref) {
    return postsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostsRepository>(value),
    );
  }
}

String _$postsRepositoryHash() => r'10ca989c9211262ea2b49d1e96df46210a2e7d16';

/// Emits the local pending uploads/posts created on this device.

@ProviderFor(pendingPosts)
final pendingPostsProvider = PendingPostsProvider._();

/// Emits the local pending uploads/posts created on this device.

final class PendingPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PendingPost>>,
          List<PendingPost>,
          Stream<List<PendingPost>>
        >
    with
        $FutureModifier<List<PendingPost>>,
        $StreamProvider<List<PendingPost>> {
  /// Emits the local pending uploads/posts created on this device.
  PendingPostsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingPostsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingPostsHash();

  @$internal
  @override
  $StreamProviderElement<List<PendingPost>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PendingPost>> create(Ref ref) {
    return pendingPosts(ref);
  }
}

String _$pendingPostsHash() => r'b4f9ca5865a398ca2ffecdc5592aeaaabc9983ba';

/// Posts authored by [authorId] (Profile tab / spectator). Throws a
/// [FailureWrapper] on error so the UI renders it via `AsyncError`.

@ProviderFor(authorPosts)
final authorPostsProvider = AuthorPostsFamily._();

/// Posts authored by [authorId] (Profile tab / spectator). Throws a
/// [FailureWrapper] on error so the UI renders it via `AsyncError`.

final class AuthorPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Post>>,
          List<Post>,
          FutureOr<List<Post>>
        >
    with $FutureModifier<List<Post>>, $FutureProvider<List<Post>> {
  /// Posts authored by [authorId] (Profile tab / spectator). Throws a
  /// [FailureWrapper] on error so the UI renders it via `AsyncError`.
  AuthorPostsProvider._({
    required AuthorPostsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'authorPostsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authorPostsHash();

  @override
  String toString() {
    return r'authorPostsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Post>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Post>> create(Ref ref) {
    final argument = this.argument as String;
    return authorPosts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AuthorPostsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authorPostsHash() => r'c56a01920231a2c4f5cdb539b41442a3ccb7d402';

/// Posts authored by [authorId] (Profile tab / spectator). Throws a
/// [FailureWrapper] on error so the UI renders it via `AsyncError`.

final class AuthorPostsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Post>>, String> {
  AuthorPostsFamily._()
    : super(
        retry: null,
        name: r'authorPostsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Posts authored by [authorId] (Profile tab / spectator). Throws a
  /// [FailureWrapper] on error so the UI renders it via `AsyncError`.

  AuthorPostsProvider call(String authorId) =>
      AuthorPostsProvider._(argument: authorId, from: this);

  @override
  String toString() => r'authorPostsProvider';
}

/// Posts authored by or linked to [teamId] (Team Profile Posts tab).

@ProviderFor(teamPosts)
final teamPostsProvider = TeamPostsFamily._();

/// Posts authored by or linked to [teamId] (Team Profile Posts tab).

final class TeamPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Post>>,
          List<Post>,
          FutureOr<List<Post>>
        >
    with $FutureModifier<List<Post>>, $FutureProvider<List<Post>> {
  /// Posts authored by or linked to [teamId] (Team Profile Posts tab).
  TeamPostsProvider._({
    required TeamPostsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamPostsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamPostsHash();

  @override
  String toString() {
    return r'teamPostsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Post>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Post>> create(Ref ref) {
    final argument = this.argument as String;
    return teamPosts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamPostsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamPostsHash() => r'5b476ca6b4edfeb0fa3f55256f835cc23bb18ef0';

/// Posts authored by or linked to [teamId] (Team Profile Posts tab).

final class TeamPostsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Post>>, String> {
  TeamPostsFamily._()
    : super(
        retry: null,
        name: r'teamPostsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Posts authored by or linked to [teamId] (Team Profile Posts tab).

  TeamPostsProvider call(String teamId) =>
      TeamPostsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamPostsProvider';
}

/// The currently selected feed filter ('all', 'people', 'teams', 'tournaments', 'matches').

@ProviderFor(FeedFilter)
final feedFilterProvider = FeedFilterProvider._();

/// The currently selected feed filter ('all', 'people', 'teams', 'tournaments', 'matches').
final class FeedFilterProvider extends $NotifierProvider<FeedFilter, String> {
  /// The currently selected feed filter ('all', 'people', 'teams', 'tournaments', 'matches').
  FeedFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedFilterHash();

  @$internal
  @override
  FeedFilter create() => FeedFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$feedFilterHash() => r'aa7268201bcec9160faeabc4378b46021b896dca';

/// The currently selected feed filter ('all', 'people', 'teams', 'tournaments', 'matches').

abstract class _$FeedFilter extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Single post by [postId] for canonical /posts/:postId screen.

@ProviderFor(postDetail)
final postDetailProvider = PostDetailFamily._();

/// Single post by [postId] for canonical /posts/:postId screen.

final class PostDetailProvider
    extends $FunctionalProvider<AsyncValue<Post>, Post, FutureOr<Post>>
    with $FutureModifier<Post>, $FutureProvider<Post> {
  /// Single post by [postId] for canonical /posts/:postId screen.
  PostDetailProvider._({
    required PostDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'postDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postDetailHash();

  @override
  String toString() {
    return r'postDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Post> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Post> create(Ref ref) {
    final argument = this.argument as String;
    return postDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PostDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postDetailHash() => r'103816d91249546ca86be4d7520a42806a18dc7f';

/// Single post by [postId] for canonical /posts/:postId screen.

final class PostDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Post>, String> {
  PostDetailFamily._()
    : super(
        retry: null,
        name: r'postDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Single post by [postId] for canonical /posts/:postId screen.

  PostDetailProvider call(String postId) =>
      PostDetailProvider._(argument: postId, from: this);

  @override
  String toString() => r'postDetailProvider';
}

/// Bookmarked / saved posts.

@ProviderFor(savedPosts)
final savedPostsProvider = SavedPostsProvider._();

/// Bookmarked / saved posts.

final class SavedPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Post>>,
          List<Post>,
          FutureOr<List<Post>>
        >
    with $FutureModifier<List<Post>>, $FutureProvider<List<Post>> {
  /// Bookmarked / saved posts.
  SavedPostsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedPostsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedPostsHash();

  @$internal
  @override
  $FutureProviderElement<List<Post>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Post>> create(Ref ref) {
    return savedPosts(ref);
  }
}

String _$savedPostsHash() => r'0def375cb6e8e9308b9cd79643b9f0f1bedb00f6';
