import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_feed_image.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../follows/presentation/controllers/follow_toggle_controller.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_media.dart';

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

  Widget _buildTeamMonogram() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        post.displayMonogram,
        style: CkType.display(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: CkColors.paper,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAuthor) ...[
            _header(context, ref),
            const SizedBox(height: 10),
          ],
          if ((post.text ?? '').isNotEmpty) ...[
            _ExpandablePostText(text: post.text!),
            const SizedBox(height: 10),
          ],
          if (post.hasMedia) ...[
            PostMediaGrid(media: post.media, onOpen: onOpenPhoto),
            const SizedBox(height: 4),
          ],
          PostActions(
            likes: post.likesCount,
            comments: post.commentsCount,
            liked: post.isLiked,
            saved: post.isBookmarked,
            onLike: onLike,
            onBookmark: onBookmark,
            onShare: onShare,
            onComment: onComment,
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref) {
    final time = timeago.format(post.createdAt, locale: 'en_short');
    final isTeam = post.authorContext == PostAuthorContext.teamManager;
    final currentUserId = ref.watch(currentUserStreamProvider).value?.id.value;

    final targetType = isTeam ? 'team' : 'user';
    final targetId = isTeam ? (post.linkedTeamId ?? post.contextEntityId) : post.authorId;
    final isSelf = targetId != null && (targetId == currentUserId || post.authorId == currentUserId);

    final isFollowingAsync = (targetId != null && !isSelf)
        ? ref.watch(followToggleProvider(targetType, targetId))
        : null;
    final isFollowing = isFollowingAsync?.value ?? false;

    void onNavigate() {
      if (isTeam) {
        final teamId = post.linkedTeamId ?? post.contextEntityId;
        if (teamId != null && teamId.isNotEmpty) {
          context.push('/teams/$teamId');
          return;
        }
      }
      final u = post.authorUsername;
      if (u != null && u.isNotEmpty) onAuthorTap?.call(u);
    }

    return Row(
      children: [
        // Avatar / Monogram
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onNavigate,
          child: isTeam
              ? (post.displayPhotoUrl != null && post.displayPhotoUrl!.trim().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: post.displayPhotoUrl!.trim(),
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildTeamMonogram(),
                        errorWidget: (_, __, ___) => _buildTeamMonogram(),
                      ),
                    )
                  : _buildTeamMonogram())
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
                    if (isTeam) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                        decoration: BoxDecoration(
                          color: CkColors.paper2,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: CkColors.hairline),
                        ),
                        child: Text(
                          'TEAM',
                          style: CkType.mono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.08,
                            color: CkColors.ink,
                          ),
                        ),
                      ),
                    ],
                    if (post.autoGenerated) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                        decoration: BoxDecoration(
                          color: CkColors.cream,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '★ AUTO',
                          style: CkType.mono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.08,
                            color: CkColors.amber,
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
                if (!isTeam && post.authorUsername != null && post.authorUsername!.isNotEmpty) ...[
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
        if (targetId != null && !isSelf) ...[
          const SizedBox(width: 8),
          _FeedFollowButton(
            isFollowing: isFollowing,
            onTap: () {
              ref.read(followToggleProvider(targetType, targetId).notifier).toggle();
            },
          ),
        ],

        // 3-dots more menu
        IconButton(
          icon: const Icon(Icons.more_horiz_rounded, size: 20, color: CkColors.muted),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onShare,
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
        child: CkFeedImage(url: m.url, blurhash: m.blurhash, useAspectRatio: false),
      ),
    );
  }

  Widget _cell(int i) {
    final m = media[i];
    return GestureDetector(
      onTap: () => onOpen(i),
      child: CkFeedImage(url: m.url, blurhash: m.blurhash, useAspectRatio: false),
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
