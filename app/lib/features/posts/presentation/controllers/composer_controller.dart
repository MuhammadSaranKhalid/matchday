import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/posts_datasource_providers.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../providers/post_store_provider.dart';
import '../providers/posts_providers.dart';
import '../state/composer_state.dart';
export '../state/composer_state.dart';
import 'feed_controller.dart';
import 'publisher_posts_controller.dart';

part 'composer_controller.g.dart';

/// Composer draft state: staged (cropped+resized) photos + submit lifecycle.
/// Autodisposed on modal dismiss to avoid stale partial drafts.
@riverpod
class ComposerController extends _$ComposerController {
  @override
  ComposerState build() => const ComposerState();

  Future<void> addPhoto() async {
    if (!state.canAddPhoto || state.busy) return;
    final picker = ref.read(photoPickerProvider);

    final photo = await picker.pickOne();
    if (photo == null || !ref.mounted) return;
    state = state.copyWith(photos: [...state.photos, photo]);
  }

  void removePhoto(int index) {
    final next = [...state.photos]..removeAt(index);
    state = state.copyWith(photos: next);
  }

  void setPublisher(PostPublisherSelection publisher) {
    state = state.copyWith(publisher: publisher);
  }

  /// Returns the created post on success (and refreshes feed/profile/team), or null
  /// on failure (with [ComposerState.error] set).
  Future<Post?> submit(String text) async {
    state = state.copyWith(busy: true);

    final profile = ref.read(myProfileProvider).value;
    final currentPublisher = state.publisher;
    final resolvedPublisher = (currentPublisher.type == PostPublisherType.user &&
            (currentPublisher.name == null || currentPublisher.name!.isEmpty))
        ? PostPublisherSelection(
            type: PostPublisherType.user,
            id: profile?.userId.value,
            name: profile?.displayName,
            username: profile?.username,
            photoUrl: profile?.avatarUrl,
          )
        : currentPublisher;

    final result = await ref.read(postCommandRepositoryProvider).createPost(
          PostDraft(
            text: text,
            photos: state.photos,
            publisher: resolvedPublisher,
            postKind: state.postKind,
            linkedMatchId: state.linkedMatchId,
            linkedTournamentId: state.linkedTournamentId,
            linkedTeamId: state.linkedTeamId,
          ),
        );
    if (!ref.mounted) return null;
    return result.fold(
      (failure) {
        state = state.copyWith(busy: false, error: failure);
        return null;
      },
      (post) {
        ref.read(postStoreProvider.notifier).upsert(post);
        ref.read(feedControllerProvider.notifier).prepend(post);
        ref
            .read(
              publisherPostsControllerProvider(
                publisherType: post.publisher.type,
                publisherId: post.publisher.id,
              ).notifier,
            )
            .prepend(post);
        state = const ComposerState();
        return post;
      },
    );
  }
}
