// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publisher_posts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keyset-paginated controller for publisher-specific posts (User, Team, Tournament).
/// Query membership lives here; normalized post state lives in [PostStore].

@ProviderFor(PublisherPostsController)
final publisherPostsControllerProvider = PublisherPostsControllerFamily._();

/// Keyset-paginated controller for publisher-specific posts (User, Team, Tournament).
/// Query membership lives here; normalized post state lives in [PostStore].
final class PublisherPostsControllerProvider
    extends $AsyncNotifierProvider<PublisherPostsController, PostQueryState> {
  /// Keyset-paginated controller for publisher-specific posts (User, Team, Tournament).
  /// Query membership lives here; normalized post state lives in [PostStore].
  PublisherPostsControllerProvider._({
    required PublisherPostsControllerFamily super.from,
    required ({PostPublisherType publisherType, String publisherId})
    super.argument,
  }) : super(
         retry: null,
         name: r'publisherPostsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$publisherPostsControllerHash();

  @override
  String toString() {
    return r'publisherPostsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PublisherPostsController create() => PublisherPostsController();

  @override
  bool operator ==(Object other) {
    return other is PublisherPostsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publisherPostsControllerHash() =>
    r'4baf5cac5240482f1e4186490871638ba8bfd72f';

/// Keyset-paginated controller for publisher-specific posts (User, Team, Tournament).
/// Query membership lives here; normalized post state lives in [PostStore].

final class PublisherPostsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PublisherPostsController,
          AsyncValue<PostQueryState>,
          PostQueryState,
          FutureOr<PostQueryState>,
          ({PostPublisherType publisherType, String publisherId})
        > {
  PublisherPostsControllerFamily._()
    : super(
        retry: null,
        name: r'publisherPostsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keyset-paginated controller for publisher-specific posts (User, Team, Tournament).
  /// Query membership lives here; normalized post state lives in [PostStore].

  PublisherPostsControllerProvider call({
    required PostPublisherType publisherType,
    required String publisherId,
  }) => PublisherPostsControllerProvider._(
    argument: (publisherType: publisherType, publisherId: publisherId),
    from: this,
  );

  @override
  String toString() => r'publisherPostsControllerProvider';
}

/// Keyset-paginated controller for publisher-specific posts (User, Team, Tournament).
/// Query membership lives here; normalized post state lives in [PostStore].

abstract class _$PublisherPostsController
    extends $AsyncNotifier<PostQueryState> {
  late final _$args =
      ref.$arg as ({PostPublisherType publisherType, String publisherId});
  PostPublisherType get publisherType => _$args.publisherType;
  String get publisherId => _$args.publisherId;

  FutureOr<PostQueryState> build({
    required PostPublisherType publisherType,
    required String publisherId,
  });
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
    element.handleCreate(
      ref,
      () => build(
        publisherType: _$args.publisherType,
        publisherId: _$args.publisherId,
      ),
    );
  }
}
