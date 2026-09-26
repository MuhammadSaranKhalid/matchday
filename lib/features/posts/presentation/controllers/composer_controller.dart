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

    // Pick + crop + resize (max 2048px JPEG) — returns fast.
    // Canonical BlurHash is computed server-side by the Firebase/Sharp pipeline (Point 83).
    final photo = await picker.pickOne();
    if (photo == null || !ref.mounted) return;
    state = state.copyWith(photos: [...state.photos, photo]);
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
        // Media posts remain in publishing state while images process and are shown
        // exclusively via pendingPostsProvider above the feed.
        // Only active posts (such as text-only posts) should be prepended to the canonical feed.
        if (post.status == PostStatus.active) {
          ref.read(feedControllerProvider.notifier).prepend(post);
        }
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
