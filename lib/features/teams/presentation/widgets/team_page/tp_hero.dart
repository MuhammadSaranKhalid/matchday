import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'tp_action_row.dart';
import 'tp_atoms.dart';
import 'tp_view.dart';

/// Full-bleed hero — primary-color background with cricket-ground motif,
/// status bar overlay, back/share/dots icons, crest tile + name + tagline,
/// optional badges row, optional W/L strip, action row.
///
/// Archived teams render in a muted brown to signal read-only.
class TpHero extends StatelessWidget {
  const TpHero({
    super.key,
    required this.team,
    required this.viewer,
    required this.badges,
    this.onBack,
  });

  final TpTeam team;
  final TeamPageViewer viewer;
  final List<TpHeroBadge> badges;
  final VoidCallback? onBack;

  Color get _heroColor =>
      team.archived != null ? const Color(0xFF6A6356) : team.primary;

  @override
  Widget build(BuildContext context) {
    final dim = team.archived != null;
    final color = _heroColor;
    return ColoredBox(
      color: color,
      child: Stack(
        children: [
          // Cricket-ground motif painted at the top-right corner.
          Positioned(
            right: -30,
            top: -10,
            child: Opacity(
              opacity: 0.10,
              child: CustomPaint(
                size: const Size(320, 200),
                painter: _PitchMotif(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TpStatusBar(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TpIconBtn(
                        icon: Icons.chevron_left,
                        onColor: true,
                        onTap: onBack,
                      ),
                      const Row(
                        children: [
                          TpIconBtn(
                              icon: Icons.ios_share, onColor: true),
                          SizedBox(width: 6),
                          TpIconBtn(
                              icon: Icons.more_horiz, onColor: true),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _Identity(team: team, heroColor: color, dim: dim),
                ),
                if (badges.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: _BadgesRow(badges: badges),
                  ),
                if (team.record != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: _RecordStrip(record: team.record!),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: TpActionRow(
                    viewer: viewer,
                    team: team,
                    heroColor: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity(
      {required this.team, required this.heroColor, required this.dim});
  final TpTeam team;
  final Color heroColor;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _HeroCrest(team: team, heroColor: heroColor),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${team.type.toUpperCase()} · '
                      '${team.area.toUpperCase()}, ${team.city.toUpperCase()}',
                      style: tpMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    if (team.verified && !dim) const TpVerifiedTick(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  team.name,
                  style: CkType.display(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
                if (team.tagline != null &&
                    team.tagline!.trim().isNotEmpty &&
                    !dim) ...[
                  const SizedBox(height: 6),
                  Text(
                    '“${team.tagline}”',
                    style: CkType.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.01,
                      color: Colors.white.withValues(alpha: 0.85),
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCrest extends StatelessWidget {
  const _HeroCrest({required this.team, required this.heroColor});
  final TpTeam team;
  final Color heroColor;

  Widget _mono() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          team.mono,
          style: CkType.display(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.04,
            color: heroColor,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final url = team.logoUrl;
    if (url == null || url.isEmpty) return _mono();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 72,
        height: 72,
        color: Colors.white,
        padding: const EdgeInsets.all(8),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _mono(),
          loadingBuilder: (ctx, child, p) => p == null ? child : _mono(),
        ),
      ),
    );
  }
}

class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.badges});
  final List<TpHeroBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final b in badges) _Badge(badge: b),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge});
  final TpHeroBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: badge.tone == TpHeroBadgeTone.red
            ? CkColors.red
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge.pulse) ...[
            const TpLivePulse(),
            const SizedBox(width: 5),
          ],
          Text(
            badge.label.toUpperCase(),
            style: tpMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordStrip extends StatelessWidget {
  const _RecordStrip({required this.record});
  final TpRecord record;

  @override
  Widget build(BuildContext context) {
    final cells = <(String, String)>[
      ('PLAYED', '${record.played}'),
      ('WON', '${record.won}'),
      ('LOST', '${record.lost}'),
      ('WIN %', '${record.winPct}'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(
                            left: BorderSide(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cells[i].$2,
                        style: CkType.display(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cells[i].$1,
                        style: tpMono(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PitchMotif extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: size.width * 0.95, height: size.height * 0.85),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: size.width * 0.55, height: size.height * 0.5),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: c, width: 16, height: 60),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
