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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../theme/circk_theme.dart';
import '../../../features/messages/presentation/providers/messages_providers.dart';
import '../../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../../features/onboarding/presentation/providers/onboarding_providers.dart';

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
  // Bottom-nav icons — match `matchday-challenge/Bottom Nav Options.html`.
  // home  : roof + walls + door (cleaner than the old single-path house).
  // matches: bat + ball (was a globe; the brief was explicit about a sport-
  //          coded glyph for a cricket app).
  // pavilion: shield with an inner star, on-brand for the "club" frame.
  // messages: speech bubble with right-edge tail.
  static const home =
      '<path d="M4 11l8-7 8 7"/>'
      '<path d="M6 9.5V20h12V9.5"/>'
      '<path d="M10 20v-5h4v5"/>';
  static const matches =
      '<path d="M14.5 4.5a2 2 0 0 1 2.9 2.9l-8 8-2.9-2.9z"/>'
      '<path d="M6.5 12.5 4 15l1.5 1.5L8 14"/>'
      '<circle cx="17.5" cy="17.5" r="2.5"/>';
  static const pavilion =
      '<path d="M12 3l7 3v5c0 4.2-3 7.4-7 8.5C8 18.4 5 15.2 5 11V6z"/>'
      '<path d="M12 8.4l1 2.1 2.3.3-1.7 1.6.4 2.3-2-1.1-2 1.1.4-2.3-1.7-1.6 2.3-.3z" stroke-width="1.4"/>';
  static const messages =
      '<path d="M20 14a2 2 0 0 1-2 2H8l-4 3V6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2z"/>';
  static const bell =
      '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>';
  static const plus = '<path d="M12 5v14M5 12h14"/>';
  static const search = '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4-4"/>';
  static const chevronRight = '<path d="M9 6l6 6-6 6"/>';
  static const chevronLeft = '<path d="M14 6l-6 6 6 6"/>';
  static const heart =
      '<path d="M20.8 8.3a5.5 5.5 0 0 0-9.3-3 5.5 5.5 0 0 0-9.3 6.3l8.4 8.7a1.3 1.3 0 0 0 1.8 0l8.4-8.7c1-1 1-2 0-3.3z"/>';
  static const comment = '<path d="M21 12a9 9 0 0 1-13 8L3 21l1-5A9 9 0 1 1 21 12z"/>';
  // The recognisable 3-node share glyph from the prototype (`P.share` in
  // home-messages.jsx). Replaces the prior paper-plane "send" path — the
  // design handoff README explicitly calls for the 3-node graph.
  static const share =
      '<circle cx="18" cy="5" r="3"/>'
      '<circle cx="6" cy="12" r="3"/>'
      '<circle cx="18" cy="19" r="3"/>'
      '<path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4"/>';
  // Horizontal three-dots — used by post-card overflow `···` buttons.
  static const dotsH =
      '<circle cx="5" cy="12" r="1.5"/>'
      '<circle cx="12" cy="12" r="1.5"/>'
      '<circle cx="19" cy="12" r="1.5"/>';
  // Chain-link, used by Copy link rows in share / overflow sheets.
  static const link =
      '<path d="M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1"/>'
      '<path d="M14 11a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1"/>';
  // Flag, used for Report rows.
  static const flag = '<path d="M4 22V4M4 4h13l-2 4 2 4H4"/>';
  // WhatsApp speech bubble (used as the WhatsApp-first share row).
  static const whatsapp =
      '<path d="M12 3a9 9 0 0 0-7.7 13.6L3 21l4.5-1.2A9 9 0 1 0 12 3z"/>'
      '<path d="M8.5 8.5c-.3 1.2.3 2.6 1.4 3.7s2.5 1.7 3.7 1.4c.5-.1.7-.7.5-1.1l-.5-.9a.7.7 0 0 0-.8-.3l-.8.3-1.8-1.8.3-.8a.7.7 0 0 0-.3-.8l-.9-.5c-.4-.2-1 0-1.1.5z"/>';
  static const bookmark = '<path d="M6 4h12v17l-6-4-6 4z"/>';
  static const check = '<path d="M5 12l4 4 10-10"/>';
  static const pin =
      '<path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z"/>';
  static const dotsV =
      '<circle cx="12" cy="6" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="18" r="1"/>';
  static const close = '<path d="M6 6l12 12M18 6L6 18"/>';
  static const camera =
      '<rect x="3" y="6" width="18" height="14" rx="2"/><circle cx="12" cy="13" r="3"/>';
  // Menu drawer icons — ported verbatim from the design prototype's PATHS map
  // (matchday Prototype.html). Used by features/menu/.../menu_screen.dart so
  // each row gets its intended glyph instead of re-using the pavilion shield.
  static const trophy =
      '<path d="M7 4h10v4a5 5 0 0 1-10 0z"/>'
      '<path d="M7 5H4v2a3 3 0 0 0 3 3M17 5h3v2a3 3 0 0 1-3 3"/>'
      '<path d="M12 13v4M9 21h6M10 17h4"/>';
  static const rankings = '<path d="M5 21V10M12 21V4M19 21v-7"/>';
  static const lock =
      '<rect x="4" y="10" width="16" height="11" rx="2"/>'
      '<path d="M8 10V7a4 4 0 0 1 8 0v3"/>';
  static const theme =
      '<circle cx="12" cy="12" r="4"/>'
      '<path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4'
      'M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>';
  static const globe =
      '<circle cx="12" cy="12" r="9"/>'
      '<path d="M3 12h18M12 3c2.5 2.5 2.5 15 0 18M12 3c-2.5 2.5-2.5 15 0 18"/>';
  static const follow =
      '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>'
      '<circle cx="9" cy="7" r="4"/>'
      '<path d="M19 8v6M22 11h-6"/>';
  static const logout =
      '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>';
  static const user =
      '<circle cx="12" cy="8" r="4"/>'
      '<path d="M4 21v-1a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v1"/>';
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

