// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_publishing_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application-scoped session coordinator for post publishing, outbox durability,
/// and silent background reconciliation.
/// Keeps feed queries completely decoupled from outbox infrastructure.

@ProviderFor(PostPublishingCoordinator)
final postPublishingCoordinatorProvider = PostPublishingCoordinatorProvider._();

/// Application-scoped session coordinator for post publishing, outbox durability,
/// and silent background reconciliation.
/// Keeps feed queries completely decoupled from outbox infrastructure.
final class PostPublishingCoordinatorProvider
    extends $AsyncNotifierProvider<PostPublishingCoordinator, void> {
  /// Application-scoped session coordinator for post publishing, outbox durability,
  /// and silent background reconciliation.
  /// Keeps feed queries completely decoupled from outbox infrastructure.
  PostPublishingCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postPublishingCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postPublishingCoordinatorHash();

  @$internal
  @override
  PostPublishingCoordinator create() => PostPublishingCoordinator();
}

String _$postPublishingCoordinatorHash() =>
    r'b4174f476e05d67731fba7048783e28b610dc372';

/// Application-scoped session coordinator for post publishing, outbox durability,
/// and silent background reconciliation.
/// Keeps feed queries completely decoupled from outbox infrastructure.

abstract class _$PostPublishingCoordinator extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
