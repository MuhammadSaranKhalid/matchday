import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../domain/entities/match_result.dart';
import 'explore_atoms.dart';

/// A card in the LIVE NOW rail — the one genuinely exciting object on the
/// Explore screen, and the only place the red accent is spent in browse.
///
/// Shows both sides with the batting team's score. The side that is not
/// batting shows "TO BAT" (first innings) or its completed total, never a
/// fabricated number: which side owns [MatchResult.totalRuns] is derived
/// server-side from the toss, and is null when the toss has not been
/// recorded — in which case neither side is attributed a score.
class LiveMatchCard extends StatelessWidget {
  const LiveMatchCard({super.key, required this.match, this.onTap});

  final MatchResult match;
  final VoidCallback? onTap;

  static const double width = 250;

  @override
  Widget build(BuildContext context) {
    final score = match.scoreLine;
    final overs = match.oversLine;
    final knownBatting = match.battingTeamId != null;

    return SizedBox(
      width: width,
      child: Material(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(CkRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CkRadii.md),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const _LiveDotPill(),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        (match.tournamentName ?? 'Friendly').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06,
                          color: CkColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                _SideLine(
                  name: match.teamAName ?? 'TBD',
                  color: ckParseColor(match.teamAColor),
                  logoUrl: match.teamALogoUrl,
                  // Attribute the score only when we actually know who bats.
                  score: knownBatting && match.isTeamABatting ? score : null,
                  dim: knownBatting && !match.isTeamABatting,
                ),
                const SizedBox(height: 8),
                _SideLine(
                  name: match.teamBName ?? 'TBD',
                  color: ckParseColor(match.teamBColor),
                  logoUrl: match.teamBLogoUrl,
                  score: knownBatting && !match.isTeamABatting ? score : null,
                  dim: knownBatting && match.isTeamABatting,
                ),
                const SizedBox(height: 9),
                const Divider(height: 1, color: CkColors.hairline),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _footer(overs),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.05,
                          color: CkColors.muted,
                        ),
                      ),
                    ),
                    if (match.venue?.isNotEmpty == true) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          match.venue!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: CkType.mono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.05,
                            color: CkColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "8.3 OV · NEED 43" when chasing, "8.3 OV" otherwise.
  String _footer(String? overs) {
    final parts = <String>[
      if (overs != null) '$overs ov',
      if (match.target != null && match.totalRuns != null)
        'need ${match.target! - match.totalRuns!}',
    ];
    return parts.isEmpty ? 'LIVE' : parts.join(' · ').toUpperCase();
  }
}

class _SideLine extends StatelessWidget {
  const _SideLine({
    required this.name,
    required this.color,
    required this.logoUrl,
    required this.score,
    required this.dim,
  });

  final String name;
  final Color color;
  final String? logoUrl;
  final String? score;
  final bool dim;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Crest(
            short: ckInitials(name),
            color: color,
            logoUrl: logoUrl,
            size: 26,
            radius: 7,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dim ? CkColors.muted : CkColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (score != null)
            Text(
              score!,
              style: CkType.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            )
          else if (dim)
            Text(
              'TO BAT',
              style: CkType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CkColors.soft,
              ),
            ),
        ],
      );
}

class _LiveDotPill extends StatefulWidget {
  const _LiveDotPill();

  @override
  State<_LiveDotPill> createState() => _LiveDotPillState();
}

class _LiveDotPillState extends State<_LiveDotPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: CkColors.red,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0.25).animate(_c),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'LIVE',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}
