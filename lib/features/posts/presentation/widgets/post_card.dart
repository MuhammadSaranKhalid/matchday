// Post UI for the feed/profile — renders a real [Post] (author header + text +
// 1–4 photo mosaic via CkFeedImage + action bar). Lives in the posts feature
// (it's coupled to the Post entity), not in the feature-agnostic core kit.
//
// Layout follows the prototype's `Post` in home-messages.jsx: the avatar sits
// inline at the start of the header row (not as a separate left column), so
// the body flows full-width below the header. Recruitment posts (type ==
// recruitment) get a full-width "Offer to play" CTA above the action bar.
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_feed_image.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../../core/widgets/v2/v2_modals.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_media.dart';

/// Canonical web base for a shared post link. There is no per-post route yet
/// (a `/p/:postId` deep link is a follow-up ticket), so the share sheet
/// currently falls back to the AUTHOR'S profile link — that route is fully
/// wired (universal/app links + `/u/:username`). Once the post route exists,
/// flip the URL constructor here.
const String _profileLinkBase = 'https://joinmatchday.com/u';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.onComment,
    required this.onOpenPhoto,
    this.onAuthorTap,
    this.showAuthor = true,
  });

  final Post post;
  final VoidCallback onComment;
  final void Function(int index) onOpenPhoto;

  /// Fires when the author avatar is tapped, passing the author's @handle.
  /// The host route pushes `/u/<username>` to open the public profile.
  /// Null is allowed for posts whose author was deleted (the avatar tap
  /// is then inert).
  final ValueChanged<String>? onAuthorTap;

  /// Hide the author avatar/name on a profile (where every post is the owner's).
  final bool showAuthor;

  void _openAuthor() {
    final u = post.authorUsername;
    if (u != null && u.isNotEmpty) onAuthorTap?.call(u);
  }

  void _openShare(BuildContext context) {
    final handle = post.authorUsername;
    final name = post.authorName ?? 'A matchday player';
    final link = (handle != null && handle.isNotEmpty)
        ? '$_profileLinkBase/$handle'
        : 'https://joinmatchday.com';
    final message = 'Check out this post by $name on matchday 🏏';
    showPostShareSheet(context, link: link, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAuthor) ...[
            _Header(post: post, onAuthorTap: _openAuthor),
            const SizedBox(height: 6),
          ],
          if ((post.text ?? '').isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onComment,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  post.text!,
                  style: CkType.body(
                      fontSize: 14, height: 1.5, color: CkColors.ink),
                ),
              ),
            ),
          if (post.hasMedia) ...[
            const SizedBox(height: 10),
            PostMediaGrid(media: post.media, onOpen: onOpenPhoto),
          ],
          if (post.type == PostType.recruitment) ...[
            const SizedBox(height: 10),
            _OfferToPlayButton(onTap: _openAuthor),
          ],
          PostActions(
            likes: post.likesCount,
            comments: post.commentsCount,
            onComment: onComment,
            onShare: () => _openShare(context),
          ),
        ],
      ),
    );
  }
}

/// Header row — inline avatar + author name (Inter Tight 700) · `@handle` ·
/// timeago, with the `★ AUTO` chip when the post was auto-generated. The
/// dots-button on the right is reserved for the overflow popover (next PR);
/// for now it's a no-op visual placeholder so the layout matches the spec.
class _Header extends StatelessWidget {
  const _Header({required this.post, required this.onAuthorTap});

  final Post post;
  final VoidCallback onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final time = timeago.format(post.createdAt, locale: 'en_short');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onAuthorTap,
          child: Avatar(
            mono: post.authorMonogram,
            size: 40,
            tone: AvatarTone.ink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAuthorTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        post.authorName ?? 'matchday player',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(
                            fontSize: 14, letterSpacing: -0.01),
                      ),
                    ),
                    if (post.autoGenerated) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
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
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  post.authorUsername != null
                      ? '@${post.authorUsername} · $time'
                      : time,
                  style: CkType.mono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      color: CkColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferToPlayButton extends StatelessWidget {
  const _OfferToPlayButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Offer to play',
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CkColors.paper,
            ),
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
