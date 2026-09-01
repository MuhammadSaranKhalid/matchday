import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';

/// Shape-matched shimmer skeleton for tournament cards.
class TournamentCardShimmer extends StatelessWidget {
  const TournamentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skeletonBox(width: 38, height: 38, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(width: 140, height: 16),
                    const SizedBox(height: 6),
                    _skeletonBox(width: 90, height: 12),
                  ],
                ),
              ),
              _skeletonBox(width: 60, height: 18, radius: 4),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: CkColors.hairline),
          const SizedBox(height: 12),
          Row(
            children: [
              _skeletonBox(width: 80, height: 12),
              const SizedBox(width: 12),
              _skeletonBox(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _skeletonBox({
    required double width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Shimmer skeleton for points standings table.
class StandingsTableShimmer extends StatelessWidget {
  const StandingsTableShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 38,
          color: CkColors.paper2,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 60, height: 12, color: CkColors.line),
              Container(width: 160, height: 12, color: CkColors.line),
            ],
          ),
        ),
        for (int i = 0; i < 6; i++) ...[
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(width: 16, height: 12, color: CkColors.paper2),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 90, height: 14, color: CkColors.paper2),
                const Spacer(),
                Container(width: 120, height: 14, color: CkColors.paper2),
              ],
            ),
          ),
          const Divider(height: 1, color: CkColors.hairline),
        ],
      ],
    );
  }
}
