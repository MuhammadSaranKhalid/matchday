import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_shimmer.dart';

/// Shimmer skeleton loading placeholder for the notifications inbox.
///
/// Shape-matched to `_TierHead` and `_Row` in `notifications_screen.dart`,
/// keeping outer chrome real and rendering varied content widths so rows
/// do not look like identical stamps while loading.
class NotificationsShimmerSkeleton extends StatelessWidget {
  const NotificationsShimmerSkeleton({super.key, this.itemCount = 7});

  final int itemCount;

  static const _rowVariations = [
    (titleWidth: 190.0, bodyWidth: 260.0, timeWidth: 26.0),
    (titleWidth: 140.0, bodyWidth: 210.0, timeWidth: 32.0),
    (titleWidth: 220.0, bodyWidth: 280.0, timeWidth: 28.0),
    (titleWidth: 165.0, bodyWidth: 195.0, timeWidth: 24.0),
    (titleWidth: 180.0, bodyWidth: 240.0, timeWidth: 30.0),
    (titleWidth: 150.0, bodyWidth: 200.0, timeWidth: 28.0),
    (titleWidth: 210.0, bodyWidth: 270.0, timeWidth: 34.0),
  ];

  @override
  Widget build(BuildContext context) {
    return CkShimmer(
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const _TierHeadSkeleton(),
          for (var i = 0; i < itemCount; i++) ...[
            _NotificationRowSkeleton(
              titleWidth: _rowVariations[i % _rowVariations.length].titleWidth,
              bodyWidth: _rowVariations[i % _rowVariations.length].bodyWidth,
              timeWidth: _rowVariations[i % _rowVariations.length].timeWidth,
            ),
          ],
        ],
      ),
    );
  }
}

class _TierHeadSkeleton extends StatelessWidget {
  const _TierHeadSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          CkShimmerBox(width: 6, height: 6, shape: BoxShape.circle),
          SizedBox(width: 8),
          CkShimmerBox(width: 72, height: 10, radius: 3),
        ],
      ),
    );
  }
}

class _NotificationRowSkeleton extends StatelessWidget {
  const _NotificationRowSkeleton({
    required this.titleWidth,
    required this.bodyWidth,
    required this.timeWidth,
  });

  final double titleWidth;
  final double bodyWidth;
  final double timeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 13, 18, 13),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left unread indicator bar
          const CkShimmerBox(width: 3, height: 32, radius: 2),
          const SizedBox(width: 12),
          // Notification icon box
          const CkShimmerBox(width: 32, height: 32, radius: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CkShimmerBox(
                          width: titleWidth,
                          height: 14,
                          radius: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CkShimmerBox(width: timeWidth, height: 10, radius: 3),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CkShimmerBox(width: bodyWidth, height: 11, radius: 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
