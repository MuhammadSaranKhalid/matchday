import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../providers/matches_feed_providers.dart';
import 'pool_icons.dart';

/// One open challenge on the Pool board — `Pool.dc.html` artboard 01.
///
/// The card states the fixture and nothing else. Per the design's redundancy
/// pass it carries no kicker and no green "Open" pill: the section header
/// above already says these are open, so a per-card repeat is noise. The only
/// status ink it spends is the expiry dot.
///
/// Meta and footer are conditional. A host who left the time, ground or expiry
/// unset gets the short card from artboard 01's third row rather than a card
/// padded out with em-dashes.
class PoolChallengeCard extends StatelessWidget {
  const PoolChallengeCard({
    super.key,
    required this.item,
    this.onTap,
    this.dimmed = false,
  });

  final OpenMatchPoolItem item;
  final VoidCallback? onTap;

  /// Artboard 05 shows the board behind the no-team gate at 55% — readable,
  /// plainly not actionable.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final team = item.fromTeam;
    final start = item.startTime;
    final ground = item.ground;
    final hasMeta = start != null || ground != null;
    final expiry = _expiry(item.expiresAt);

    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titleRow(team),
          const SizedBox(height: 11),
          Text(
            item.formatLine.toUpperCase(),
            style: CkType.mono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.04,
              color: CkColors.ink,
            ),
          ),
          if (hasMeta) ...[
            const SizedBox(height: 11),
            if (start != null)
              _metaRow(
                PoolIcons.clock,
                Text(
                  poolStartLabel(start),
                  style: CkType.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                    letterSpacing: -0.01,
                  ),
                ),
              ),
            if (start != null && ground != null) const SizedBox(height: 6),
            if (ground != null)
              _metaRow(
                PoolIcons.pin,
                Text(
                  ground,
                  style: CkType.body(fontSize: 13, color: CkColors.ink2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          if (expiry != null) ...[
            const SizedBox(height: 11),
            const Divider(height: 1, thickness: 1, color: CkColors.hairline),
            const SizedBox(height: 11),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: expiry.urgent ? CkColors.amber : CkColors.soft,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Expires in ${expiry.label}'.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color:
                        expiry.urgent ? CkColors.amberInk : CkColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (dimmed) return Opacity(opacity: 0.55, child: card);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }

  Widget _titleRow(Team? team) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Crest(
          short: teamMonogram(team),
          color: teamCrestColor(team),
          logoUrl: team?.logoUrl,
          size: 42,
          radius: 12,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    team?.name ?? 'Open challenger',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
                      letterSpacing: -0.01,
                    ),
                  ),
                ),
                if (team?.isVerified ?? false) ...[
                  const SizedBox(width: 6),
                  const PoolIcon(PoolIcons.verified, size: 13),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaRow(String icon, Widget label) {
    return Row(
      children: [
        PoolIcon(icon, size: 14),
        const SizedBox(width: 8),
        Expanded(child: label),
      ],
    );
  }
}

// ─── Shared card helpers ──────────────────────────────────────────────────

/// Crest monogram: the team's override, else initials of the first two words,
/// else the first two letters. "TM" only when there is no team at all.
String teamMonogram(Team? team) {
  if (team == null) return 'TM';
  final override = team.logoMonogram?.trim();
  if (override != null && override.isNotEmpty) return override.toUpperCase();

  final words =
      team.name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  if (words.isEmpty) return 'TM';
  final one = words.first;
  return (one.length >= 2 ? one.substring(0, 2) : one).toUpperCase();
}

/// Crest ground colour from the team's stored hex, falling back to ink so an
/// unstyled team still reads as a crest rather than a red alert.
Color teamCrestColor(Team? team) {
  final hex = team?.primaryColor?.replaceAll('#', '');
  if (hex == null || hex.isEmpty) return CkColors.ink;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return CkColors.ink;
  return Color(0xFF000000 | value);
}

/// "Today · 4:30 PM", "Tomorrow · 9:00 AM", else "Sat, Sep 6 · 9:00 AM".
///
/// Shared with the host's own surfaces so a challenge reads identically on
/// the public board and on the list of the challenges you posted.
String poolStartLabel(DateTime dt) {
  final now = DateTime.now();
  final day = DateTime(dt.year, dt.month, dt.day);
  final today = DateTime(now.year, now.month, now.day);
  final delta = day.difference(today).inDays;

  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final time = '$hour:$minute ${dt.hour >= 12 ? 'PM' : 'AM'}';

  if (delta == 0) return 'Today · $time';
  if (delta == 1) return 'Tomorrow · $time';

  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day} · $time';
}

class _Expiry {
  const _Expiry(this.label, {required this.urgent});
  final String label;
  final bool urgent;
}

/// "41h" / "2d" / "38m". Amber under 48 hours, soft grey beyond — the split
/// artboard 01 draws between its 41h and 2d cards. An already-lapsed
/// challenge returns null: it should not be on the board at all, and a
/// negative countdown is worse than a missing one.
_Expiry? _expiry(DateTime? expiresAt) {
  if (expiresAt == null) return null;
  final left = expiresAt.difference(DateTime.now());
  if (left.isNegative) return null;

  if (left.inHours < 1) {
    return _Expiry('${left.inMinutes}m', urgent: true);
  }
  if (left.inHours < 48) {
    return _Expiry('${left.inHours}h', urgent: true);
  }
  return _Expiry('${left.inDays}d', urgent: false);
}
