// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommentsController)
final commentsControllerProvider = CommentsControllerFamily._();

final class CommentsControllerProvider
    extends $AsyncNotifierProvider<CommentsController, List<Comment>> {
  CommentsControllerProvider._({
    required CommentsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'commentsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentsControllerHash();

  @override
  String toString() {
    return r'commentsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CommentsController create() => CommentsController();

  @override
  bool operator ==(Object other) {
    return other is CommentsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentsControllerHash() =>
    r'eed3c5d42d01a372d3a71897377f4682efc25da2';

final class CommentsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CommentsController,
          AsyncValue<List<Comment>>,
          List<Comment>,
          FutureOr<List<Comment>>,
          String
        > {
  CommentsControllerFamily._()
    : super(
        retry: null,
        name: r'commentsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CommentsControllerProvider call(String postId) =>
      CommentsControllerProvider._(argument: postId, from: this);

  @override
  String toString() => r'commentsControllerProvider';
}

abstract class _$CommentsController extends $AsyncNotifier<List<Comment>> {
  late final _$args = ref.$arg as String;
  String get postId => _$args;

  FutureOr<List<Comment>> build(String postId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Comment>>, List<Comment>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Comment>>, List<Comment>>,
              AsyncValue<List<Comment>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
