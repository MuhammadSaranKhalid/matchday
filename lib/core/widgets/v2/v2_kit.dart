// v2 IA shared widget kit.
//
// Faithful Flutter port of the shared atoms from the design bundle's
// `screens/v2-IA.jsx` (matchday v2 prototype): Crest, Avatar, Pill, the
// universal header, the 5-tab bottom nav, and the per-post action bar.
//
// Colors / radii / type come from [CkColors] / [CkRadii] / [CkType]
// (lib/core/theme/circk_theme.dart) — the same tokens the prototype's
// styles.css declares. Icons are rendered as inline SVG via flutter_svg so the
// exact path data from the prototype reproduces 1:1.
//
// This is presentation-only chassis for the faithful UI rebuild; the prototype
// itself ships mock data and inert affordances, mirrored here.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/circk_theme.dart';

/// `Color` → `#RRGGBB` for embedding in raw SVG markup.
String ckHex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

/// Team crest colours from `v2-IA.jsx`'s `C` map (oklch → sRGB).
abstract final class CkCrest {
  static const ll = CkColors.red; // Lahore Lions — oklch(0.62 0.19 28)
  static const ke = Color(0xFF4264A8); // Karachi Eagles — oklch(0.55 0.15 250)
  static const mt = Color(0xFF6F5A45); // Multan Tigers — oklch(0.48 0.08 50)
  static const mk = CkColors.amber; // Mohalla Kings — oklch(0.78 0.14 80)
  static const sc = Color(0xFF6E2A22); // Spring Cup — oklch(0.36 0.10 28)
  static const kc = Color(0xFF2E3E63); // Karachi Cobras — oklch(0.42 0.10 260)
  static const ob = Color(0xFF4A4337); // Old Boys — oklch(0.36 0.04 80)
  static const dha = Color(0xFF2E3E63); // DHA United — oklch(0.42 0.10 260)
}

/// Darker "ink" text colours that sit on the soft accent backgrounds.
abstract final class CkInk {
  static const red = Color(0xFF8C2218); // on redSoft — oklch(0.42 0.16 28)
  static const green = Color(0xFF1E5A2C); // on greenSoft — oklch(0.34 0.12 148)
  static const amber = Color(0xFF6B5414); // on cream — oklch(0.42 0.12 80)
}

/// Inner SVG path data lifted verbatim from `v2-IA.jsx` (`ic` map + inline use).
abstract final class V2Icons {
  static const home =
      '<path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-7h-6v7H4a1 1 0 0 1-1-1v-9z"/>';
  static const matches =
      '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18a14 14 0 0 1 0-18"/>';
  static const pavilion =
      '<path d="M3 9l9-5 9 5v2H3z"/><path d="M5 11v9M9 11v9M15 11v9M19 11v9M3 20h18"/>';
  static const messages = '<path d="M4 5h16v11H8l-4 4z"/>';
  static const bell =
      '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>';
  static const plus = '<path d="M12 5v14M5 12h14"/>';
  static const search = '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4-4"/>';
  static const chevronRight = '<path d="M9 6l6 6-6 6"/>';
  static const chevronLeft = '<path d="M14 6l-6 6 6 6"/>';
  static const heart =
      '<path d="M20.8 8.3a5.5 5.5 0 0 0-9.3-3 5.5 5.5 0 0 0-9.3 6.3l8.4 8.7a1.3 1.3 0 0 0 1.8 0l8.4-8.7c1-1 1-2 0-3.3z"/>';
  static const comment = '<path d="M21 12a9 9 0 0 1-13 8L3 21l1-5A9 9 0 1 1 21 12z"/>';
  static const share = '<path d="M4 12l16-8-6 16-2-6-8-2z"/>';
  static const bookmark = '<path d="M6 4h12v17l-6-4-6 4z"/>';
  static const check = '<path d="M5 12l4 4 10-10"/>';
  static const pin =
      '<path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z"/>';
  static const dotsV =
      '<circle cx="12" cy="6" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="18" r="1"/>';
  static const close = '<path d="M6 6l12 12M18 6L6 18"/>';
  static const camera =
      '<rect x="3" y="6" width="18" height="14" rx="2"/><circle cx="12" cy="13" r="3"/>';
}

