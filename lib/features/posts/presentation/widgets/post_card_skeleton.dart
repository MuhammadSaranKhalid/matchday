import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_shimmer.dart';

/// Skeleton placeholder for a single [FeedPostCard].
///
/// Mirrors the exact layout, padding, avatar size, text rhythm, media aspect ratio,
/// and action bar of real feed posts.
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({
    super.key,
    this.hasMedia = true,
    this.mediaHeight = 190,
  });

  /// Whether to render a media box placeholder in this post skeleton.
  final bool hasMedia;

  /// Height of the media rectangle placeholder.
  final double mediaHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Avatar Circle (36x36 matching standard Avatar widget)
          const CkShimmerBox(
            width: 36,
            height: 36,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: 12),
          // Post Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Name + Handle + Timestamp)
                const Row(
                  children: [
                    CkShimmerBox(width: 110, height: 13, radius: 4),
                    SizedBox(width: 6),
                    CkShimmerBox(width: 52, height: 11, radius: 4),
                    Spacer(),
                    CkShimmerBox(width: 24, height: 10, radius: 4),
                  ],
                ),
                const SizedBox(height: 9),

                // Caption Text Lines (Simulating 2 varied lines of text)
                const CkShimmerBox(height: 11, radius: 4),
                const SizedBox(height: 6),
                const FractionallySizedBox(
                  widthFactor: 0.68,
                  alignment: Alignment.centerLeft,
                  child: CkShimmerBox(height: 11, radius: 4),
                ),

                // Optional Media Image Placeholder
                if (hasMedia) ...[
                  const SizedBox(height: 12),
                  CkShimmerBox(
                    height: mediaHeight,
                    radius: 14,
                  ),
                ],

                const SizedBox(height: 14),

                // Action Bar Row (Likes, Comments, Share, Bookmark)
                const Row(
                  children: [
                    CkShimmerBox(width: 34, height: 13, radius: 4),
                    SizedBox(width: 18),
                    CkShimmerBox(width: 34, height: 13, radius: 4),
                    SizedBox(width: 18),
                    CkShimmerBox(width: 42, height: 13, radius: 4),
                    Spacer(),
                    CkShimmerBox(width: 14, height: 13, radius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full scrollable shimmer skeleton feed with multiple realistic post cards.
class FeedShimmerSkeleton extends StatelessWidget {
  const FeedShimmerSkeleton({
    super.key,
    this.itemCount = 4,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return CkShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 0.8,
          color: CkColors.hairline,
        ),
        itemBuilder: (context, index) {
          // Alternate between photo posts and text-only posts for visual variety
          final hasMedia = index % 3 != 1;
          final mediaHeight = index % 2 == 0 ? 190.0 : 160.0;
          return PostCardSkeleton(
            hasMedia: hasMedia,
            mediaHeight: mediaHeight,
          );
        },
      ),
    );
  }
}
