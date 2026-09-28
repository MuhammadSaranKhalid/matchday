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
