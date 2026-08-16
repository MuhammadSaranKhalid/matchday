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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header (Avatar + Name/Handle + Follow Button + 3-dots)
          const Row(
            children: [
              CkShimmerBox(
                width: 38,
                height: 38,
                shape: BoxShape.circle,
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CkShimmerBox(width: 110, height: 13, radius: 4),
                      SizedBox(width: 6),
                      CkShimmerBox(width: 24, height: 10, radius: 4),
                    ],
                  ),
                  SizedBox(height: 4),
                  CkShimmerBox(width: 65, height: 10, radius: 4),
                ],
              ),
              Spacer(),
              CkShimmerBox(width: 62, height: 26, radius: 8),
              SizedBox(width: 6),
              CkShimmerBox(width: 18, height: 18, radius: 4),
            ],
          ),
          const SizedBox(height: 10),

          // Caption Text Lines (Full width across card)
          const CkShimmerBox(height: 12, radius: 4),
          const SizedBox(height: 6),
          const FractionallySizedBox(
            widthFactor: 0.72,
            alignment: Alignment.centerLeft,
            child: CkShimmerBox(height: 12, radius: 4),
          ),

          // Optional Media Image Placeholder
          if (hasMedia) ...[
            const SizedBox(height: 10),
            CkShimmerBox(
              height: mediaHeight,
              radius: 12,
            ),
          ],

          const SizedBox(height: 12),

          // Action Bar Row (Likes, Comments, Share, Bookmark)
          const Row(
            children: [
              CkShimmerBox(width: 38, height: 14, radius: 4),
              SizedBox(width: 18),
              CkShimmerBox(width: 38, height: 14, radius: 4),
              SizedBox(width: 18),
              CkShimmerBox(width: 44, height: 14, radius: 4),
              Spacer(),
              CkShimmerBox(width: 16, height: 14, radius: 4),
            ],
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
