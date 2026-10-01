import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Shape-matched shimmer skeleton for tournament cards using design system tokens.
class TournamentCardShimmer extends StatelessWidget {
  const TournamentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;

    return ShimmerLoading(
      child: Container(
        padding: EdgeInsets.all(layout.cardPadding),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(layout.cardRadius),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerBox(width: 38, height: 38, radius: 10),
                SizedBox(width: layout.inlineGap),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 16),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 12),
                    ],
                  ),
                ),
                const ShimmerBox(width: 60, height: 18, radius: 4),
              ],
            ),
            SizedBox(height: layout.itemGap),
            Divider(height: 1, color: scheme.outlineVariant),
            SizedBox(height: layout.inlineGap),
            Row(
              children: [
                const ShimmerBox(width: 80, height: 12),
                SizedBox(width: layout.inlineGap),
                const ShimmerBox(width: 60, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for points standings table using design system tokens.
class StandingsTableShimmer extends StatelessWidget {
  const StandingsTableShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;

    return ShimmerLoading(
      child: Column(
        children: [
          Container(
            height: 38,
            color: scheme.surfaceContainer,
            padding: EdgeInsets.symmetric(horizontal: layout.screenGutter),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 60, height: 12, color: scheme.outline),
                ShimmerBox(width: 160, height: 12, color: scheme.outline),
              ],
            ),
          ),
          for (int i = 0; i < 6; i++) ...[
            Container(
              height: 48,
              padding: EdgeInsets.symmetric(horizontal: layout.screenGutter),
              child: const Row(
                children: [
                  ShimmerBox(width: 16, height: 12),
                  SizedBox(width: 8),
                  ShimmerBox(width: 20, height: 20, radius: 4),
                  SizedBox(width: 8),
                  ShimmerBox(width: 90, height: 14),
                  Spacer(),
                  ShimmerBox(width: 120, height: 14),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}
