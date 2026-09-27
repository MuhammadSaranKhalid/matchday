// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'48013226b5eb3d365c00f78e2e7e5e460ce1bdcb';

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
    r'a9b80650d36ee348e6c87463afb50defda469007';

/// Comments Repository Provider.

@ProviderFor(commentsRepository)
final commentsRepositoryProvider = CommentsRepositoryProvider._();

/// Comments Repository Provider.

final class CommentsRepositoryProvider
    extends
        $FunctionalProvider<
          CommentsRepository,
          CommentsRepository,
          CommentsRepository
        >
    with $Provider<CommentsRepository> {
  /// Comments Repository Provider.
  CommentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commentsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commentsRepositoryHash();

  @$internal
  @override
  $ProviderElement<CommentsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CommentsRepository create(Ref ref) {
    return commentsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommentsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommentsRepository>(value),
    );
  }
}

String _$commentsRepositoryHash() =>
    r'6034bd4bbc35a6e8eb43d4d0cf631749ca14d189';

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

/// Returns a failed outbox post if matching [postId] is currently in terminal failure.

@ProviderFor(failedPendingPost)
final failedPendingPostProvider = FailedPendingPostFamily._();

/// Returns a failed outbox post if matching [postId] is currently in terminal failure.

final class FailedPendingPostProvider
    extends $FunctionalProvider<PendingPost?, PendingPost?, PendingPost?>
    with $Provider<PendingPost?> {
  /// Returns a failed outbox post if matching [postId] is currently in terminal failure.
  FailedPendingPostProvider._({
    required FailedPendingPostFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'failedPendingPostProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$failedPendingPostHash();

  @override
  String toString() {
    return r'failedPendingPostProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<PendingPost?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PendingPost? create(Ref ref) {
    final argument = this.argument as String;
    return failedPendingPost(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingPost? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingPost?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FailedPendingPostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$failedPendingPostHash() => r'68ae773f426bcbb6b4a852d7177eda187138af52';

/// Returns a failed outbox post if matching [postId] is currently in terminal failure.

final class FailedPendingPostFamily extends $Family
    with $FunctionalFamilyOverride<PendingPost?, String> {
  FailedPendingPostFamily._()
    : super(
        retry: null,
        name: r'failedPendingPostProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns a failed outbox post if matching [postId] is currently in terminal failure.

  FailedPendingPostProvider call(String postId) =>
      FailedPendingPostProvider._(argument: postId, from: this);

  @override
  String toString() => r'failedPendingPostProvider';
}

/// Startup coordinator that automatically recovers in-flight pending posts.

@ProviderFor(publishRecoveryCoordinator)
final publishRecoveryCoordinatorProvider =
    PublishRecoveryCoordinatorProvider._();

/// Startup coordinator that automatically recovers in-flight pending posts.

final class PublishRecoveryCoordinatorProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Startup coordinator that automatically recovers in-flight pending posts.
  PublishRecoveryCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publishRecoveryCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publishRecoveryCoordinatorHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return publishRecoveryCoordinator(ref);
  }
}

String _$publishRecoveryCoordinatorHash() =>
    r'05afcf8b800c125d4a46f89564a5590d98313451';

/// Posts authored by [authorId] (Profile tab / spectator).
/// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].

@ProviderFor(authorPosts)
final authorPostsProvider = AuthorPostsFamily._();

/// Posts authored by [authorId] (Profile tab / spectator).
/// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].

final class AuthorPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Post>>,
          List<Post>,
          FutureOr<List<Post>>
        >
    with $FutureModifier<List<Post>>, $FutureProvider<List<Post>> {
  /// Posts authored by [authorId] (Profile tab / spectator).
  /// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].
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

String _$authorPostsHash() => r'7ef411679a9cf65b1f1825042d5947e9fa9a8f4a';

/// Posts authored by [authorId] (Profile tab / spectator).
/// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].

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
  /// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].

  AuthorPostsProvider call(String authorId) =>
      AuthorPostsProvider._(argument: authorId, from: this);

  @override
  String toString() => r'authorPostsProvider';
}

/// Posts authored by or linked to [teamId] (Team Profile Posts tab).
/// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].

@ProviderFor(teamPosts)
final teamPostsProvider = TeamPostsFamily._();

/// Posts authored by or linked to [teamId] (Team Profile Posts tab).
/// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].

final class TeamPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Post>>,
          List<Post>,
          FutureOr<List<Post>>
        >
    with $FutureModifier<List<Post>>, $FutureProvider<List<Post>> {
  /// Posts authored by or linked to [teamId] (Team Profile Posts tab).
  /// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].
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

String _$teamPostsHash() => r'7dbf85c9b5e3adb2cc3641bf9b34600a6aa3333e';

/// Posts authored by or linked to [teamId] (Team Profile Posts tab).
/// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].

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
  /// Delegated to [publisherPostsControllerProvider] and returns live reactive projections from [PostStore].

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
