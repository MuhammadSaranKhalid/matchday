import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/posts_datasource_providers.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../providers/posts_providers.dart';
import 'feed_controller.dart';

part 'composer_controller.g.dart';

class ComposerState {
  const ComposerState({
    this.photos = const [],
    this.busy = false,
    this.error,
  });

  final List<ProcessedPhoto> photos;
  final bool busy;
  final Failure? error;

  static const maxPhotos = 4;
  bool get canAddPhoto => photos.length < maxPhotos;

  ComposerState copyWith({
    List<ProcessedPhoto>? photos,
    bool? busy,
    Failure? error,
  }) =>
      ComposerState(
        photos: photos ?? this.photos,
        busy: busy ?? this.busy,
        error: error,
      );
}

/// Composer draft state: staged (cropped+resized) photos + submit lifecycle.
/// The text is owned by the screen's TextEditingController and passed to submit.
@riverpod
class ComposerController extends _$ComposerController {
  @override
  ComposerState build() => const ComposerState();

  Future<void> addPhoto() async {
    if (!state.canAddPhoto || state.busy) return;
    final photo = await ref.read(photoPickerProvider).pickOne();
    if (photo == null) return;
    state = state.copyWith(photos: [...state.photos, photo]);
  }

  void removePhoto(int index) {
    final next = [...state.photos]..removeAt(index);
    state = state.copyWith(photos: next);
  }

  /// Returns the created post on success (and refreshes feed/profile), or null
  /// on failure (with [ComposerState.error] set).
  Future<Post?> submit(String text) async {
    state = state.copyWith(busy: true);
    final result = await ref.read(createPostUseCaseProvider).call(
          PostDraft(text: text, photos: state.photos),
        );
    return result.fold(
      (failure) {
        state = state.copyWith(busy: false, error: failure);
        return null;
      },
      (post) {
        // Surface the new post immediately, and let the author's profile refetch.
        ref.read(feedControllerProvider.notifier).prepend(post);
        ref.invalidate(authorPostsProvider(post.authorId));
        state = const ComposerState();
        return post;
      },
    );
  }
}
