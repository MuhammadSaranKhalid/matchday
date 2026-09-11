import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/ck_shimmer.dart';

/// The My Teams loading state.
///
/// Shape-matched, not generic: every box below traces the real widget it
/// stands in for — [Subhead]'s 18/16/18/6 box around a 10pt mono label, and
/// [TeamRow]'s 14/4 margin, 12pt padding, 44pt crest disc, 15pt name line and
/// 11.5pt meta line. The row's own chrome (paper-2 fill, hairline border,
/// 12pt radius) is rendered for real and only its *contents* shimmer, so the
/// rows read as rows rather than as slabs, and nothing shifts when data lands.
///
/// Only one section is drawn. Which sections a real user gets — lead, play,
/// manage — is not known until the data arrives, and the needs-you banner and
/// upcoming-match card are both conditional; promising them here would make
/// the list jump when they do not come.
///
/// The chrome above this (the push nav, with its live "Create" pill) stays
/// real — never shimmer a control the user can already use.
class MyTeamsShimmerSkeleton extends StatelessWidget {
  const MyTeamsShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        // Not scrollable: there is nothing below the fold to reach, and the
        // padding matches the real list so the first row lands in place.
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        children: const [
          _SubheadSkeleton(),
          // The sweep runs on the first row only and the rest fade back — the
          // same grammar as the My Matches skeleton, and it keeps three
          // animated ShaderMasks off the first frame.
          _TeamRowSkeleton(
            opacity: 1,
            live: true,
            nameWidth: 144,
            metaWidth: 176,
          ),
          _TeamRowSkeleton(
            opacity: 0.7,
            live: false,
            nameWidth: 118,
            metaWidth: 148,
          ),
          _TeamRowSkeleton(
            opacity: 0.4,
            live: false,
            nameWidth: 136,
            metaWidth: 162,
          ),
        ],
      );
}

/// Stands in for a `Subhead` — same padding box, same 10pt label height.
class _SubheadSkeleton extends StatelessWidget {
  const _SubheadSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(18, 16, 18, 6),
        child: CkShimmer(
          child: CkShimmerBox(width: 104, height: 14, radius: 4),
        ),
      );
}

/// Stands in for a `TeamRow`. Chrome real, contents skeletal.
class _TeamRowSkeleton extends StatelessWidget {
  const _TeamRowSkeleton({
    required this.opacity,
    required this.live,
    required this.nameWidth,
    required this.metaWidth,
  });

  final double opacity;
  final bool live;

  /// Real names and meta lines differ in length row to row; fixed widths
  /// across all three would read as a repeated stamp.
  final double nameWidth;
  final double metaWidth;

  @override
  Widget build(BuildContext context) {
    Widget shim(Widget c) => live ? CkShimmer(child: c) : c;
    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // The crest is a disc at every size (TeamCrest), so is this.
              shim(
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
                    // Team name — display 15.
                    shim(CkShimmerBox(width: nameWidth, height: 15, radius: 4)),
                    // 7, not the real 3: the bars are drawn at font size
                    // rather than at full line height, and this puts them back
                    // on the baselines the two text lines actually occupy.
                    const SizedBox(height: 7),
                    // Meta line — mono 11.5. Usually runs longer than the name
                    // ("Karachi · 14 players"), so it is drawn that way.
                    CkShimmerBox(width: metaWidth, height: 12, radius: 4),
                  ],
                ),
              ),
              // Real, like the row's border: the chevron is identical in every
              // row whatever the data says.
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
