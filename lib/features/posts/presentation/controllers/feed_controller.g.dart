// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Home feed — normalized post ID membership ordering with keyset pagination + pull-to-refresh.
/// Post entities live in [PostStore] to ensure unified synchronization across all views.

@ProviderFor(FeedController)
final feedControllerProvider = FeedControllerProvider._();

/// The Home feed — normalized post ID membership ordering with keyset pagination + pull-to-refresh.
/// Post entities live in [PostStore] to ensure unified synchronization across all views.
final class FeedControllerProvider
    extends $AsyncNotifierProvider<FeedController, PostQueryState> {
  /// The Home feed — normalized post ID membership ordering with keyset pagination + pull-to-refresh.
  /// Post entities live in [PostStore] to ensure unified synchronization across all views.
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

String _$feedControllerHash() => r'f28711d9948ef6114868ecf3a5e13924adb67c24';

/// The Home feed — normalized post ID membership ordering with keyset pagination + pull-to-refresh.
/// Post entities live in [PostStore] to ensure unified synchronization across all views.

abstract class _$FeedController extends $AsyncNotifier<PostQueryState> {
  FutureOr<PostQueryState> build();
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
    element.handleCreate(ref, build);
  }
}
