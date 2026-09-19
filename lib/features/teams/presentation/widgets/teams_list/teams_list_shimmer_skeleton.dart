import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/ck_shimmer.dart';

/// Shape-matched loading state for the team list.
///
/// The navigation bar stays real and interactive. Only the rows that depend on
/// the membership query shimmer.
class TeamsListShimmerSkeleton extends StatelessWidget {
  const TeamsListShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: const [
          _SectionSkeleton(),
          _TeamRowSkeleton(
            opacity: 1,
            animated: true,
            nameWidth: 144,
            metaWidth: 176,
          ),
          _TeamRowSkeleton(
            opacity: 0.7,
            animated: false,
            nameWidth: 118,
            metaWidth: 148,
          ),
          _TeamRowSkeleton(
            opacity: 0.4,
            animated: false,
            nameWidth: 136,
            metaWidth: 162,
          ),
        ],
      );
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(18, 16, 18, 6),
        child: CkShimmer(
          child: CkShimmerBox(
            width: 120,
            height: 14,
            radius: 4,
          ),
        ),
      );
}

class _TeamRowSkeleton extends StatelessWidget {
  const _TeamRowSkeleton({
    required this.opacity,
    required this.animated,
    required this.nameWidth,
    required this.metaWidth,
  });

  final double opacity;
  final bool animated;
  final double nameWidth;
  final double metaWidth;

  @override
  Widget build(BuildContext context) {
    Widget shimmer(Widget child) =>
        animated ? CkShimmer(child: child) : child;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              shimmer(
                const CkShimmerBox(
                  width: 44,
                  height: 44,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    shimmer(
                      CkShimmerBox(
                        width: nameWidth,
                        height: 15,
                        radius: 4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    CkShimmerBox(
                      width: metaWidth,
                      height: 12,
                      radius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: CkColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
