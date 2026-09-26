import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/modals/comments_sheet.dart';
import '../../domain/entities/post_media.dart';
import '../controllers/saved_posts_controller.dart';
import '../providers/post_store_provider.dart';
import '../widgets/post_card.dart';
import 'photo_viewer_screen.dart';

/// Screen displaying the user's saved/bookmarked posts (/saved).
/// Backed by normalized [SavedPostsController] (membership) and [PostStore] (entities).
class SavedPostsScreen extends ConsumerStatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  ConsumerState<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends ConsumerState<SavedPostsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(savedPostsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final queryStateAsync = ref.watch(savedPostsControllerProvider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      appBar: AppBar(
        backgroundColor: CkColors.paper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CkColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Saved Posts',
          style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: queryStateAsync.when(
        data: (state) {
          final ids = state.ids;
          if (ids.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bookmark_border_rounded,
                      size: 48,
                      color: CkColors.muted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No saved posts yet',
                      style: CkType.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bookmark posts in your feed to save them for later.',
                      textAlign: TextAlign.center,
                      style: CkType.body(fontSize: 13, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: CkColors.ink,
            onRefresh: () => ref.read(savedPostsControllerProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: ids.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= ids.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: CkColors.ink),
                    ),
                  );
                }

                final postId = ids[i];
                final post = ref.watch(postFromStoreProvider(postId));
                if (post == null) return const SizedBox.shrink();

                return FeedPostCard(
                  post: post,
                  onComment: () => showCommentsSheet(
                    context,
                    postId: post.id.value,
                    postAuthorHandle: post.authorUsername != null &&
                            post.authorUsername!.isNotEmpty
                        ? '@${post.authorUsername}'
                        : post.authorName,
                    onOpenProfile: (username) => context.push('/u/$username'),
                  ),
                  onAuthorTap: (username) => context.push('/u/$username'),
                  onOpenPhoto: (index) => _openPhoto(context, post.media, index),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: CkColors.ink),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 36, color: CkColors.muted),
                const SizedBox(height: 12),
                Text(
                  'Could not load saved posts',
                  style: CkType.display(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.read(savedPostsControllerProvider.notifier).refresh(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPhoto(BuildContext context, List<PostMedia> media, int index) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewerScreen(media: media, initialIndex: index),
      ),
    );
  }
}
