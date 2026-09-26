import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/utils/app_links.dart';
import '../../../../core/widgets/v2/ck_feed_image.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../follows/presentation/controllers/follow_toggle_controller.dart';
import '../../../teams/presentation/widgets/team_crest.dart';
import '../../domain/entities/post.dart';
import '../../../safety/presentation/widgets/safety_menu.dart';
import '../../../safety/presentation/providers/safety_providers.dart';
import '../../domain/entities/post_media.dart';
import '../controllers/post_interactions_controller.dart';
import '../providers/post_store_provider.dart';

class FeedPostCard extends ConsumerWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.onComment,
    required this.onOpenPhoto,
    this.onLike,
    this.onBookmark,
    this.onShare,
    this.onAuthorTap,
    this.showAuthor = true,
  });

  final Post post;
  final VoidCallback onComment;
  final void Function(int index) onOpenPhoto;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;

  /// Fires when the author avatar is tapped, passing the author's @handle.
  /// The host route pushes `/u/<username>` to open the public profile.
  /// Null is allowed for posts whose author was deleted (the avatar tap
  /// is then inert).
  final ValueChanged<String>? onAuthorTap;

  /// Hide the author avatar/name on a profile (where every post is the owner's).
  final bool showAuthor;

  /// A team author is a crest, not a square tile: artwork inset on a paper
  /// disc, against the player author's full-bleed photo circle below.
  Widget _teamCrest(Post post) => TeamCrest(
        name: post.displayName,
        logoUrl: post.displayPhotoUrl,
        monogram: post.displayMonogram,
        size: 38,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectivePost = ref.watch(postFromStoreProvider(post.id)) ?? post;

    final blocked = ref.watch(blockedAccountsProvider).value ?? [];
    if (blocked.any((u) => u.id == effectivePost.authorId)) return const SizedBox.shrink();

    final onLikeAction = onLike ??
        () => ref
            .read(postInteractionsControllerProvider.notifier)
            .toggleLike(effectivePost.id, fallback: effectivePost);
    final onBookmarkAction = onBookmark ??
        () => ref
            .read(postInteractionsControllerProvider.notifier)
            .toggleBookmark(effectivePost.id, fallback: effectivePost);
    final onShareAction = onShare ??
        () {
          SharePlus.instance.share(
            ShareParams(
              text:
                  'Check out this post on Matchday: ${AppLinks.post(effectivePost.id.value)}',
            ),
          );
        };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!showAuthor)
            Align(
              alignment: Alignment.centerRight,
              child: SafetyMenu(
                userId: effectivePost.authorId,
                kind: 'post',
                targetId: effectivePost.id.value,
                onShare: onShareAction,
              ),
            ),
          if (showAuthor) ...[
            _header(context, ref, effectivePost, onShareAction),
            const SizedBox(height: 10),
          ],
          if ((effectivePost.text ?? '').isNotEmpty) ...[
            _ExpandablePostText(text: effectivePost.text!),
            const SizedBox(height: 10),
          ],
          if (effectivePost.hasMedia) ...[
            PostMediaGrid(media: effectivePost.media, onOpen: onOpenPhoto),
            const SizedBox(height: 4),
          ],
          PostActions(
            likes: effectivePost.likesCount,
            comments: effectivePost.commentsCount,
            liked: effectivePost.isLiked,
            saved: effectivePost.isBookmarked,
            onLike: onLikeAction,
            onBookmark: onBookmarkAction,
            onShare: onShareAction,
            onComment: onComment,
          ),
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    WidgetRef ref,
    Post post,
    VoidCallback onShareAction,
  ) {
    final time = timeago.format(post.createdAt, locale: 'en_short');
    final isOrgPublisher = post.publisher.type != PostPublisherType.user;
    final currentUserId = ref.watch(currentUserIdProvider);

    final targetType = switch (post.publisher.type) {
      PostPublisherType.team => 'team',
      PostPublisherType.tournament => 'tournament',
      PostPublisherType.user => 'user',
    };
    final targetId = post.publisher.id;
    final isSelf = targetId.isNotEmpty &&
        (targetId == currentUserId || post.createdByUserId == currentUserId);
    final isFollowing = post.isFollowing;

    void onNavigate() {
      switch (post.publisher.type) {
        case PostPublisherType.team:
          final teamId = post.linkedTeamId ?? post.publisher.id;
          if (teamId.isNotEmpty) {
            context.push('/teams/$teamId');
          }
          break;
        case PostPublisherType.tournament:
          final tournamentId = post.linkedTournamentId ?? post.publisher.id;
          if (tournamentId.isNotEmpty) {
            context.push('/tournaments/$tournamentId');
          }
          break;
        case PostPublisherType.user:
          final u = post.publisher.username ?? post.authorUsername;
          if (u != null && u.isNotEmpty) onAuthorTap?.call(u);
          break;
      }
    }

    return Row(
      children: [
        // Avatar / Monogram
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onNavigate,
          child: isOrgPublisher
              ? _teamCrest(post)
              : Avatar(
                  mono: post.authorMonogram,
                  imageUrl: post.displayPhotoUrl,
                  tone: AvatarTone.ink,
                  size: 38,
                ),
        ),
        const SizedBox(width: 10),

        // Display Name, Badges, Time, and Username Subtitle
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onNavigate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.01,
                        ),
                      ),
                    ),
                    if (isOrgPublisher) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                        decoration: BoxDecoration(
                          color: CkColors.paper2,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: CkColors.hairline),
                        ),
                        child: Text(
                          post.publisher.type == PostPublisherType.tournament
                              ? 'TOURNAMENT'
                              : 'TEAM',
                          style: CkType.mono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.08,
                            color: CkColors.ink,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 5),
                    Text(
                      '· $time',
                      style: CkType.body(fontSize: 12, color: CkColors.muted),
                    ),
                  ],
                ),
                if (!isOrgPublisher && post.authorUsername != null && post.authorUsername!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    '@${post.authorUsername}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.mono(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Follow Button
        if (targetId.isNotEmpty && !isSelf) ...[
          const SizedBox(width: 8),
          _FeedFollowButton(
            isFollowing: isFollowing,
            onTap: () {
              ref.read(followToggleProvider(targetType, targetId).notifier).toggle();
              ref.read(postStoreProvider.notifier).updateWhere(
                    (p) => p.publisher.id == targetId,
                    (p) => p.copyWith(
                      viewer: p.viewer.copyWith(isFollowingPublisher: !isFollowing),
                    ),
                  );
            },
          ),
        ],

        SafetyMenu(
          userId: post.authorId,
          kind: 'post',
          targetId: post.id.value,
          onShare: onShareAction,
        ),
      ],
    );
  }
}

