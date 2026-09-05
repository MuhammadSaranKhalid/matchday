import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/util/surface_mode.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import 'tp_view.dart';

/// Mono / uppercase / letter-spaced label — the design's single most-used
/// text style. Centralised so the dozens of label rows stay consistent.
TextStyle tpMono({
  double fontSize = 10,
  FontWeight fontWeight = FontWeight.w600,
  Color color = CkColors.muted,
}) =>
    CkType.mono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.10,
      color: color,
    );

/// iOS-style 9:41 + signal + battery — painted over the hero so the chrome
/// shows up white-on-color. Positioned by the hero stack; no own SafeArea.
class TpStatusBar extends StatelessWidget {
  const TpStatusBar({super.key, this.color = Colors.white});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('9:41',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                )),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(17, 11),
                  painter: _SignalPainter(color: color),
                ),
                const SizedBox(width: 5),
                CustomPaint(
                  size: const Size(24, 11),
                  painter: _BatteryPainter(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalPainter extends CustomPainter {
  _SignalPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    void bar(double x, double y, double w, double h) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          const Radius.circular(0.6),
        ),
        paint,
      );
    }

    bar(0, 6.5, 2.8, 4.5);
    bar(4.5, 4.5, 2.8, 6.5);
    bar(9, 2.5, 2.8, 8.5);
    bar(13.5, 0, 2.8, 11);
  }

  @override
  bool shouldRepaint(_SignalPainter old) => old.color != color;
}

class _BatteryPainter extends CustomPainter {
  _BatteryPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.5, 0.5, 20, 10),
        const Radius.circular(3),
      ),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 2, 17, 7),
        const Radius.circular(1.5),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(_BatteryPainter old) => old.color != color;
}

/// Round chrome button — back / share / ⋯ on the hero.
///
/// `onColor` = glassy overlay on the hero; off → paper with a hairline.
///
/// 36px disc inside a 44px hit box. The visual size is unchanged from the
/// original design; only the touch target grew, by inseting the 44 box 4px
/// into itself so the row can be laid out at 10px padding and the disc still
/// lands on the hero's 14px optical margin. Adjacent hit boxes touch with no
/// gap — two 44s side by side leave exactly the 8px visual gap between discs
/// that the design already had, with no dead pixels between targets.
class TpIconBtn extends StatelessWidget {
  const TpIconBtn({
    super.key,
    required this.icon,
    this.onColor = false,
    this.onTap,
    this.size = 36,
    this.mode = CkSurfaceMode.paper,
    this.tooltip,
  });

  final IconData icon;

  /// Renders on a coloured hero rather than on paper.
  final bool onColor;

  final VoidCallback? onTap;

  /// Diameter of the visible disc. The hit box is always at least 44.
  final double size;

  /// Which ink ramp the hero is using. Ignored unless [onColor].
  final CkSurfaceMode mode;

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final ink = onColor && mode.isInk;
    final Color fill;
    final Color foreground;
    Border? border;

    if (!onColor) {
      fill = CkColors.paper;
      foreground = CkColors.ink;
      border = Border.all(color: CkColors.hairline);
    } else if (ink) {
      // On a pale primary an 8% ink fill alone cannot hold 3:1, so the disc
      // gains a hairline to read as a control.
      fill = CkColors.ink.withValues(alpha: 0.08);
      foreground = CkColors.ink;
      border = Border.all(color: CkColors.ink.withValues(alpha: 0.14));
    } else {
      fill = Colors.white.withValues(alpha: 0.16);
      foreground = Colors.white;
    }

    final hit = size < 44.0 ? 44.0 : size;
    final button = SizedBox(
      width: hit,
      height: hit,
      child: Center(
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: border,
            ),
            alignment: Alignment.center,
            // 18, not 16: Material at weight 400 goes thin against a mid-tone
            // primary, and the extra 2px costs no layout.
            child: Icon(icon, size: 18, color: foreground),
          ),
        ),
      ),
    );

    final tappable = Material(
      type: MaterialType.transparency,
      child: InkResponse(
        onTap: onTap,
        radius: hit / 2,
        containedInkWell: false,
        highlightColor: (onColor && !ink)
            ? Colors.white.withValues(alpha: 0.12)
            : CkColors.ink.withValues(alpha: 0.06),
        splashColor: Colors.transparent,
        child: button,
      ),
    );

    if (tooltip == null) return tappable;
    return Tooltip(message: tooltip!, child: tappable);
  }
}

/// Pulsing 5×5 dot — used by the LIVE pill + the "Playing now" badge.
class TpLivePulse extends StatefulWidget {
  const TpLivePulse({
    super.key,
    this.size = 5,
    this.color = Colors.white,
  });
  final double size;
  final Color color;

  @override
  State<TpLivePulse> createState() => _TpLivePulseState();
}

class _TpLivePulseState extends State<TpLivePulse>
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
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_c),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Small green check inside a 14×14 frosted circle — sits next to a verified
/// team's eyebrow on the hero.
class TpVerifiedTick extends StatelessWidget {
  const TpVerifiedTick({super.key, this.size = 10, this.color = Colors.white});
  final double size;

