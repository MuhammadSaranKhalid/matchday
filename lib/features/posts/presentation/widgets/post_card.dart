import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_feed_image.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_media.dart';

class FeedPostCard extends StatelessWidget {
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(9),
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
  Widget build(BuildContext context) {
    final isTeam = post.authorContext == PostAuthorContext.teamManager;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        if ((post.text ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          _ExpandablePostText(text: post.text!),
        ],
        if (post.hasMedia) ...[
          const SizedBox(height: 10),
          PostMediaGrid(media: post.media, onOpen: onOpenPhoto),
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
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: showAuthor
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (isTeam) {
                      final teamId = post.linkedTeamId ?? post.contextEntityId;
                      if (teamId != null && teamId.isNotEmpty) {
                        context.push('/teams/$teamId');
                        return;
                      }
                    }
                    final u = post.authorUsername;
                    if (u != null && u.isNotEmpty) onAuthorTap?.call(u);
                  },
                  child: isTeam
                      ? (post.displayPhotoUrl != null &&
                              post.displayPhotoUrl!.trim().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: CachedNetworkImage(
                                imageUrl: post.displayPhotoUrl!.trim(),
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _buildTeamMonogram(),
                                errorWidget: (_, __, ___) =>
                                    _buildTeamMonogram(),
                              ),
                            )
                          : _buildTeamMonogram())
                      : Avatar(
                          mono: post.authorMonogram,
                          imageUrl: post.displayPhotoUrl,
                          tone: AvatarTone.ink,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  Widget _header(BuildContext context) {
    final time = timeago.format(post.createdAt, locale: 'en_short');
    final isTeam = post.authorContext == PostAuthorContext.teamManager;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (showAuthor) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isTeam) {
                final teamId = post.linkedTeamId ?? post.contextEntityId;
                if (teamId != null && teamId.isNotEmpty) {
                  context.push('/teams/$teamId');
                  return;
                }
              }
              final u = post.authorUsername;
              if (u != null && u.isNotEmpty) onAuthorTap?.call(u);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    post.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(fontSize: 13.5, letterSpacing: -0.01),
                  ),
                ),
                if (!isTeam && post.authorUsername != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '@${post.authorUsername}',
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (isTeam) ...[
          if (showAuthor) const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
          if (showAuthor) const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('★ AUTO',
                style: CkType.mono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.amber)),
          ),
        ],
        const Spacer(),
        Text(time, style: CkType.mono(fontSize: 9, letterSpacing: 0.10)),
      ],
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
