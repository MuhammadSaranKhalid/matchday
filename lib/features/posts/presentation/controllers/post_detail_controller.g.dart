// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single post controller by [postId] for canonical /posts/:postId screen.
/// Implements stale-while-revalidate: returns cached Post from PostStore if present,
/// and revalidates in the background. Explicit refresh() awaits the network response.

@ProviderFor(PostDetailController)
final postDetailControllerProvider = PostDetailControllerFamily._();

/// Single post controller by [postId] for canonical /posts/:postId screen.
/// Implements stale-while-revalidate: returns cached Post from PostStore if present,
/// and revalidates in the background. Explicit refresh() awaits the network response.
final class PostDetailControllerProvider
    extends $AsyncNotifierProvider<PostDetailController, Post> {
  /// Single post controller by [postId] for canonical /posts/:postId screen.
  /// Implements stale-while-revalidate: returns cached Post from PostStore if present,
  /// and revalidates in the background. Explicit refresh() awaits the network response.
  PostDetailControllerProvider._({
    required PostDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'postDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postDetailControllerHash();

  @override
  String toString() {
    return r'postDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PostDetailController create() => PostDetailController();

  @override
  bool operator ==(Object other) {
    return other is PostDetailControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postDetailControllerHash() =>
    r'47b9423c3e559e087a50e4be9efabc44d2a632f5';

/// Single post controller by [postId] for canonical /posts/:postId screen.
/// Implements stale-while-revalidate: returns cached Post from PostStore if present,
/// and revalidates in the background. Explicit refresh() awaits the network response.

final class PostDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PostDetailController,
          AsyncValue<Post>,
          Post,
          FutureOr<Post>,
          String
        > {
  PostDetailControllerFamily._()
    : super(
        retry: null,
        name: r'postDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Single post controller by [postId] for canonical /posts/:postId screen.
  /// Implements stale-while-revalidate: returns cached Post from PostStore if present,
  /// and revalidates in the background. Explicit refresh() awaits the network response.

  PostDetailControllerProvider call(String postId) =>
      PostDetailControllerProvider._(argument: postId, from: this);

  @override
  String toString() => r'postDetailControllerProvider';
}

/// Single post controller by [postId] for canonical /posts/:postId screen.
/// Implements stale-while-revalidate: returns cached Post from PostStore if present,
/// and revalidates in the background. Explicit refresh() awaits the network response.

abstract class _$PostDetailController extends $AsyncNotifier<Post> {
  late final _$args = ref.$arg as String;
  String get postId => _$args;

  FutureOr<Post> build(String postId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Post>, Post>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Post>, Post>,
              AsyncValue<Post>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
