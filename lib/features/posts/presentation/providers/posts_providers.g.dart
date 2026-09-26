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

/// CQRS Read Repository Provider.

@ProviderFor(postReadRepository)
final postReadRepositoryProvider = PostReadRepositoryProvider._();

/// CQRS Read Repository Provider.

final class PostReadRepositoryProvider
    extends
        $FunctionalProvider<
          PostReadRepository,
          PostReadRepository,
          PostReadRepository
        >
    with $Provider<PostReadRepository> {
  /// CQRS Read Repository Provider.
  PostReadRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postReadRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postReadRepositoryHash();

  @$internal
  @override
  $ProviderElement<PostReadRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PostReadRepository create(Ref ref) {
    return postReadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostReadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostReadRepository>(value),
    );
  }
}

String _$postReadRepositoryHash() =>
    r'ac983f3ff3979efaf3c4c65880138e3bb2aac359';

/// CQRS Command Repository Provider.

@ProviderFor(postCommandRepository)
final postCommandRepositoryProvider = PostCommandRepositoryProvider._();

/// CQRS Command Repository Provider.

final class PostCommandRepositoryProvider
    extends
        $FunctionalProvider<
          PostCommandRepository,
          PostCommandRepository,
          PostCommandRepository
        >
    with $Provider<PostCommandRepository> {
  /// CQRS Command Repository Provider.
  PostCommandRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postCommandRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postCommandRepositoryHash();

  @$internal
  @override
  $ProviderElement<PostCommandRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PostCommandRepository create(Ref ref) {
    return postCommandRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostCommandRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostCommandRepository>(value),
    );
  }
}

String _$postCommandRepositoryHash() =>
    r'2825dce7ba33efd321b69df3bb4edab809143844';

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

String _$pendingPostsHash() => r'40e4a10d6c85fa768b8b524e667c7fc87b53f0cb';

/// Posts authored by [authorId] (Profile tab / spectator).
/// Populates the L1 PostStore and returns the canonical entities.

@ProviderFor(authorPosts)
final authorPostsProvider = AuthorPostsFamily._();

/// Posts authored by [authorId] (Profile tab / spectator).
/// Populates the L1 PostStore and returns the canonical entities.

final class AuthorPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Post>>,
          List<Post>,
          FutureOr<List<Post>>
        >
    with $FutureModifier<List<Post>>, $FutureProvider<List<Post>> {
  /// Posts authored by [authorId] (Profile tab / spectator).
  /// Populates the L1 PostStore and returns the canonical entities.
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

String _$authorPostsHash() => r'65fd2aecf7f237c612cb3f1388817e43efbddcfd';

/// Posts authored by [authorId] (Profile tab / spectator).
/// Populates the L1 PostStore and returns the canonical entities.

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

  /// Posts authored by [authorId] (Profile tab / spectator).
  /// Populates the L1 PostStore and returns the canonical entities.

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

String _$teamPostsHash() => r'0bc2e020c319450dc7da94e5896336e1fa667f48';

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
/// Checks L1 PostStore first, fetches from server on cache miss.

@ProviderFor(postDetail)
final postDetailProvider = PostDetailFamily._();

/// Single post by [postId] for canonical /posts/:postId screen.
/// Checks L1 PostStore first, fetches from server on cache miss.

final class PostDetailProvider
    extends $FunctionalProvider<AsyncValue<Post>, Post, FutureOr<Post>>
    with $FutureModifier<Post>, $FutureProvider<Post> {
  /// Single post by [postId] for canonical /posts/:postId screen.
  /// Checks L1 PostStore first, fetches from server on cache miss.
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

String _$postDetailHash() => r'ff8b1abdcb2c2880e24124bc3b0ff384adc77dcc';

/// Single post by [postId] for canonical /posts/:postId screen.
/// Checks L1 PostStore first, fetches from server on cache miss.

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
  /// Checks L1 PostStore first, fetches from server on cache miss.

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

String _$savedPostsHash() => r'08f0ebfbd4f4443b77e06ceb8317db5bb83975a4';
