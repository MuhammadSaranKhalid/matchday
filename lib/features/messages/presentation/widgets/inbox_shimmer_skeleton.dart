import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_shimmer.dart';

/// Shimmer skeleton loading placeholder for the messages inbox.
class InboxShimmerSkeleton extends StatelessWidget {
  const InboxShimmerSkeleton({super.key, this.itemCount = 7});

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
        itemBuilder: (_, __) => const _SkeletonThreadRow(),
      ),
    );
  }
}

class _SkeletonThreadRow extends StatelessWidget {
  const _SkeletonThreadRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar circle placeholder
          CkShimmerBox(
            width: 48,
            height: 48,
            radius: 24,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name placeholder
                    CkShimmerBox(
                      width: 130,
                      height: 15,
                      radius: 4,
                    ),
                    // Time placeholder
                    CkShimmerBox(
                      width: 38,
                      height: 11,
                      radius: 3,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Message snippet placeholder
                CkShimmerBox(
                  width: double.infinity,
                  height: 13,
                  radius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
