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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../theme/circk_theme.dart';
import '../../../features/messages/presentation/providers/messages_providers.dart';
import '../../../features/notifications/presentation/providers/notifications_providers.dart';

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
  // pavilion: shield with an inner star, on-brand for the "club" frame
  //          (no longer a nav tab — Pavilion moved to the Management sheet).
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
  // pool    : radar/crosshair — "find an opponent nearby", the open match pool.
  static const pool =
      '<circle cx="12" cy="12" r="8.5"/>'
      '<circle cx="12" cy="12" r="3.4"/>'
      '<path d="M12 1.6v3.6M12 18.8v3.6M1.6 12h3.6M18.8 12h3.6"/>';
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
  static const profile =
      '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>';
  static const management =
      '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/>';
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

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _MonogramTile(
            short: short,
            color: color,
            size: size,
            radius: radius,
          ),
          errorWidget: (_, __, ___) => _MonogramTile(
            short: short,
            color: color,
            size: size,
            radius: radius,
          ),
        ),
      );
    }
    return _MonogramTile(
      short: short,
      color: color,
      size: size,
      radius: radius,
    );
  }
}

class _MonogramTile extends StatelessWidget {
  const _MonogramTile({
    required this.short,
    required this.color,
    required this.size,
    required this.radius,
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
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: CkColors.paper,
        ),
      ),
    );
  }
}

enum AvatarTone { paper, ink, neutral }

/// Player avatar — circle with cached network image support + monogram fallback.
///
/// The monogram is not a loading state: for unclaimed players (who have no
/// photo column at all) and for users who never uploaded one, it is the final
/// rendering. It also backstops a broken URL, so a dead object in the
/// `avatars` bucket degrades to initials rather than a grey box.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.mono,
    this.imageUrl,
    this.size = 36,
    this.tone = AvatarTone.paper,
    this.background,
    this.foreground,
  });

  final String mono;
  final String? imageUrl;
  final double size;
  final AvatarTone tone;

  /// Overrides the tone's fill. Used where an avatar doubles as a role badge
  /// — the scoring screen's bowler carries its own green.
  final Color? background;

  /// Overrides the tone's monogram colour. Pair with [background].
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final ink = tone == AvatarTone.ink;
    final bg = background ?? (ink ? CkColors.ink : CkColors.paper2);
    final fg = foreground ?? (ink ? CkColors.paper : CkColors.ink2);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: (ink || background != null)
            ? null
            : Border.all(color: CkColors.hairline),
      ),
      child: Text(
        mono,
        style: CkType.display(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      // Sized decode. Avatars come out of the `avatars` bucket at up to 5 MB
      // and these render at 22–36 px, often eleven at a time in a picker
      // grid; decoding at full resolution is a real memory and jank cost.
      final memW = (size * MediaQuery.devicePixelRatioOf(context)).round();
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: memW,
          placeholder: (_, __) => fallback,
          errorWidget: (_, __, ___) => fallback,
        ),
      );
    }

    return fallback;
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

/// Universal top header: large title on the left; management, bell, and
/// the messages/chat button on the right.
class V2Header extends ConsumerWidget {
  const V2Header({
    super.key,
    required this.title,
    this.sub,
    this.notifCount,
    this.messagesCount,
    this.onBell,
    this.onMessages,
    this.onManagement,
    this.refreshing = false,
    this.showMessages = true,
    this.showManagement = true,
    this.showAvatar = false,
    this.showBack = false,
    this.onBack,
  });

  final String title;
  final String? sub;
  final int? notifCount;
  final int? messagesCount;
  final VoidCallback? onBell;
  final VoidCallback? onMessages;
  final VoidCallback? onManagement;

  /// Whether to render the chat/messages inbox button on the right.
  final bool showMessages;

  /// Whether to render the management console button on the right.
  final bool showManagement;

  /// Retained for legacy compatibility.
  final bool showAvatar;

