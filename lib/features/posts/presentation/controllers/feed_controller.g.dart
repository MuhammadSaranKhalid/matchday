// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Home feed — newest active posts with keyset pagination + pull-to-refresh.
/// Integrates with the L1 normalized [PostStore] to keep post interactions synchronized across all screens.

@ProviderFor(FeedController)
final feedControllerProvider = FeedControllerProvider._();

/// The Home feed — newest active posts with keyset pagination + pull-to-refresh.
/// Integrates with the L1 normalized [PostStore] to keep post interactions synchronized across all screens.
final class FeedControllerProvider
    extends $AsyncNotifierProvider<FeedController, List<Post>> {
  /// The Home feed — newest active posts with keyset pagination + pull-to-refresh.
  /// Integrates with the L1 normalized [PostStore] to keep post interactions synchronized across all screens.
  FeedControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedControllerHash();

  @$internal
  @override
  FeedController create() => FeedController();
}

String _$feedControllerHash() => r'137a79bc5417aceeb8f4ac888ed7b0c6cd2815b2';

/// The Home feed — newest active posts with keyset pagination + pull-to-refresh.
/// Integrates with the L1 normalized [PostStore] to keep post interactions synchronized across all screens.

abstract class _$FeedController extends $AsyncNotifier<List<Post>> {
  FutureOr<List<Post>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Post>>, List<Post>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Post>>, List<Post>>,
              AsyncValue<List<Post>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