class _FeedFollowButton extends StatelessWidget {
  const _FeedFollowButton({
    required this.isFollowing,
    required this.onTap,
  });

  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? CkColors.paper2 : CkColors.ink,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFollowing ? CkColors.hairline : Colors.transparent,
          ),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: CkType.display(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isFollowing ? CkColors.ink : CkColors.paper,
          ),
        ),
      ),
    );
  }
}

/// 1–4 photo mosaic. Single image respects its (clamped) aspect ratio; 2–4 use
/// a fixed-height grid with cover crop. Tapping a cell calls [onOpen].
class PostMediaGrid extends StatelessWidget {
  const PostMediaGrid({super.key, required this.media, required this.onOpen});
  final List<PostMedia> media;
  final void Function(int index) onOpen;

  static const _gap = 2.0;
  static const _gridHeight = 240.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: switch (media.length) {
        0 => const SizedBox.shrink(),
        1 => _single(),
        2 => SizedBox(
            height: _gridHeight,
            child: Row(children: [
              Expanded(child: _cell(0)),
              const SizedBox(width: _gap),
              Expanded(child: _cell(1)),
            ]),
          ),
        3 => SizedBox(
            height: _gridHeight,
            child: Row(children: [
              Expanded(flex: 2, child: _cell(0)),
              const SizedBox(width: _gap),
              Expanded(
                child: Column(children: [
                  Expanded(child: _cell(1)),
                  const SizedBox(height: _gap),
                  Expanded(child: _cell(2)),
                ]),
              ),
            ]),
          ),
        _ => SizedBox(
            height: _gridHeight,
            child: Row(children: [
              Expanded(
                child: Column(children: [
                  Expanded(child: _cell(0)),
                  const SizedBox(height: _gap),
                  Expanded(child: _cell(2)),
                ]),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: Column(children: [
                  Expanded(child: _cell(1)),
                  const SizedBox(height: _gap),
                  Expanded(child: _cell(3)),
                ]),
              ),
            ]),
          ),
      },
    );
  }

  Widget _single() {
    final m = media[0];
    return GestureDetector(
      onTap: () => onOpen(0),
      child: AspectRatio(
        aspectRatio: m.aspectRatio.clamp(0.8, 1.91),
        child: CkFeedImage(
          url: m.url,
          variants: m.variantUrls,
          blurhash: m.blurhash ?? '',
          useAspectRatio: false,
        ),
      ),
    );
  }

  Widget _cell(int i) {
    final m = media[i];
    return GestureDetector(
      onTap: () => onOpen(i),
      child: CkFeedImage(
        url: m.url,
        variants: m.variantUrls,
        blurhash: m.blurhash ?? '',
        useAspectRatio: false,
      ),
    );
  }
}

class _ExpandablePostText extends StatefulWidget {
  const _ExpandablePostText({required this.text});
  final String text;

  @override
  State<_ExpandablePostText> createState() => _ExpandablePostTextState();
}

class _ExpandablePostTextState extends State<_ExpandablePostText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.length > 200 || '\n'.allMatches(widget.text).length >= 4;

    if (!isLong) {
      return Text(
        widget.text,
        style: CkType.body(fontSize: 14, height: 1.45, color: CkColors.ink),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: CkType.body(fontSize: 14, height: 1.45, color: CkColors.ink),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              _expanded ? 'Show less' : 'See more',
              style: CkType.body(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: CkColors.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
