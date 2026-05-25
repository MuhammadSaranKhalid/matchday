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

String _$postsRepositoryHash() => r'0a7e6d1d1f53065625bde61590f37bbb8c474e09';

@ProviderFor(getFeedUseCase)
final getFeedUseCaseProvider = GetFeedUseCaseProvider._();

final class GetFeedUseCaseProvider
    extends $FunctionalProvider<GetFeed, GetFeed, GetFeed>
    with $Provider<GetFeed> {
  GetFeedUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getFeedUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getFeedUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetFeed> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetFeed create(Ref ref) {
    return getFeedUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetFeed value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetFeed>(value),
    );
  }
}

String _$getFeedUseCaseHash() => r'c9dc44da038bcd343dfab661bfbe07804f1a2934';

@ProviderFor(getAuthorPostsUseCase)
final getAuthorPostsUseCaseProvider = GetAuthorPostsUseCaseProvider._();

final class GetAuthorPostsUseCaseProvider
    extends $FunctionalProvider<GetAuthorPosts, GetAuthorPosts, GetAuthorPosts>
    with $Provider<GetAuthorPosts> {
  GetAuthorPostsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getAuthorPostsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getAuthorPostsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetAuthorPosts> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetAuthorPosts create(Ref ref) {
    return getAuthorPostsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetAuthorPosts value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetAuthorPosts>(value),
    );
  }
}

String _$getAuthorPostsUseCaseHash() =>
    r'2ec71c29d980ab4deb4f89f26bc1f479191d0fe5';

@ProviderFor(createPostUseCase)
final createPostUseCaseProvider = CreatePostUseCaseProvider._();

final class CreatePostUseCaseProvider
    extends $FunctionalProvider<CreatePost, CreatePost, CreatePost>
    with $Provider<CreatePost> {
  CreatePostUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createPostUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createPostUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreatePost> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreatePost create(Ref ref) {
    return createPostUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreatePost value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreatePost>(value),
    );
  }
}

String _$createPostUseCaseHash() => r'addf52a8fc1c4b88d3785e250477af273eabc362';

@ProviderFor(deletePostUseCase)
final deletePostUseCaseProvider = DeletePostUseCaseProvider._();

final class DeletePostUseCaseProvider
    extends $FunctionalProvider<DeletePost, DeletePost, DeletePost>
    with $Provider<DeletePost> {
  DeletePostUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletePostUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletePostUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeletePost> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeletePost create(Ref ref) {
    return deletePostUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeletePost value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeletePost>(value),
    );
  }
}

String _$deletePostUseCaseHash() => r'461592403a88c0b9f53b34915d9573f41b51e3a6';

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

String _$authorPostsHash() => r'face2cf3a155d067635031d410e5c33d9edcd20a';

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
