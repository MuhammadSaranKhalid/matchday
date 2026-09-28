import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_shimmer.dart';

/// Shimmer skeleton loading state for the followers/following list.
class FollowsShimmerSkeleton extends StatelessWidget {
  const FollowsShimmerSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return CkShimmer(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 1,
          color: CkColors.hairline,
        ),
        itemBuilder: (_, __) => const _FollowerTileSkeleton(),
      ),
    );
  }
}

class _FollowerTileSkeleton extends StatelessWidget {
  const _FollowerTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          // Avatar circle
          CkShimmerBox(
            width: 42,
            height: 42,
            shape: BoxShape.circle,
          ),
          SizedBox(width: 12),
          // Name and handle lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CkShimmerBox(width: 120, height: 14, radius: 4),
                SizedBox(height: 6),
                CkShimmerBox(width: 70, height: 10, radius: 4),
              ],
            ),
          ),
          SizedBox(width: 12),
          // Follow button placeholder
          CkShimmerBox(width: 80, height: 34, radius: 10),
        ],
      ),
    );
  }
}