/// Renders an inline 24-viewBox SVG icon, either stroked (outline) or filled.
class V2Svg extends StatelessWidget {
  const V2Svg(
    this.paths, {
    super.key,
    this.size = 24,
    this.color = CkColors.ink,
    this.filled = false,
    this.strokeWidth = 1.8,
  });

  final String paths;
  final double size;
  final Color color;
  final bool filled;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final hex = ckHex(color);
    final fill = filled ? hex : 'none';
    final stroke = filled ? 'none' : hex;
    final sw = filled ? 0 : strokeWidth;
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" '
        'viewBox="0 0 24 24" fill="$fill" stroke="$stroke" stroke-width="$sw" '
        'stroke-linecap="round" stroke-linejoin="round">$paths</svg>';
    return SvgPicture.string(svg, width: size, height: size);
  }
}

/// Team crest — rounded square, white initials.
class Crest extends StatelessWidget {
  const Crest({
    super.key,
    required this.short,
    required this.color,
    this.size = 36,
    this.radius = 9,
  });

  final String short;
  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        short,
        style: CkType.display(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: CkColors.paper,
        ),
      ),
    );
  }
}

enum AvatarTone { paper, ink }

/// Circular initials avatar.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.mono,
    this.size = 36,
    this.tone = AvatarTone.paper,
  });

  final String mono;
  final double size;
  final AvatarTone tone;

  @override
  Widget build(BuildContext context) {
    final ink = tone == AvatarTone.ink;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ink ? CkColors.ink : CkColors.paper2,
        shape: BoxShape.circle,
        border: ink ? null : Border.all(color: CkColors.hairline),
      ),
      child: Text(
        mono,
        style: CkType.display(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: ink ? CkColors.paper : CkColors.ink2,
        ),
      ),
    );
  }
}

enum PillTone { red, redS, green, amber, ink, neutral }

/// Mono uppercase status pill (e.g. LIVE, MATCH ANNOUNCEMENT).
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.tone = PillTone.neutral});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.red => (CkColors.red, Colors.white),
      PillTone.redS => (CkColors.redSoft, const Color(0xFF8C2218)),
      PillTone.green => (CkColors.greenSoft, const Color(0xFF1E5A2C)),
      PillTone.amber => (CkColors.cream, const Color(0xFF6B5414)),
      PillTone.ink => (CkColors.ink, CkColors.paper),
      PillTone.neutral => (CkColors.paper2, CkColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: fg,
        ),
      ),
    );
  }
}

/// Universal top header: large title on the left, bell (→ notifications) right.
class V2Header extends StatelessWidget {
  const V2Header({
    super.key,
    required this.title,
    this.sub,
    this.notifCount = 3,
    this.onBell,
  });

  final String title;
  final String? sub;
  final int notifCount;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: CkType.display(fontSize: 26)),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      sub!,
                      style: CkType.body(fontSize: 12, color: CkColors.muted),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _BellButton(count: notifCount, onTap: onBell),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.count, this.onTap});
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper,
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.hairline),
              ),
              child: const V2Svg(V2Icons.bell, size: 18, color: CkColors.ink),
            ),
            if (count > 0)
              Positioned(
                top: 0,
                right: 0,
                child: _Badge(text: count > 9 ? '9+' : '$count'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CkColors.red,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CkColors.paper, width: 1.5),
      ),
      child: Text(
        text,
        style: CkType.display(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: CkColors.paper,
        ),
      ),
    );
  }
}

/// The five v2 bottom-nav destinations.
enum V2Tab { home, matches, pavilion, messages, profile }

