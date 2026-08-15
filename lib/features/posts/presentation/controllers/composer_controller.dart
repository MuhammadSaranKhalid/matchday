import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/posts_datasource_providers.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../providers/posts_providers.dart';
import '../state/composer_state.dart';
export '../state/composer_state.dart';
import 'feed_controller.dart';

part 'composer_controller.g.dart';


/// Composer draft state: staged (cropped+resized) photos + submit lifecycle.
/// The text is owned by the screen's TextEditingController and passed to submit.
@Riverpod(keepAlive: true)
class ComposerController extends _$ComposerController {
  @override
  ComposerState build() => const ComposerState();

  Future<void> addPhoto() async {
    if (!state.canAddPhoto || state.busy) return;
    final picker = ref.read(photoPickerProvider);

    // 1) Pick + crop + resize — returns fast; show the thumbnail immediately.
    final photo = await picker.pickOne();
    // mounted guard: the composer may have been closed during the picker/crop
    // or the (slower) hash await, which disposes this autodispose provider.
    if (photo == null || !ref.mounted) return;
    state = state.copyWith(photos: [...state.photos, photo]);

    // 2) Compute the BlurHash off the main isolate, then patch it into the
    //    same photo (matched by identity; skipped if it was removed meanwhile).
    final hash = await picker.blurHashFor(photo.file);
    if (!ref.mounted) return;
    final list = [...state.photos];
    final i = list.indexWhere((p) => identical(p, photo));
    if (i != -1) {
      list[i] = photo.copyWith(blurhash: hash, hashPending: false);
      state = state.copyWith(photos: list);
    }
  }

  void removePhoto(int index) {
    final next = [...state.photos]..removeAt(index);
    state = state.copyWith(photos: next);
  }

  void setIdentity({
    required PostAuthorContext authorContext,
    String? contextEntityId,
    String? entityName,
    String? entityMono,
  }) {
    state = state.copyWith(
      authorContext: authorContext,
      contextEntityId: contextEntityId,
      entityName: entityName,
      entityMono: entityMono,
    );
  }

  /// Returns the created post on success (and refreshes feed/profile/team), or null
  /// on failure (with [ComposerState.error] set).
  Future<Post?> submit(String text) async {
    state = state.copyWith(busy: true);
    final result = await ref.read(postsRepositoryProvider).createPost(
          PostDraft(
            text: text,
            photos: state.photos,
            authorContext: state.authorContext,
            contextEntityId: state.contextEntityId,
          ),
        );
    // Composer closed mid-submit → don't touch disposed state/providers.
    if (!ref.mounted) return null;
    return result.fold(
      (failure) {
        state = state.copyWith(busy: false, error: failure);
        return null;
      },
      (post) {
        // Surface the new post immediately, and let the author's profile & team refetch.
        ref.read(feedControllerProvider.notifier).prepend(post);
        ref.invalidate(authorPostsProvider(post.authorId));
        if (post.contextEntityId != null) {
          ref.invalidate(teamPostsProvider(post.contextEntityId!));
        }
        state = const ComposerState();
        return post;
      },
    );
  }
}
