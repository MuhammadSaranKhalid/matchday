import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';

/// The uppercase mono section label used above every Explore group and
/// section ("TEAMS · 2", "LIVE NOW"). Mirrors the design system's
/// `.ck-section-h`: 11px / 600 / uppercase / +0.10em / muted.
class ExploreSectionHeader extends StatelessWidget {
  const ExploreSectionHeader({
    super.key,
    required this.label,
    this.count,
    this.trailingLabel,
    this.onTrailingTap,
    this.trailingColor = CkColors.ink,
    this.subtitle,
  });

  final String label;

  /// Rendered as "· 2" after the label. Null hides it.
  final int? count;

  /// e.g. "See all ›". Only rendered when [onTrailingTap] is also provided.
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  /// Ink for "See all ›"; red for a destructive "Clear all".
  final Color trailingColor;

  /// Optional italic explainer beneath, for honest degradation messages.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = count == null ? label : '$label · $count';
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, subtitle == null ? 2 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  text.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.10,
                    color: CkColors.muted,
                  ),
                ),
              ),
              if (trailingLabel != null && onTrailingTap != null)
                GestureDetector(
                  onTap: onTrailingTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    // Widen the tap target without moving the text.
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Text(
                      trailingLabel!.toUpperCase(),
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.06,
                        color: trailingColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: CkType.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: CkColors.soft,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}

/// A name with the matched substring highlighted on Seam Cream, per the
/// design's result rows.
///
/// Case-insensitive, first occurrence only — highlighting every occurrence
/// makes long names look striped, and the first hit is what the user's eye
/// is already checking.
class HighlightedName extends StatelessWidget {
  const HighlightedName({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    this.maxLines = 1,
  });

  final String text;
  final String query;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    final idx = q.isEmpty
        ? -1
        : text.toLowerCase().indexOf(q.toLowerCase());

    if (idx < 0) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final end = idx + q.length;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, end),
            style: const TextStyle(
              backgroundColor: CkColors.cream,
            ),
          ),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// The small cream check that marks a verified team or player.
class VerifiedTick extends StatelessWidget {
  const VerifiedTick({super.key, this.size = 13});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: CkColors.cream,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: size * 0.7, color: CkColors.ink),
      );
}

/// The mono meta sub-line under a result's name.
class ExploreMetaLine extends StatelessWidget {
  const ExploreMetaLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
          color: CkColors.muted,
        ),
      );
}

/// A shimmering placeholder block — the design's `mdshim` sweep.
class ShimmerBlock extends StatefulWidget {
  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = 4,
    this.circle = false,
  });

  final double width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.circle
                ? null
                : BorderRadius.circular(widget.radius),
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              // Sweep left→right across a band four times the block's width,
              // so the highlight reads as a moving sheen rather than a fade.
              begin: Alignment(-1 - 2 * (1 - _c.value), 0),
              end: Alignment(1 + 2 * _c.value, 0),
              colors: const [
                CkColors.paper2,
                CkColors.hairline,
                CkColors.paper2,
              ],
              stops: const [0.25, 0.37, 0.63],
            ),
          ),
        ),
      );
}

/// The signature "ruled ledger" row: a 1px hairline top border, edge to edge,
/// no card and no shadow. Every Explore list row is built on this.
class RuledRow extends StatelessWidget {
  const RuledRow({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
              child: child,
            ),
          ),
        ),
      );
}

/// The single "incoming result" row appended below retained results while a
/// new query is in flight (artboard 06) — a shimmering avatar and two text
/// bars, signalling that more is arriving without blanking what is there.
class ExploreIncomingRow extends StatelessWidget {
  const ExploreIncomingRow({super.key, this.circle = true});

  final bool circle;

  @override
  Widget build(BuildContext context) => RuledRow(
        child: Row(
          children: [
            ShimmerBlock(
              width: 40,
              height: 40,
              circle: circle,
              radius: 9,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: 180, height: 12),
                  SizedBox(height: 7),
                  ShimmerBlock(width: 110, height: 9),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Derives up to two initials for a monogram. Shared so a team crest and a
/// player avatar never disagree about the same name.
String ckInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final w = words.first;
    return (w.length == 1 ? w : w.substring(0, 2)).toUpperCase();
  }
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

/// Parses a `#RRGGBB` / `RRGGBB` team colour, falling back to ink when the
/// value is absent or malformed — a bad colour string must never crash a row.
Color ckParseColor(String? raw, {Color fallback = CkColors.ink2}) {
  if (raw == null) return fallback;
  var hex = raw.trim().replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return fallback;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? fallback : Color(value);
}