/// 5-tab bottom navigation — Home · Matches · Pavilion · Messages · You.
/// Equal-weight tabs (Apple HIG): filled icon + ink when active, stroked +
/// muted otherwise. The "You" tab is the avatar; Messages carries a count.
class V2BottomNav extends StatelessWidget {
  const V2BottomNav({
    super.key,
    required this.active,
    required this.onSelect,
    this.avatarMono = 'BA',
    this.messagesBadge = 2,
  });

  final V2Tab active;
  final ValueChanged<V2Tab> onSelect;
  final String avatarMono;
  final int messagesBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _navItem(V2Tab.home, 'Home', V2Icons.home),
            _navItem(V2Tab.matches, 'Matches', V2Icons.matches),
            _navItem(V2Tab.pavilion, 'Pavilion', V2Icons.pavilion),
            _navItem(V2Tab.messages, 'Messages', V2Icons.messages,
                badge: messagesBadge),
            _navItem(V2Tab.profile, 'You', null),
          ],
        ),
      ),
    );
  }

  Widget _navItem(V2Tab id, String label, String? icon, {int? badge}) {
    final isActive = id == active;
    final color = isActive ? CkColors.ink : CkColors.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(id),
      child: Container(
        constraints: const BoxConstraints(minWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (icon == null)
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: CkColors.ink,
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(color: CkColors.ink, width: 2)
                            : null,
                      ),
                      foregroundDecoration: isActive
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CkColors.paper,
                                width: 2,
                              ),
                            )
                          : null,
                      child: Text(
                        avatarMono,
                        style: CkType.display(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: CkColors.paper,
                        ),
                      ),
                    )
                  else
                    V2Svg(icon, size: 24, color: color, filled: isActive),
                  if (badge != null && badge > 0)
                    Positioned(
                      top: -3,
                      right: -8,
                      child: _Badge(text: '$badge'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: CkType.body(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.05,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-post action bar — Like · Comment · Share, optional RSVP text, Save.
class PostActions extends StatefulWidget {
  const PostActions({
    super.key,
    required this.likes,
    required this.comments,
    this.liked = false,
    this.rsvp,
    this.onComment,
  });

  final int likes;
  final int comments;
  final bool liked;
  final String? rsvp;
  final VoidCallback? onComment;

  @override
  State<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends State<PostActions> {
  late bool _liked = widget.liked;
  late int _likes = widget.likes;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    // The JSX nudges the bar out by -4px to align the first icon's internal
    // padding to the edge; Container margins can't be negative, so we just pad
    // the top (the 6px of icon left-padding is a negligible inset).
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          _action(
            icon: V2Icons.heart,
            label: '$_likes',
            filled: _liked,
            color: _liked ? CkColors.red : CkColors.ink2,
            onTap: () => setState(() {
              _liked = !_liked;
              _likes += _liked ? 1 : -1;
            }),
          ),
          _action(
            icon: V2Icons.comment,
            label: '${widget.comments}',
            color: CkColors.ink2,
            onTap: widget.onComment,
          ),
          _action(
            icon: V2Icons.share,
            label: 'Share',
            color: CkColors.ink2,
            onTap: () {},
          ),
          // The RSVP text takes the remaining space and right-aligns next to
          // Save, ellipsizing on narrow screens rather than overflowing.
          if (widget.rsvp != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 6),
                child: Text(
                  widget.rsvp!,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                ),
              ),
            )
          else
            const Spacer(),
          _action(
            icon: V2Icons.bookmark,
            label: null,
            filled: _saved,
            color: _saved ? CkColors.ink : CkColors.ink2,
            onTap: () => setState(() => _saved = !_saved),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required String icon,
    required String? label,
    required Color color,
    bool filled = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            V2Svg(icon, size: 19, color: color, filled: filled),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: CkType.body(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard scrolling screen body padding token used across v2 feeds.
const kFeedHairline = BorderSide(color: CkColors.hairline);
