// Faithful Flutter port of the matchday v2 prototype's identity-first profile
// (`V21Profile` in design/app/screens/v2-IA.jsx).
//
// PRESENTATION-ONLY, MOCK DATA. No Riverpod / backend / repositories — plain
// Stateless/Stateful widgets. Buttons are inert except the FAB (→ ComposerScreen)
// and Edit profile (→ ProfileEditScreen); the comment action opens the shared
// comments sheet. Cricket stats and the posts grid are intentionally removed —
// the profile shows the feed-style LIST view only.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:novex_clean_arch/core/theme/circk_theme.dart';
import 'package:novex_clean_arch/features/posts/presentation/widgets/post_card.dart';
import 'package:novex_clean_arch/core/widgets/v2/v2_kit.dart';
import 'package:novex_clean_arch/core/widgets/v2/v2_modals.dart';
import 'package:novex_clean_arch/features/auth/presentation/providers/auth_providers.dart';
import 'package:novex_clean_arch/features/onboarding/domain/entities/profile.dart';
import 'package:novex_clean_arch/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:novex_clean_arch/features/posts/presentation/providers/posts_providers.dart';
import 'package:novex_clean_arch/features/posts/presentation/screens/composer_screen.dart';
import 'package:novex_clean_arch/features/posts/presentation/screens/photo_viewer_screen.dart';

import 'profile_edit_screen.dart';

// One-off oklch literals from PROFILE_POSTS in the JSX, converted to approx sRGB.
const Color _hueRed = Color(0xFFC2362B); // oklch(0.62 0.19 28) — "SIX" highlight
const Color _hueIndigo = Color(0xFF2E3E63); // oklch(0.42 0.10 260)
const Color _hueGold = Color(0xFFB98A2E); // oklch(0.55 0.13 80)

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.isTab = false, this.spectator = false});

  /// True when shown as the authenticated "You" tab (shell owns the bottom nav,
  /// so this screen renders none).
  final bool isTab;

  /// True when viewing someone else's profile (back chevron, Follow/Message,
  /// mutual count, no compose FAB).
  final bool spectator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Self view shows the signed-in user's real posts; the spectator demo keeps
    // its mock list (it's a fictional other user).
    // Stream-backed auth entity (same source as the router/app), not a raw
    // Supabase SDK snapshot; UserId.value is the uid that matches posts.author_id.
    final authorId = spectator
        ? null
        : ref.watch(currentUserStreamProvider).value?.id.value;
    // Real profile for the self view; spectator keeps the mock identity.
    final profile = spectator ? null : ref.watch(myProfileProvider).value;

    final scroll = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdentityHero(
            spectator: spectator,
            profile: profile,
            onEdit: () => _openEdit(context),
          ),
          const _PlaysForSection(),
          _PostsSection(
            onOpenComments: () => showCommentsSheet(context),
            authorId: authorId,
          ),
        ],
      ),
    );

    final content = ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CompactNav(spectator: spectator),
            Expanded(child: scroll),
          ],
        ),
      ),
    );

    // Compose FAB overlays only on the self view.
    if (spectator) return content;

    return Stack(
      children: [
        content,
        Positioned(
          right: 18,
          bottom: 24,
          child: _ComposeFab(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(builder: (_) => const ComposerScreen()),
            ),
          ),
        ),
      ],
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileEditScreen()),
    );
  }
}

// ── Compact nav: padding 6/14/4, label centred, optional back + 3-dot. ──
class _CompactNav extends StatelessWidget {
  const _CompactNav({required this.spectator});
  final bool spectator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Row(
        children: [
          if (spectator)
            _IconButton(
              icon: V2Icons.chevronLeft,
              size: 22,
              strokeWidth: 2,
              onTap: () => Navigator.maybePop(context),
            )
          else
            const SizedBox(width: 28),
          Expanded(
            child: Center(
              child: Text(
                spectator ? 'PROFILE' : 'YOUR PROFILE',
                style: CkType.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
              ),
            ),
          ),
          _IconButton(
            icon: V2Icons.dotsV,
            size: 18,
            strokeWidth: 2,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.size,
    this.strokeWidth = 2,
    this.onTap,
  });

  final String icon;
  final double size;
  final double strokeWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: V2Svg(
          icon,
          size: size,
          color: CkColors.ink,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

// ── Identity hero: avatar, name, handle, location, bio, signals, actions. ──
class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.spectator,
    this.profile,
    required this.onEdit,
  });
  final bool spectator;

  /// Real profile for the self view; null for the spectator mock.
  final Profile? profile;
  final VoidCallback onEdit;