  /// Whether to render a back chevron on the left.
  final bool showBack;
  final VoidCallback? onBack;

  final bool refreshing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int bellCount =
        notifCount ?? ref.watch(unreadNotificationsCountProvider);
    final int chatCount =
        messagesCount ?? ref.watch(unreadMessagesCountProvider);
    final bool renderBack = showBack || (onBack != null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (renderBack) ...[
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: CkColors.hairline),
                ),
                child: const V2Svg(
                  V2Icons.chevronLeft,
                  size: 18,
                  color: CkColors.ink,
                ),
              ),
            ),
          ] else if (showManagement && onManagement != null) ...[
            _ManagementButton(onTap: onManagement),
            const SizedBox(width: 12),
          ],
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
          const SizedBox(width: 8),
          _BellButton(count: bellCount, onTap: onBell),
          if (showMessages) ...[
            const SizedBox(width: 8),
            _MessagesButton(
              count: chatCount,
              onTap: onMessages ?? () => context.push('/messages'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManagementButton extends StatelessWidget {
  const _ManagementButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.paper,
          shape: BoxShape.circle,
          border: Border.all(color: CkColors.hairline),
        ),
        child: const V2Svg(
          V2Icons.management,
          size: 17,
          color: CkColors.ink,
        ),
      ),
    );
  }
}

class _MessagesButton extends StatelessWidget {
  const _MessagesButton({required this.count, this.onTap});
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
              child: const V2Svg(
                V2Icons.messages,
                size: 18,
                color: CkColors.ink,
              ),
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

/// The four v2 bottom-nav destinations: Home · Explore · Matches · Pool.
///
/// Organising rule: Bottom nav is the world; side panel is you.
/// Profile is now reached via the side panel's identity masthead.
enum V2Tab { home, explore, matches, pool }

/// 4-tab bottom navigation — Home · Explore · Matches · Pool.
class V2BottomNav extends StatelessWidget {
  const V2BottomNav({
    super.key,
    required this.active,
    required this.onSelect,
  });

  final V2Tab active;
  final ValueChanged<V2Tab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.surface,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _navItem(V2Tab.home, V2Icons.home),
            _navItem(V2Tab.explore, V2Icons.search),
            _navItem(V2Tab.matches, V2Icons.matches),
            _navItem(V2Tab.pool, V2Icons.pool),
          ],
        ),
      ),
    );
  }

  Widget _navItem(V2Tab id, String icon, {int? badge}) {
    final isActive = id == active;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 32,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: V2Svg(
                  icon,
                  size: 24,
                  color: isActive ? CkColors.red : CkColors.soft,
                  strokeWidth: isActive ? 2.2 : 1.8,
                ),
              ),
              if (badge != null && badge > 0)
                Positioned(
                  top: -2,
                  right: -6,
                  child: _Badge(text: '$badge'),
                ),
            ],
          ),
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
    this.saved = false,
    this.rsvp,
    this.onLike,
    this.onComment,
    this.onBookmark,
    this.onShare,
  });

  final int likes;
  final int comments;
  final bool liked;
  final bool saved;
  final String? rsvp;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;

  @override
  State<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends State<PostActions> {
  late bool _liked = widget.liked;
  late int _likes = widget.likes;
  late bool _saved = widget.saved;

  @override
  void didUpdateWidget(covariant PostActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liked != widget.liked || oldWidget.likes != widget.likes) {
      _liked = widget.liked;
      _likes = widget.likes;
    }
    if (oldWidget.saved != widget.saved) {
      _saved = widget.saved;
    }
  }

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
            onTap: () {
              setState(() {
                _liked = !_liked;
                _likes += _liked ? 1 : -1;
              });
              widget.onLike?.call();
            },
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
            onTap: widget.onShare ?? () {},
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
            onTap: () {
              setState(() => _saved = !_saved);
              widget.onBookmark?.call();
            },
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
