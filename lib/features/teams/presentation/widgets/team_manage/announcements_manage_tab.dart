import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/modals/modals.dart';
import '../../../../posts/presentation/providers/posts_providers.dart';
import '../../../../posts/presentation/screens/photo_viewer_screen.dart';
import '../../../../posts/presentation/widgets/post_card.dart';
import '../../../../posts/presentation/widgets/post_card_skeleton.dart';
import '../../../domain/entities/team.dart';

class TeamAnnouncementsManageTab extends ConsumerWidget {
  const TeamAnnouncementsManageTab({super.key, required this.team});
  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(teamPostsProvider(team.id.value));

    return RefreshIndicator(
      color: CkColors.ink,
      onRefresh: () async =>
          ref.refresh(teamPostsProvider(team.id.value).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CkColors.ink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.campaign_outlined,
                        size: 18,
                        color: CkColors.paper,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Post Announcement',
                            style: CkType.display(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Share trials, match updates & squad selections',
                            style: CkType.body(
                              fontSize: 11.5,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final uri = Uri(
                        path: '/composer',
                        queryParameters: {
                          'teamId': team.id.value,
                          'teamName': team.name,
                          if (team.logoMonogram != null &&
                              team.logoMonogram!.isNotEmpty)
                            'teamMono': team.logoMonogram!,
                        },
                      );
                      context.push(uri.toString());
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: Text('Post as ${team.name}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.ink,
                      foregroundColor: CkColors.paper,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'PUBLISHED POSTS',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          switch (postsAsync) {
            AsyncData(:final value) when value.isEmpty => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 32,
                      color: CkColors.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No posts published yet',
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posts you publish as ${team.name} will appear here and on the team\'s public page.',
                      textAlign: TextAlign.center,
                      style:
                          CkType.body(fontSize: 12, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
            AsyncData(:final value) => Column(
                children: [
                  for (final post in value)
                    FeedPostCard(
                      post: post,
                      onComment: () => showCommentsSheet(
                        context,
                        postId: post.id.value,
                        postAuthorHandle:
                            post.authorUsername != null &&
                                    post.authorUsername!.isNotEmpty
                                ? '@${post.authorUsername}'
                                : post.authorName,
                        onOpenProfile: (String u) =>
                            context.push('/u/$u'),
                      ),
                      onLike: () => ref
                          .read(postsRepositoryProvider)
                          .togglePostLike(post.id),
                      onBookmark: () => ref
                          .read(postsRepositoryProvider)
                          .toggleBookmark(post.id),
                      onAuthorTap: (String u) => context.push('/u/$u'),
                      onOpenPhoto: (int idx) {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PhotoViewerScreen(
                              media: post.media,
                              initialIndex: idx,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            AsyncError() => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Could not load posts.',
                    style:
                        TextStyle(fontSize: 13, color: CkColors.muted),
                  ),
                ),
              ),
            _ => const Padding(
                padding: EdgeInsets.all(16),
                child: PostCardSkeleton(),
              ),
          },
        ],
      ),
    );
  }
}