/// Team crest — rounded square. Renders the uploaded [logoUrl] when set,
/// otherwise the team's monogram on its primary [color]. Errors / loading
/// fall back to the monogram tile so the crest never goes blank.
class Crest extends StatelessWidget {
  const Crest({
    super.key,
    required this.short,
    required this.color,
    this.logoUrl,
    this.size = 36,
    this.radius = 9,
  });

  final String short;
  final Color color;
  final String? logoUrl;
  final double size;
  final double radius;

  Widget _monoTile() => Container(
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

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.isEmpty) return _monoTile();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: CkColors.paper2,
        child: Image.network(
          logoUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _monoTile(),
          loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : _monoTile(),
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

/// Universal top header: large title on the left; bell (→ notifications) and
/// the signed-in user's avatar (→ `/profile`) on the right.
///
/// The avatar replaces the removed Profile tab (D9 in
/// docs/search-feature-design.md — nav is Home · Search · Matches · Messages ·
/// Pavilion). Pass [showAvatar] = false for headers where it doesn't belong.
///
/// The bell badge auto-reads the unread notifications count via the
/// `unreadNotificationsCountProvider` if no explicit [notifCount] is passed.
/// Callers can still override (e.g. in widget tests).
class V2Header extends ConsumerWidget {
  const V2Header({
    super.key,
    required this.title,
    this.sub,
    this.notifCount,
    this.onBell,
    this.refreshing = false,
    this.showAvatar = true,
  });

  final String title;
  final String? sub;
  final int? notifCount;
  final VoidCallback? onBell;

  /// Whether to render the own-profile avatar button on the right.
  final bool showAvatar;

  /// When true AND [sub] is null, a subtle inline spinner renders below the
  /// title in the sub's slot. Used by screens that paint from a local cache
  /// while a network refresh is in flight (ticket #23). Ignored when [sub]
  /// is non-null — the explicit subtitle takes precedence.
  final bool refreshing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count =
        notifCount ?? ref.watch(unreadNotificationsCountProvider);
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
                  )
                else if (refreshing)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.2,
                        color: CkColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _BellButton(count: count, onTap: onBell),
          if (showAvatar) ...[
            const SizedBox(width: 8),
            const _HeaderAvatar(),
          ],
        ],
      ),
    );
  }
}

/// Header avatar — the signed-in user's photo (or initials fallback); tapping
/// opens the own-profile screen, full-screen over the shell. Replaces the
/// removed Profile tab (D9, docs/search-feature-design.md).
class _HeaderAvatar extends ConsumerWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final name = profile?.displayName ?? profile?.username ?? '';
    final url = profile?.avatarUrl;
    final mono = _initialsOf(name);
    final Widget face = (url == null || url.isEmpty)
        ? Avatar(mono: mono, size: 36)
        : ClipOval(
            child: Container(
              width: 36,
              height: 36,
              color: CkColors.paper2,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Avatar(mono: mono, size: 36),
              ),
            ),
          );
    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: face,
    );
  }
}

