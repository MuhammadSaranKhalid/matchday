import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/util/initials.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

// Shared tap-to-pick lineup widgets, used by BOTH the first-innings Match Start
// flow (match_start_screen.dart · _Stage2Lineup) and the second-innings setup
// (innings_break_screen.dart) so the player-selection UX is identical across
// innings. Purely presentational — no Riverpod, no domain types.

/// A single on-field slot (ON STRIKE / NON-STRIKER / BOWLER). [hot] paints the
/// striker slot red once filled.
class LineupSlotCard extends StatelessWidget {
  const LineupSlotCard({
    super.key,
    required this.label,
    this.value,
    this.hot = false,
  });

  final String label;
  final String? value;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    final filled = value != null;
    final border =
        hot && filled
            ? CkColors.red
            : filled
            ? CkColors.ink
            : CkColors.hairline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hot && filled ? CkColors.redSoft : CkColors.paper,
        border: Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: hot && filled ? CkColors.red : CkColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? '— tap below —',
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: filled ? CkColors.ink : CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable roster row. The leading element is the player's avatar (their
/// monogram when they have no photo); [badge] shows the assigned slot
/// (STR / NS / BWL) as a pill beside the name.
///
/// The badge used to occupy the leading position, which meant every
/// unassigned player — most of the list — led with an empty grey square.
class LineupRosterRow extends StatelessWidget {
  const LineupRosterRow({
    super.key,
    required this.name,
    required this.onTap,
    this.photoUrl,
    this.jersey,
    this.badge,
  });

  final String name;
  final VoidCallback onTap;

  /// Avatar URL, or null to render the monogram.
  final String? photoUrl;

  final int? jersey;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: badge != null ? CkColors.paper2 : CkColors.paper,
          border: const Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            Avatar(mono: personInitials(name), imageUrl: photoUrl, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: CkType.display(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      badge == 'STR'
                          ? CkColors.red
                          : badge == 'NS'
                          ? CkColors.ink
                          : _bowlerBadge,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.paper,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (jersey != null)
              Text(
                '#$jersey',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.04,
                  color: CkColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _bowlerBadge = Color(
  0xFF1A6A2E,
); // green, matches the scoring bowler chip
