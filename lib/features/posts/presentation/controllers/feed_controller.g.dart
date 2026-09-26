// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Home feed — newest active posts with keyset pagination + pull-to-refresh.

@ProviderFor(FeedController)
final feedControllerProvider = FeedControllerProvider._();

/// The Home feed — newest active posts with keyset pagination + pull-to-refresh.
final class FeedControllerProvider
    extends $AsyncNotifierProvider<FeedController, List<Post>> {
  /// The Home feed — newest active posts with keyset pagination + pull-to-refresh.
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

String _$feedControllerHash() => r'c067ef925f8901234cf371e09f7bc26789cf84c1';

/// The Home feed — newest active posts with keyset pagination + pull-to-refresh.

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