  /// Ink for the tick. Follows the hero's ramp — on a pale team primary the
  /// white tick on a white-alpha disc disappears entirely.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final box = size + 4;
    return Container(
      width: box,
      height: box,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.check_rounded,
        size: size,
        color: color,
      ),
    );
  }
}

/// Five-bar vertical sparkline used in [TpPlayerRowWidget]'s last-5 column.
/// Empty data renders as a muted em-dash so the row stays balanced.
class TpSparkline extends StatelessWidget {
  const TpSparkline({super.key, required this.values});
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Text(
        '—',
        style: tpMono(fontSize: 9, color: CkColors.muted),
      );
    }
    final max = values.fold<int>(1, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in values) ...[
            Container(
              width: 4,
              height: (v / max * 22).clamp(2, 22),
              decoration: BoxDecoration(
                color: v == 0 ? CkColors.hairline : CkColors.ink,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

/// Roster row — jersey tile (colored or dashed-outline if unclaimed), name +
/// role pill + YOU pill + UNCLAIMED pill, mono bat/bowl line, sparkline.
class TpPlayerRowWidget extends StatelessWidget {
  const TpPlayerRowWidget({
    super.key,
    required this.player,
    required this.primary,
    required this.isFirst,
    this.viewerPlayerId,
  });

  final TpPlayerRow player;
  final Color primary;
  final bool isFirst;
  final String? viewerPlayerId;

  bool get _isMe => viewerPlayerId != null && viewerPlayerId == player.id;
  bool get _isUnclaimed => player.status == TpPlayerStatus.unclaimed;

  String get _roleAbbr {
    switch (player.role) {
      case TpPlayerRole.captain:
        return 'C';
      case TpPlayerRole.viceCaptain:
        return 'VC';
      case TpPlayerRole.wicketKeeper:
        return 'WK';
      case TpPlayerRole.player:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUsername = player.username != null && player.username!.isNotEmpty;

    return InkWell(
      onTap: () {
        if (!_isUnclaimed && hasUsername) {
          context.push('/u/${player.username}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : const Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            Avatar(
              mono: player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              imageUrl: !_isUnclaimed ? player.photoUrl : null,
              size: 38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.display(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.01,
                          ),
                        ),
                      ),
                      if (_roleAbbr.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _SmallChip(
                          label: _roleAbbr,
                          bg: CkColors.cream,
                          fg: const Color(0xFF6B5414),
                        ),
                      ],
                      if (player.jersey > 0) ...[
                        const SizedBox(width: 6),
                        _SmallChip(
                          label: '#${player.jersey}',
                          bg: CkColors.paper2,
                          fg: CkColors.ink,
                          border: CkColors.hairline,
                        ),
                      ],
                      if (_isMe) ...[
                        const SizedBox(width: 6),
                        const _SmallChip(
                          label: 'YOU',
                          bg: CkColors.ink,
                          fg: CkColors.paper,
                        ),
                      ],
                      if (_isUnclaimed) ...[
                        const SizedBox(width: 6),
                        const _SmallChip(
                          label: 'UNCLAIMED',
                          bg: CkColors.paper2,
                          fg: CkColors.muted,
                          border: CkColors.hairline,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasUsername
                        ? '@${player.username}'
                        : (_isUnclaimed ? 'Offline squad player' : 'Squad member'),
                    style: CkType.body(
                      fontSize: 11.5,
                      color: hasUsername ? const Color(0xFF1E5A2C) : CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TpSparkline(values: player.last5),
          ],
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.bg,
    required this.fg,
    this.border,
  });
  final String label;
  final Color bg;
  final Color fg;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06,
          color: fg,
        ),
      ),
    );
  }
}

/// Section header — the mono uppercase label used everywhere ("Action queue ·
/// 3", "Top performers · this season", etc.). Optional trailing count.
class TpSectionHeader extends StatelessWidget {
  const TpSectionHeader({
    super.key,
    required this.label,
    this.count,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 8),
  });
  final String label;
  final int? count;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(label.toUpperCase(), style: tpMono()),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text('· $count', style: tpMono(color: CkColors.muted)),
          ],
        ],
      ),
    );
  }
}

/// Center-aligned empty-state with a small framed icon + headline + body.
/// Used by MatchesTab / StatsTab / private SquadTab.
class TpEmptyTile extends StatelessWidget {
  const TpEmptyTile({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.cta,
    this.onCtaTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? cta;
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: CkColors.hairline),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: CkColors.muted),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: CkType.display(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 12.5,
                color: CkColors.muted,
                height: 1.5,
              ),
            ),
          ),
          if (cta != null) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: onCtaTap,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  color: CkColors.ink,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  cta!,
                  style: CkType.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CkColors.paper,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Decides black or white text for a given background based on luminance.
Color tpOnColor(Color bg) =>
    bg.computeLuminance() > 0.55 ? CkColors.ink : CkColors.paper;