/// "Muhammad Saran" → "MS"; single word → first letter; empty → "·".
String _initialsOf(String name) {
  final t = name.trim();
  if (t.isEmpty) return '·';
  final parts = t.split(RegExp(r'\s+'));
  final b = StringBuffer(parts.first[0]);
  if (parts.length > 1) b.write(parts[1][0]);
  return b.toString().toUpperCase();
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

/// The three matchday bottom-nav destinations. Order = bar order from the
/// design handoff prototype (`design_handoff_matchday/`): Home · Matches ·
/// Alerts. Search, Messages and Profile/Pavilion are reached via the
/// [GlobalHeader] (search pill, messages bubble, avatar → Menu drawer) — not
/// from the bottom bar.
enum V2Tab { home, matches, alerts }

/// 3-tab bottom navigation — Home · Matches · Alerts.
///
/// Same "Option B · Filled square tile" treatment as before (inactive = soft
/// outline glyph, active = white glyph reversed inside a red rounded-square
/// tile). The Alerts tab carries a numeric red unread badge driven by
/// [unreadNotificationsCountProvider]; an explicit [alertsBadge] override is
/// available for tests / mocks.
///
/// Tokens taken verbatim from the design CSS:
///   bar bg          surface (#fff)            hairline border top
///   tile (active)   40×32  radius 11  red bg  21px white glyph
///   tile (inactive) 40×32  transparent        23px soft glyph
///   label          9.5px Inter  600 → 700     muted → ink on active
///   tab gap (glyph→label) 5px   tab vertical padding 4px
class V2BottomNav extends ConsumerWidget {
  const V2BottomNav({
    super.key,
    required this.active,
    required this.onSelect,
    this.alertsBadge,
  });

  final V2Tab active;
  final ValueChanged<V2Tab> onSelect;

  /// Override the unread count rendered on the Alerts tab. When null, the
  /// widget reads it from [unreadNotificationsCountProvider].
  final int? alertsBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int badge =
        alertsBadge ?? ref.watch(unreadNotificationsCountProvider);
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.surface,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _navItem(V2Tab.home, 'Home', V2Icons.home),
            _navItem(V2Tab.matches, 'Matches', V2Icons.matches),
            _navItem(V2Tab.alerts, 'Alerts', V2Icons.bell,
                badge: badge > 0 ? badge : null),
          ],
        ),
      ),
    );
  }

  Widget _navItem(V2Tab id, String label, String icon, {int? badge}) {
    final isActive = id == active;

    // Icon tabs: 40×32 rounded tile. Tile fill swaps transparent → red on
    // active; SVG inside resizes 23 → 21 and swaps soft → white.
    final Widget glyph = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 40,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? CkColors.red : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
      ),
      child: V2Svg(
        icon,
        size: isActive ? 21 : 23,
        color: isActive ? CkColors.surface : CkColors.soft,
        strokeWidth: 2.0,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  glyph,
                  if (badge != null && badge > 0)
                    Positioned(
                      top: -2,
                      right: 0,
                      child: _Badge(text: '$badge'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: CkType.body(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.01,
                color: isActive ? CkColors.ink : CkColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-post action bar — Like (count) · Comment · Share. Mirrors the
/// prototype's `PostActions` in home-messages.jsx: three actions, no top
/// border, no save/bookmark, no repost; share is the 3-node graph glyph and
/// is right-aligned with no label.
class PostActions extends StatefulWidget {
  const PostActions({
    super.key,
    required this.likes,
    required this.comments,
    this.liked = false,
    this.onComment,
    this.onShare,
  });

  final int likes;
  final int comments;
  final bool liked;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  State<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends State<PostActions> {
  late bool _liked = widget.liked;
  late int _likes = widget.likes;

  @override
  void didUpdateWidget(covariant PostActions old) {
    super.didUpdateWidget(old);
    if (old.likes != widget.likes) _likes = widget.likes;
    if (old.liked != widget.liked) _liked = widget.liked;
  }

  @override
  Widget build(BuildContext context) {
    // Prototype offsets the bar by -8px to line the first glyph's internal
    // padding up with the card edge; Padding handles the same effect here.
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          _action(
            icon: V2Icons.heart,
            label: '$_likes',
            filled: _liked,
            color: _liked ? CkColors.red : CkColors.muted,
            onTap: () => setState(() {
              _liked = !_liked;
              _likes += _liked ? 1 : -1;
            }),
          ),
          _action(
            icon: V2Icons.comment,
            label: null,
            color: CkColors.muted,
            onTap: widget.onComment,
          ),
          const Spacer(),
          _action(
            icon: V2Icons.share,
            label: null,
            color: CkColors.muted,
            onTap: widget.onShare,
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
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            V2Svg(icon, size: 18, color: color, filled: filled),
            if (label != null) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: CkType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
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

// ─── matchday IA additions ───────────────────────────────────────────────
// New atoms + GlobalHeader added for the design_handoff_matchday pivot.
// Existing V2Header / V2BottomNav above are still used by screens that
// haven't been restyled yet.

/// Ports the prototype's `.ck-ball` log-pill variants — one circle per ball
/// in the live commentary strip.
enum BallKind { dot, runs, four, six, wkt, extra }

class BallPill extends StatelessWidget {
  const BallPill({super.key, required this.kind, this.label});

  final BallKind kind;

  /// Centre label. Optional for [BallKind.dot] (defaults to "·") and
  /// [BallKind.wkt] (defaults to "W"); required for [BallKind.runs] /
  /// [BallKind.extra].
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (kind) {
      BallKind.dot => (CkColors.paper2, CkColors.muted, CkColors.hairline),
      BallKind.runs => (CkColors.paper2, CkColors.ink, CkColors.hairline),
      BallKind.four =>
        (CkColors.greenSoft, const Color(0xFF1E5A2C), Colors.transparent),
      BallKind.six => (CkColors.ink, CkColors.paper, Colors.transparent),
      BallKind.wkt => (CkColors.red, Colors.white, Colors.transparent),
      BallKind.extra => (CkColors.cream, CkColors.ink2, Colors.transparent),
    };
    final text = label ??
        switch (kind) {
          BallKind.dot => '·',
          BallKind.wkt => 'W',
          _ => '',
        };
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        text,
        style: CkType.display(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: fg,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

/// Ports the prototype's `.ck-chip.live` — red pill with a pulsing white dot.
/// Used on live-match cards and the watch screen's LIVE hero.
class LiveChip extends StatefulWidget {
  const LiveChip({super.key, this.label = 'LIVE', this.compact = false});

  final String label;

  /// Tighter padding for use inside dense cards.
  final bool compact;

  @override
  State<LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<LiveChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  late final Animation<double> _opacity =
      Tween<double>(begin: 1.0, end: 0.35).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padH = widget.compact ? 7.0 : 9.0;
    final padV = widget.compact ? 3.0 : 5.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: const BoxDecoration(
        color: CkColors.red,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: CkType.body(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.06 * 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ports the prototype's `.ck-section-h` — uppercase muted small caps used as
/// section dividers ("MY TEAMS", "FRIENDLIES", etc.).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: CkType.body(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.10 * 11,
        color: CkColors.muted,
      ),
    );
  }
}

/// Ports the prototype's `.ck-placeholder` — 135° diagonal stripe pattern for
/// empty slots (unclaimed player tiles, etc.).
class StripePlaceholder extends StatelessWidget {
  const StripePlaceholder({
    super.key,
    this.borderRadius,
    this.child,
  });

  final BorderRadius? borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CustomPaint(
        painter: const _StripePainter(),
        child: child,
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = CkColors.paper;
    canvas.drawRect(Offset.zero & size, base);
    final stripe = Paint()..color = CkColors.paper2;
    const step = 16.0;
    const w = 8.0;
    final diag = size.width + size.height;
    for (double i = -diag; i < diag; i += step) {
      final p = Path()
        ..moveTo(i, 0)
        ..lineTo(i + w, 0)
        ..lineTo(i + w + size.height, size.height)
        ..lineTo(i + size.height, size.height)
        ..close();
      canvas.drawPath(p, stripe);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Universal top header from the design handoff prototype: 38px round ink
/// avatar on the left (taps → Menu drawer at `/menu`), full-width Search pill
/// in the middle (taps → `/search`), Messages bubble on the right with a red
/// unread badge (taps → `/messages`). Rendered at the top of every primary
/// tab in the matchday IA shell.
///
/// Initials are read from [myProfileProvider]; the messages badge is the sum
/// of unread counts across the inbox. Both can be overridden for tests via
/// [overrideInitials] / [overrideMessagesBadge].
class GlobalHeader extends ConsumerWidget {
  const GlobalHeader({
    super.key,
    this.onMenu,
    this.onSearch,
    this.onMessages,
    this.overrideInitials,
    this.overrideMessagesBadge,
  });

  /// Overrides the default `context.push('/menu')` behaviour.
  final VoidCallback? onMenu;

  /// Overrides the default `context.push('/search')` behaviour.
  final VoidCallback? onSearch;

  /// Overrides the default `context.push('/messages')` behaviour.
  final VoidCallback? onMessages;

  final String? overrideInitials;
  final int? overrideMessagesBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final name = profile?.displayName ?? profile?.username ?? '';
    final initials = overrideInitials ?? _initialsOf(name);
    final chats = ref.watch(myChatsProvider).value ?? const [];
    final badge = overrideMessagesBadge ??
        chats.fold<int>(0, (sum, c) => sum + c.unreadCount);

    return Padding(
      // Spec from prototype: 6/14/10 padding under the 44px safe-area spacer
      // (SafeArea handles the top inset for us, so we drop the static 44).
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Row(
        children: [
          _AvatarButton(
            initials: initials,
            onTap: onMenu ?? () => context.push('/menu'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SearchPill(
              onTap: onSearch ?? () => context.push('/search'),
            ),
          ),
          const SizedBox(width: 12),
          _MessagesButton(
            badge: badge,
            onTap: onMessages ?? () => context.push('/messages'),
          ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.initials, required this.onTap});
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: CkColors.ink,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: CkType.display(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: CkColors.paper,
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Row(
          children: [
            const V2Svg(
              V2Icons.search,
              size: 17,
              color: CkColors.muted,
              strokeWidth: 2,
            ),
            const SizedBox(width: 9),
            Text(
              'Search',
              style: CkType.body(fontSize: 15, color: CkColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesButton extends StatelessWidget {
  const _MessagesButton({required this.badge, required this.onTap});
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper,
                shape: BoxShape.circle,
                border: Border.all(color: CkColors.hairline),
              ),
              child: const V2Svg(
                V2Icons.messages,
                size: 19,
                color: CkColors.ink,
                strokeWidth: 1.9,
              ),
            ),
            if (badge > 0)
              Positioned(
                top: -2,
                right: -2,
                child: _Badge(text: badge > 9 ? '9+' : '$badge'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shared chrome for full-screen sub-pages reached from the Menu drawer
/// (My matches, My teams, My tournaments, …). Mirrors the prototype's
/// inline `SubPage`: back arrow + left-aligned title + optional eyebrow +
/// bottom hairline + optional bottom-right FAB.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.onBack,
    this.fabLabel,
    this.onFab,
  });

  final String title;
  final Widget child;
  final String? eyebrow;
  final VoidCallback? onBack;

  /// When non-null, renders a circular-plus FAB pinned bottom-right with
  /// [fabLabel] as the accessibility label.
  final String? fabLabel;
  final VoidCallback? onFab;

  @override
  Widget build(BuildContext context) {
    final back = onBack ?? () => Navigator.of(context).maybePop();
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 14, 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: CkColors.hairline)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: back,
                        icon: const V2Svg(
                          V2Icons.chevronLeft,
                          size: 20,
                          color: CkColors.ink,
                          strokeWidth: 2,
                        ),
                        splashRadius: 22,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (eyebrow != null)
                              Text(
                                eyebrow!,
                                style: CkType.mono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.12,
                                  color: CkColors.muted,
                                ),
                              ),
                            Text(
                              title,
                              style: CkType.display(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
            if (fabLabel != null && onFab != null)
              Positioned(
                right: 16,
                bottom: 20,
                child: FloatingActionButton.extended(
                  onPressed: onFab,
                  backgroundColor: CkColors.ink,
                  foregroundColor: CkColors.paper,
                  icon: const V2Svg(
                    V2Icons.plus,
                    size: 18,
                    color: CkColors.paper,
                    strokeWidth: 2,
                  ),
                  label: Text(
                    fabLabel!,
                    style: CkType.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CkColors.paper,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
