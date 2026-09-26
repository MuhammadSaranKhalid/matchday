import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/modals/comments_sheet.dart';
import '../../domain/entities/post_media.dart';
import '../providers/posts_providers.dart';
import '../widgets/post_card.dart';
import 'photo_viewer_screen.dart';

/// Screen displaying the user's saved/bookmarked posts (/saved).
class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPostsProvider);

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
      body: savedAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
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
            onRefresh: () async => ref.refresh(savedPostsProvider.future),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, i) {
                final post = posts[i];
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
                  onLike: () async {
                    await ref
                        .read(postsRepositoryProvider)
                        .setPostLike(post.id, liked: !post.isLiked);
                    ref.invalidate(savedPostsProvider);
                  },
                  onBookmark: () async {
                    await ref
                        .read(postsRepositoryProvider)
                        .setPostBookmark(post.id, bookmarked: false);
                    ref.invalidate(savedPostsProvider);
                  },
                  onShare: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Check out this post on Matchday: https://matchday.cricket/posts/${post.id.value}',
                      ),
                    );
                  },
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
                  onPressed: () => ref.refresh(savedPostsProvider),
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
