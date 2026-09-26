import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/theme/circk_theme.dart';
import '../../../../../../core/widgets/modals/modals.dart';
import '../../../../../posts/presentation/providers/posts_providers.dart';
import '../../../../../posts/presentation/screens/photo_viewer_screen.dart';
import '../../../../../posts/presentation/widgets/post_card.dart';
import '../../../../../posts/presentation/widgets/post_card_skeleton.dart';

class TeamPostsTab extends ConsumerWidget {
  const TeamPostsTab({super.key, required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(teamPostsProvider(teamId));
    return RefreshIndicator(
      color: CkColors.ink,
      onRefresh: () async => ref.refresh(teamPostsProvider(teamId).future),
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        children: [
          switch (postsAsync) {
            AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: CkColors.paper2,
                          shape: BoxShape.circle,
                          border: Border.all(color: CkColors.hairline),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.campaign_outlined,
                          size: 24,
                          color: CkColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No team posts yet',
                        style: CkType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Match announcements, photos, and team updates will appear here.',
                        textAlign: TextAlign.center,
                        style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                      ),
                    ],
                  ),
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
                        postAuthorHandle: post.authorUsername != null &&
                                post.authorUsername!.isNotEmpty
                            ? '@${post.authorUsername}'
                            : post.authorName,
                        onOpenProfile: (String username) =>
                            context.push('/u/$username'),
                      ),
                      onAuthorTap: (String username) =>
                          context.push('/u/$username'),
                      onOpenPhoto: (int index) {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PhotoViewerScreen(
                              media: post.media,
                              initialIndex: index,
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
                    style: TextStyle(fontSize: 13, color: CkColors.muted),
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