  String get _name {
    final dn = profile?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    return spectator ? 'Bilal Ahmed' : 'matchday player';
  }

  String get _handle {
    final u = profile?.username;
    return (u != null && u.isNotEmpty) ? '@$u' : (spectator ? '@bilala' : '@you');
  }

  String get _city {
    final c = profile?.city?.trim();
    return (c != null && c.isNotEmpty) ? c : (spectator ? 'Karachi' : '—');
  }

  String get _monogram {
    final parts =
        _name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final letters =
        parts.length == 1 ? parts.first : '${parts.first[0]}${parts[1][0]}';
    return letters.substring(0, letters.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _avatarCircle() {
    final url = profile?.avatarUrl;
    final inner = (url != null && url.isNotEmpty)
        ? Image.network(url,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsCircle())
        : _initialsCircle();
    return ClipOval(child: SizedBox(width: 88, height: 88, child: inner));
  }

  Widget _initialsCircle() => Container(
        color: CkColors.ink,
        alignment: Alignment.center,
        child: Text(
          _monogram,
          style: CkType.display(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.03,
            color: CkColors.paper,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatarCircle(),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(
                          fontSize: 26,
                          letterSpacing: -0.025,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _handle,
                        style: CkType.body(
                          fontSize: 12.5,
                          color: CkColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const V2Svg(
                            V2Icons.pin,
                            size: 12,
                            color: CkColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CkType.body(
                                fontSize: 12,
                                color: CkColors.ink2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bio — real text for the self view; the styled sample for spectator.
          if (profile != null && (profile!.bio?.trim() ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  profile!.bio!.trim(),
                  style: CkType.body(
                    fontSize: 13.5,
                    color: CkColors.ink,
                    height: 1.5,
                  ),
                ),
              ),
            )
          else if (profile == null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: RichText(
                  text: TextSpan(
                    style: CkType.body(
                      fontSize: 13.5,
                      color: CkColors.ink,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Opening bat for the '),
                      TextSpan(
                        text: '@lahore-lions',
                        style: CkType.body(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: CkColors.red,
                          height: 1.5,
                        ),
                      ),
                      const TextSpan(
                        text: '. Tape ball weekends, leather on Sundays. '
                            'Karachi-based but travel for anything that pays in chai.',
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Social signals — followers / following (+ mutual on spectator).
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                const _Signal(value: '284', label: 'Followers'),
                const SizedBox(width: 16),
                const _Signal(value: '92', label: 'Following'),
                if (spectator) ...[
                  const Spacer(),
                  Text(
                    '2 mutual',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.10,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions.
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: spectator
                ? const Row(
                    children: [
                      _PrimaryBtn(label: 'Follow'),
                      SizedBox(width: 8),
                      _GhostBtn(label: 'Message'),
                      SizedBox(width: 8),
                      _IconSquareBtn(icon: V2Icons.share),
                    ],
                  )
                : Row(
                    children: [
                      _GhostBtn(label: 'Edit profile', onTap: onEdit),
                      const SizedBox(width: 8),
                      const _GhostBtn(label: 'Share profile'),
                      const SizedBox(width: 8),
                      // Pencil icon button.
                      const _IconSquareBtn(
                        icon:
                            '<path d="M12 20h9M4 20l4-1 11-11-3-3L5 16l-1 4z"/>',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Signal extends StatelessWidget {
  const _Signal({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: CkType.body(fontSize: 13, color: CkColors.ink),
        children: [
          TextSpan(
            text: value,
            style: CkType.display(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ' $label',
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buttons (ghost / primary / icon-square). ──
class _GhostBtn extends StatelessWidget {
  const _GhostBtn({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CkColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CkColors.paper,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconSquareBtn extends StatelessWidget {
  const _IconSquareBtn({required this.icon});
  final String icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CkColors.hairline),
        ),
        child: V2Svg(icon, size: 16, color: CkColors.ink, strokeWidth: 2),
      ),
    );
  }
}

// ── "Plays for" section: section label + horizontal TeamChip scroll. ──
class _PlaysForSection extends StatelessWidget {
  const _PlaysForSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Plays for'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TeamChip(
                  crest: CkCrest.ll,
                  short: 'LL',
                  name: 'Lahore Lions',
                  role: 'CAPTAIN',
                  main: true,
                ),
                SizedBox(width: 8),
                _TeamChip(
                  crest: CkCrest.ob,
                  short: 'OB',
                  name: 'Old Boys',
                  role: 'ALL-ROUNDER',
                ),
                SizedBox(width: 8),
                _TeamChip(
                  crest: CkCrest.mk,
                  short: 'MK',
                  name: 'Mohalla Kings',
                  role: 'BATTER',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  const _TeamChip({
    required this.crest,
    required this.short,
    required this.name,
    required this.role,
    this.main = false,
  });

  final Color crest;
  final String short;
  final String name;
  final String role;
  final bool main;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: main ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: main ? null : Border.all(color: CkColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Crest(short: short, color: crest, size: 28, radius: 999),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: CkType.display(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.01,
                  height: 1.1,
                  color: main ? CkColors.paper : CkColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role.toUpperCase(),
                style: CkType.mono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                  // main → rgba(255,255,255,0.6)
                  color: main
                      ? CkColors.paper.withValues(alpha: 0.6)
                      : CkColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Posts section: header + type filter chips + feed-style list. ──
class _PostsSection extends StatelessWidget {
  const _PostsSection({required this.onOpenComments, this.authorId});
  final VoidCallback onOpenComments;

  /// Non-null → render this author's real posts; null → the spectator mock.
  final String? authorId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header "Posts · 28".
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RichText(
              text: TextSpan(
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
                children: [
                  const TextSpan(text: 'POSTS'),
                  TextSpan(
                    text: ' · 28',
                    style: CkType.body(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Type filter chips.
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'All', count: 28, active: true),
                SizedBox(width: 6),
                _FilterChip(label: 'Posts', count: 14),
                SizedBox(width: 6),
                _FilterChip(label: 'Photos', count: 9),
                SizedBox(width: 6),
                _FilterChip(label: 'Moments', count: 5, auto: true),
              ],
            ),
          ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // Feed-style list: real posts for the owner, mock for the spectator demo.
        if (authorId == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _ProfileList(onOpenComments: onOpenComments),
          )
        else
          _RealProfileList(
            authorId: authorId!,
            onOpenComments: onOpenComments,
          ),
      ],
    );
  }
}

// ── Real posts list (profile owner): author's posts, full-bleed cards. ──
class _RealProfileList extends ConsumerWidget {
  const _RealProfileList({required this.authorId, required this.onOpenComments});
  final String authorId;
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(authorPostsProvider(authorId));
    return switch (async) {
      AsyncData(:final value) when value.isEmpty => Padding(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
          child: Text('No posts yet.',
              style: CkType.body(fontSize: 13, color: CkColors.muted)),
        ),
      AsyncData(:final value) => Column(
          children: [
            for (final post in value)
              FeedPostCard(
                post: post,
                showAuthor: false,
                onComment: onOpenComments,
                onOpenPhoto: (i) =>
                    Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PhotoViewerScreen(media: post.media, initialIndex: i),
                  ),
                ),
              ),
          ],
        ),
      AsyncError() => Padding(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
          child: Text("Couldn't load posts.",
              style: CkType.body(fontSize: 13, color: CkColors.muted)),
        ),
      _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: CkColors.muted),
            ),
          ),
        ),
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.10,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    this.active = false,
    this.auto = false,
  });

  final String label;
  final int count;
  final bool active;
  final bool auto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: active ? null : Border.all(color: CkColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: active ? CkColors.paper : CkColors.ink2,
            ),
          ),
          const SizedBox(width: 5),
          Opacity(
            opacity: 0.6,
            child: Text(
              '· $count',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.10,
                color: active ? CkColors.paper : CkColors.ink2,
              ),
            ),
          ),
          if (auto) ...[
            const SizedBox(width: 5),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: CkColors.amber,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── ProfileList: the first 5 PROFILE_POSTS as feed cards + footer. ──
class _ProfileList extends StatelessWidget {
  const _ProfileList({required this.onOpenComments});
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    // First 5 of PROFILE_POSTS: milestone, photo, photo, award, result.
    final posts = <_PostItem>[
      _MilestonePost(onOpenComments: onOpenComments),
      _PhotoPost(hue: _hueRed, label: 'SIX', score: '107*', onOpenComments: onOpenComments),
      _PhotoPost(hue: _hueIndigo, onOpenComments: onOpenComments),
      _AwardPost(onOpenComments: onOpenComments),
      _ResultPost(onOpenComments: onOpenComments),
    ];

    final children = <Widget>[];
    for (var i = 0; i < posts.length; i++) {
      if (i > 0) children.add(const SizedBox(height: 14));
      children.add(posts[i]);
    }
    children.add(const SizedBox(height: 14));
    children.add(
      Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
          child: Text(
            '4 MORE · KEEP SCROLLING',
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

// Marker mixin so the list can hold heterogenous post widgets typed as one.
abstract class _PostItem extends StatelessWidget {
  const _PostItem();
}

// Shared meta row: KIND · ★AUTO · when.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.kind, required this.when, this.auto = false});
  final String kind;
  final String when;
  final bool auto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            kind.toUpperCase(),
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
          if (auto) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: CkColors.cream,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '★ AUTO',
                style: CkType.mono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                  color: CkColors.amber,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            when,
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration get _cardDecoration => BoxDecoration(
      color: CkColors.paper,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: CkColors.hairline),
    );

class _MilestonePost extends _PostItem {
  const _MilestonePost({required this.onOpenComments});
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: _MetaRow(kind: 'milestone', when: '38m', auto: true),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CkColors.ink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    style: CkType.display(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.04,
                      height: 1,
                      color: CkColors.paper,
                    ),
                    children: [
                      const TextSpan(text: '107'),
                      TextSpan(
                        text: '*',
                        style: CkType.display(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.04,
                          color: CkColors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HIGHEST SCORE',
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.10,
                        color: CkColors.paper.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'off 62 balls vs Cobras',
                      style: CkType.body(fontSize: 12, color: CkColors.paper),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: PostActions(
              likes: 142,
              comments: 23,
              onComment: onOpenComments,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPost extends _PostItem {
  const _PhotoPost({
    required this.hue,
    this.label,
    this.score,
    required this.onOpenComments,
  });

  final Color hue;
  final String? label;
  final String? score;
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: _MetaRow(kind: 'photo', when: '2h'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(
              'Boys from the QF win — heart in my mouth that final over.',
              style: CkType.body(
                fontSize: 13,
                color: CkColors.ink,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2fr main cell.
                Expanded(
                  flex: 2,
                  child: Container(
                    color: hue,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HIGHLIGHT',
                          style: CkType.mono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.10,
                            color: CkColors.paper.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          label ?? 'PHOTO',
                          style: CkType.display(
                            fontSize: 56,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.04,
                            height: 1,
                            color: CkColors.paper,
                          ),
                        ),
                        if (score != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              score!,
                              style: CkType.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.10,
                                color: CkColors.paper.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // 1fr split column.
                const Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: ColoredBox(color: _hueIndigo)),
                      SizedBox(height: 2),
                      Expanded(child: ColoredBox(color: _hueGold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: PostActions(
              likes: 87,
              comments: 12,
              onComment: onOpenComments,
            ),
          ),
        ],
      ),
    );
  }
}

class _AwardPost extends _PostItem {
  const _AwardPost({required this.onOpenComments});
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: _MetaRow(kind: 'award', when: '2d'),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: CkColors.ink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PLAYER OF THE TOURNAMENT',
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.10,
                          color: CkColors.cream,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spring Cup ʼ25',
                        style: CkType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.02,
                          color: CkColors.paper,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '284 runs · SR 148 · 2 fifties',
                        style: CkType.body(
                          fontSize: 11,
                          color: CkColors.paper.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: PostActions(
              likes: 398,
              comments: 72,
              onComment: onOpenComments,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPost extends _PostItem {
  const _ResultPost({required this.onOpenComments});
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: _MetaRow(kind: 'result', when: '6h', auto: true),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: CkColors.hairline),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Crest(short: 'LL', color: CkCrest.ll, size: 26, radius: 6),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lahore Lions',
                          style: CkType.display(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '142/6',
                        style: CkType.mono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: CkColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Crest(short: 'KC', color: CkCrest.kc, size: 26, radius: 6),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Karachi Cobras',
                          style: CkType.display(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '119/9',
                        style: CkType.mono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: CkColors.redSoft,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'Lions won by 23 runs',
                      style: CkType.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CkInk.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: PostActions(
              likes: 214,
              comments: 37,
              onComment: onOpenComments,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compose FAB — 56×56 ink circle, plus icon, drop shadow. ──
class _ComposeFab extends StatelessWidget {
  const _ComposeFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.ink,
          shape: BoxShape.circle,
          boxShadow: [
            // boxShadow: 0 8px 22px rgba(40,30,15,0.18), 0 2px 6px rgba(40,30,15,0.10)
            BoxShadow(
              color: const Color(0xFF281E0F).withValues(alpha: 0.18),
              offset: const Offset(0, 8),
              blurRadius: 22,
            ),
            BoxShadow(
              color: const Color(0xFF281E0F).withValues(alpha: 0.10),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: const V2Svg(
          V2Icons.plus,
          size: 24,
          color: CkColors.paper,
          strokeWidth: 2.4,
        ),
      ),
    );
  }
}
