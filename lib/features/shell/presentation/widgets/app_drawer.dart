import 'dart:ui' show FontFeature, clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_shimmer.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../follows/presentation/providers/follows_providers.dart';
import '../../../matches/presentation/providers/match_pool_providers.dart';
import '../../../matches/presentation/providers/my_matches_providers.dart';
import '../../../matches/presentation/state/live_panel_match.dart';
import '../../../posts/presentation/providers/posts_providers.dart';
import '../../../profile/domain/entities/player_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../teams/presentation/providers/teams_providers.dart';

// ─── Panel glyph set ────────────────────────────────────────────────────────
//
// The Side Panel design redraws the house glyphs on a 24 viewBox at stroke 1.8
// with round caps and joins. Five are new to the app (settings, help, trophy,
// clubs, sign-out); the other six are refinements of `V2Icons` entries that are
// deliberately NOT changed there — `V2Icons.matches` and friends are the bottom
// nav's glyphs and must stay as drawn for that surface. Promote any of these to
// `V2Icons` the first time a second screen needs one.
abstract final class _Glyphs {
  static const matches =
      '<path d="M14.5 4.2l5.3 5.3-7.4 7.4-5.3-5.3z"/>'
      '<path d="M6.6 12.2L4 14.8l4.4 4.4 2.6-2.6"/>'
      '<circle cx="6.2" cy="6.2" r="2.3"/>';
  static const teams =
      '<path d="M12 3.2l7.2 2.6v5.6c0 4.3-3 7-7.2 8.4-4.2-1.4-7.2-4.1-7.2-8.4V5.8z"/>'
      '<circle cx="12" cy="11" r="2.2"/>';
  static const pool =
      '<circle cx="12" cy="12" r="8.2"/>'
      '<circle cx="12" cy="12" r="3.4"/>'
      '<path d="M12 1.8v3M12 19.2v3M1.8 12h3M19.2 12h3"/>';
  static const bookmark =
      '<path d="M6.2 4.4a1.6 1.6 0 0 1 1.6-1.6h8.4a1.6 1.6 0 0 1 1.6 1.6v16.8L12 16.6l-5.8 4.6z"/>';
  static const settings =
      '<path d="M4 7.5h10M18 7.5h2M4 16.5h6M14 16.5h6"/>'
      '<circle cx="16" cy="7.5" r="2.2"/>'
      '<circle cx="12" cy="16.5" r="2.2"/>';
  static const help =
      '<circle cx="12" cy="12" r="9"/>'
      '<path d="M9.4 9.4a2.7 2.7 0 1 1 3.8 2.5c-.8.4-1.2 1-1.2 1.9"/>'
      '<path d="M12 17.2h.01"/>';
  static const trophy =
      '<path d="M8 4h8v4.5a4 4 0 0 1-8 0z"/>'
      '<path d="M8 5.6H5.4v1.6c0 1.7 1.4 3.1 3.1 3.1"/>'
      '<path d="M16 5.6h2.6v1.6c0 1.7-1.4 3.1-3.1 3.1"/>'
      '<path d="M12 12.6V16M9 20h6l-.7-4H9.7z"/>';
  static const clubs =
      '<path d="M5 20V6.4l7-3.2 7 3.2V20"/>'
      '<path d="M3.2 20h17.6"/>'
      '<path d="M9.4 20v-5.2h5.2V20"/>'
      '<path d="M9.4 9.6h1.6M13 9.6h1.6"/>';
  static const signOut =
      '<path d="M14.5 4.2H7.6A2.4 2.4 0 0 0 5.2 6.6v10.8a2.4 2.4 0 0 0 2.4 2.4h6.9"/>'
      '<path d="M17 8.6l3.4 3.4-3.4 3.4"/>'
      '<path d="M20.4 12h-8.2"/>';
  static const chevronRight = '<path d="M9.5 5.5l6.5 6.5-6.5 6.5"/>';
  static const close = '<path d="M6.2 6.2l11.6 11.6M17.8 6.2L6.2 17.8"/>';
}

/// `shadow-2` — the app's larger of two shadow tokens. Replaces the Material
/// elevation-16 the drawer used to carry, which reads far too heavy on paper.
const _shadow2 = <BoxShadow>[
  BoxShadow(color: Color(0x12281E0F), offset: Offset(0, 8), blurRadius: 28),
  BoxShadow(color: Color(0x0A281E0F), offset: Offset(0, 2), blurRadius: 6),
];

/// Hairline inside the live card. One step of the existing ramp, sitting
/// between `redSoft` (#F7E6E1) and the red ink — a plain `hairline` is a cool
/// grey and reads as dirt on the red tint.
const _redSoftHairline = Color(0xFFEFD8D2);

/// The outer (right) edge of the panel is the only rounded one.
const _panelRadius = BorderRadius.horizontal(right: Radius.circular(20));

/// Row metrics track the OS text scale, so a row keeps its proportions rather
/// than having a fixed-size glyph float in a growing box: at 120% the design's
/// row is `min-height 67` with a 26 glyph and a 21 chevron — 56 / 22 / 18 all
/// scaled by the same factor. Capped at 1.3; past that the glyph starts to
/// crowd the 20dp side padding.
double _scaled(BuildContext context, double base) =>
    base * clampDouble(MediaQuery.textScalerOf(context).scale(1), 1.0, 1.3);

TextStyle _tabular(TextStyle s) =>
    s.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// Two-letter initials from a display name (for the avatar fallback).
String _initialsOf(String? name) {
  final parts =
      (name ?? '')
          .trim()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList();
  if (parts.isEmpty) return '·';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length >= 2 ? 2 : 1)
        .toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String _playerRoleLabel(PlayerRole? r) => switch (r) {
  PlayerRole.batter => 'Batter',
  PlayerRole.bowler => 'Bowler',
  PlayerRole.allRounder => 'All-rounder',
  PlayerRole.wicketKeeper => 'Wicket-keeper',
  null => '',
};

/// The authenticated side navigation panel.
///
/// Organising principle: "Bottom nav is the world; side panel is you." The
/// panel is **nouns only, no verbs** — every destination owns its own create
/// button one tap deeper.
///
/// Ported from the Side Panel canvas (Claude Design project "Matchday mobile
/// app design", `Side Panel.dc.html`). It draws five states off the same tree:
///
/// * **A · Default** — populated, with the current destination carrying the
///   place marker (paper2 fill + a 3×20 red rail).
/// * **B · Live** — a live match is promoted out of the badge into a redSoft
///   card pinned under identity. My Matches drops back to its upcoming count,
///   so the live state is promoted rather than duplicated.
/// * **C · First run** — count rows fall back to an em-dash plus a one-line
///   subtitle, and a cream orientation note states the rule of the panel.
/// * **D · Loading** — a content-shaped shimmer. Chrome, glyphs and labels are
///   real; only account-scoped values shim, so nothing jumps on resolve.
/// * **E · Overflow** — rows are min-height, not height, so 120% text scale
///   grows them (56 → 67) instead of clipping.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final profile = profileAsync.value;

    // D · Loading. `isLoading && !hasValue` rather than `value == null`, so a
    // provider that fails (or legitimately resolves to null) drops out of the
    // skeleton instead of shimmering forever.
    final identityLoading = profileAsync.isLoading && !profileAsync.hasValue;

    final displayName = profile?.displayName ?? profile?.username ?? '';
    final roleLabel = _playerRoleLabel(profile?.playerProfile?.role);
    final subline = [
      if (profile?.username != null && profile!.username!.isNotEmpty)
        '@${profile.username}',
      if (roleLabel.isNotEmpty) roleLabel,
      if (profile?.city != null && profile!.city!.isNotEmpty) profile.city!,
    ].join(' · ');

    final uid = profile?.userId.value;
    final postsCount =
        uid != null
            ? ref.watch(authorPostsProvider(uid)).value?.length ?? 0
            : 0;
    final followersCount =
        uid != null
            ? ref.watch(followCountsProvider(uid)).value?.followers ?? 0
            : 0;

    final live = ref.watch(livePanelMatchProvider).value;
    final matchesAsync = ref.watch(myMatchesViewProvider);
    final teamsAsync = ref.watch(myTeamsProvider);
    final poolAsync = ref.watch(myPoolRequestsProvider);

    final myMatches = matchesAsync.value;
    final teamCount = teamsAsync.value?.length;
    final poolCount = poolAsync.value?.length;

    // The three count rows shim on their own providers: chrome, glyphs and
    // labels stay real, and the badge slot holds a pre-sized block so nothing
    // jumps when a value lands.
    final countsLoading =
        (matchesAsync.isLoading && !matchesAsync.hasValue) ||
        (teamsAsync.isLoading && !teamsAsync.hasValue) ||
        (poolAsync.isLoading && !poolAsync.hasValue);

    // My Matches badge precedence: live > upcoming > pending. The live badge
    // only appears when the live card is NOT shown — otherwise the panel would
    // say the same thing twice.
    final (String? matchBadge, _BadgeTone matchTone) = switch (myMatches) {
      null => (null, _BadgeTone.neutral),
      final v when v.confirmed.any((m) => m.live) && live == null => (
        'Live now',
        _BadgeTone.live,
      ),
      final v when v.confirmed.where((m) => !m.live).isNotEmpty => (
        '${v.confirmed.where((m) => !m.live).length} upcoming',
        _BadgeTone.neutral,
      ),
      final v when v.pendingRequestsCount > 0 => (
        '${v.pendingRequestsCount} pending',
        _BadgeTone.pending,
      ),
      _ => (null, _BadgeTone.neutral),
    };

    // C · First run — everything has resolved and the account is empty.
    final firstRun =
        !identityLoading &&
        !countsLoading &&
        (myMatches?.isEmpty ?? false) &&
        (teamCount ?? 0) == 0 &&
        (poolCount ?? 0) == 0;

    final here = GoRouter.of(context).state.uri.path;
    final width = clampDouble(
      MediaQuery.sizeOf(context).width * 0.86,
      320,
      420,
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: MaterialLocalizations.of(context).drawerLabel,
      // Sized exactly as Material's own Drawer does. An `Align` here would
      // report the full screen width to the DrawerController, whose reveal
      // animation is a `widthFactor` on this child — the panel would then
      // slide across the whole screen instead of its own 335.
      child: ConstrainedBox(
        constraints: BoxConstraints.expand(width: width),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: CkColors.paper,
            borderRadius: _panelRadius,
            boxShadow: _shadow2,
          ),
          child: ClipRRect(
            borderRadius: _panelRadius,
            child: Material(
              color: CkColors.paper,
              child: SafeArea(
                right: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Identity(
                      loading: identityLoading,
                      name: displayName,
                      subline: subline,
                      avatarUrl: profile?.avatarUrl,
                      postsCount: postsCount,
                      followersCount: followersCount,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: CkColors.hairline,
                    ),

                    // B · the hero state.
                    if (live != null) _LiveCard(match: live),

                    // C · one sentence that states the rule of the panel.
                    if (firstRun) const _OrientationNote(),

                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const _Eyebrow('Yours'),
                          _NavRow(
                            glyph: _Glyphs.matches,
                            label: 'My Matches',
                            empty: firstRun,
                            subtitle: 'Fixtures you are playing in',
                            badge: matchBadge,
                            badgeTone: matchTone,
                            skeletonWidth: 46,
                            loading: countsLoading,
                            current: here.startsWith('/my/matches'),
                            route: '/my/matches',
                          ),
                          _NavRow(
                            glyph: _Glyphs.teams,
                            label: 'My Teams',
                            empty: firstRun,
                            subtitle: 'Squads you own or belong to',
                            badge: (teamCount ?? 0) > 0 ? '$teamCount' : null,
                            skeletonWidth: 22,
                            loading: countsLoading,
                            current:
                                here.startsWith('/my/teams') ||
                                here.startsWith('/teams'),
                            route: '/my/teams',
                          ),
                          _NavRow(
                            glyph: _Glyphs.pool,
                            label: 'My challenges',
                            empty: firstRun,
                            subtitle: 'Challenges you posted',
                            badge:
                                (poolCount ?? 0) > 0 ? '$poolCount open' : null,
                            skeletonWidth: 38,
                            loading: countsLoading,
                            current: here.startsWith('/my/pool-requests'),
                            route: '/my/pool-requests',
                          ),
                          _NavRow(
                            glyph: _Glyphs.trophy,
                            label: 'My Tournaments',
                            empty: firstRun,
                            subtitle: 'Cups & leagues you organize or follow',
                            skeletonWidth: 38,
                            loading: countsLoading,
                            current:
                                here.startsWith('/my/tournaments') ||
                                here.startsWith('/tournaments'),
                            route: '/my/tournaments',
                          ),

                          const _GroupRule(),
                          const _Eyebrow('Account'),
                          _NavRow(
                            glyph: _Glyphs.bookmark,
                            label: 'Saved',
                            current: here.startsWith('/saved'),
                            route: '/saved',
                          ),
                          _NavRow(
                            glyph: _Glyphs.settings,
                            label: 'Settings',
                            current: here.startsWith('/settings'),
                            route: '/settings',
                          ),
                          const _NavRow(
                            glyph: _Glyphs.help,
                            label: 'Help & Support',
                            inert: true,
                          ),

                          const _GroupRule(),
                          const _Eyebrow('Not built yet'),
                          const _NavRow(
                            glyph: _Glyphs.clubs,
                            label: 'Clubs',
                            inert: true,
                            roadmap: true,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: CkColors.hairline,
                    ),
                    const _Footer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 5.6 Identity block ─────────────────────────────────────────────────────

class _Identity extends StatelessWidget {
  const _Identity({
    required this.loading,
    required this.name,
    required this.subline,
    required this.avatarUrl,
    required this.postsCount,
    required this.followersCount,
  });

  final bool loading;
  final String name;
  final String subline;
  final String? avatarUrl;
  final int postsCount;
  final int followersCount;

  @override
  Widget build(BuildContext context) {
    final close = _CloseButton(onTap: () => Navigator.of(context).pop());

    if (loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CkShimmer(
              child: CkShimmerBox(
                width: 48,
                height: 48,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 3),
                child: CkShimmer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CkShimmerBox(width: 132, height: 15),
                      SizedBox(height: 6),
                      CkShimmerBox(width: 178, height: 11, radius: 5),
                      SizedBox(height: 6),
                      CkShimmerBox(width: 112, height: 9, radius: 5),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            close,
          ],
        ),
      );
    }

    // The stat line is the only thing added to the block: it is a doorway to
    // the profile, not the profile. Cover, bio and batting style stay there.
    final stats =
        postsCount == 0 && followersCount == 0
            ? 'NO POSTS YET'
            : '$postsCount POSTS · $followersCount FOLLOWERS';

    return _Pressable(
      onTap: () {
        Navigator.of(context).pop();
        context.push('/profile');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(mono: _initialsOf(name), imageUrl: avatarUrl, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? '·' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.display(fontSize: 17),
                    ),
                    if (subline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                          fontSize: 11.5,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      stats,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _tabular(
                        CkType.mono(
                          fontSize: 10,
                          letterSpacing: 0.10,
                          color:
                              postsCount == 0 && followersCount == 0
                                  ? CkColors.soft
                                  : CkColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            close,
          ],
        ),
      ),
    );
  }
}

/// 36dp disc inside a 44dp tap target — the old 30dp button was under the
/// minimum. The −4 margin keeps the disc's optical edge on the 14dp padding.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(4, -4),
      child: Semantics(
        button: true,
        label: MaterialLocalizations.of(context).closeButtonTooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  shape: BoxShape.circle,
                  border: Border.all(color: CkColors.hairline),
                ),
                child: const V2Svg(_Glyphs.close, size: 17),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 5.4 Live card — the hero state ─────────────────────────────────────────

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.match});

  final LivePanelMatch match;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
      child: _Pressable(
        radius: BorderRadius.circular(14),
        pressedColor: _redSoftHairline,
        restColor: CkColors.redSoft,
        onTap: () {
          Navigator.of(context).pop();
          context.push('/matches/${match.matchId}');
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _LivePill(),
                  Text(
                    '${match.oversLabel} OV',
                    style: _tabular(
                      CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.09,
                        color: CkInk.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _LiveScoreLine(
                short: match.battingShort,
                color: match.battingColor,
                name: match.battingName,
                score: match.battingScore,
                batting: true,
              ),
              const SizedBox(height: 7),
              _LiveScoreLine(
                short: match.opponentShort,
                color: match.opponentColor,
                name: match.opponentName,
                score: match.opponentScore,
                batting: false,
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.only(top: 9),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _redSoftHairline)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (match.targetLine ?? '').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.mono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.09,
                          color: CkInk.red,
                        ),
                      ),
                    ),
                    V2Svg(
                      _Glyphs.chevronRight,
                      size: _scaled(context, 16),
                      color: CkInk.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveScoreLine extends StatelessWidget {
  const _LiveScoreLine({
    required this.short,
    required this.color,
    required this.name,
    required this.score,
    required this.batting,
  });

  final String short;
  final Color color;
  final String name;
  final String score;

  /// The side at the crease is ink; the side that has set its total is muted.
  final bool batting;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LiveCrest(short: short, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: batting ? CkColors.ink : CkColors.muted,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          score,
          style: _tabular(
            batting
                ? CkType.display(fontSize: 16)
                : CkType.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: CkColors.muted,
                ),
          ),
        ),
      ],
    );
  }
}

/// 22×22 r6 crest. Not `Crest` from the kit: this one is drawn at the card's
/// own monogram size (Inter Tight 10/700, no tracking).
class _LiveCrest extends StatelessWidget {
  const _LiveCrest({required this.short, required this.color});

  final String short;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        short,
        style: CkType.display(
          fontSize: 10,
          letterSpacing: 0,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// LIVE pill with the 5px dot pulsing 1400ms ease-in-out, opacity 1 → .25.
class _LivePill extends StatefulWidget {
  const _LivePill();

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CkColors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(
              begin: 1,
              end: 0.25,
            ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
            child: Container(
              width: 5,
              height: 5,
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
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.09,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 5.2 First run ──────────────────────────────────────────────────────────

/// A sentence, not a button. States the rule of the panel without adding a
/// verb: the destinations still own creation.
class _OrientationNote extends StatelessWidget {
  const _OrientationNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: CkColors.cream,
          border: Border.all(color: CkColors.creamBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR SIDE OF MATCHDAY',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: CkInk.amber,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Everything you join, create or are invited to collects here. '
              'It fills up as you play.',
              style: CkType.body(
                fontSize: 11.5,
                height: 1.5,
                color: CkColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rows ───────────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

class _GroupRule extends StatelessWidget {
  const _GroupRule();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 8),
    child: Divider(height: 1, thickness: 1, color: CkColors.hairline),
  );
}

enum _BadgeTone { neutral, live, pending, soon }

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.glyph,
    required this.label,
    this.subtitle,
    this.badge,
    this.badgeTone = _BadgeTone.neutral,
    this.skeletonWidth = 46,
    this.loading = false,
    this.empty = false,
    this.current = false,
    this.inert = false,
    this.roadmap = false,
    this.route,
  });

  final String glyph;
  final String label;

  /// Shown only in the empty state, in place of a count.
  final String? subtitle;

  final String? badge;
  final _BadgeTone badgeTone;

  /// Width of the shimmer block that stands in for this row's badge, so the
  /// slot is pre-sized and nothing jumps when the value resolves.
  final double skeletonWidth;

  final bool loading;

  /// First run — the account has nothing anywhere yet, so count rows fall back
  /// to an em-dash plus a one-line subtitle saying what will appear there.
  final bool empty;

  /// The destination the user is currently inside — paper2 fill + red rail.
  final bool current;

  /// No destination: no chevron, no press state, not focusable.
  final bool inert;

  /// A `NOT BUILT YET` row — one step quieter and shorter than [inert].
  final bool roadmap;

  final String? route;

  bool get _empty => empty && !loading && !inert && subtitle != null;

  @override
  Widget build(BuildContext context) {
    final double height = roadmap ? 48 : (_empty ? 60 : 56);

    final Color glyphColor = switch (true) {
      _ when roadmap => CkColors.soft,
      _ when inert || loading => loading ? CkColors.soft : CkColors.muted,
      _ when _empty => CkColors.muted,
      _ => CkColors.ink,
    };

    final label0 = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CkType.display(
        fontSize: roadmap ? 13.5 : 14.5,
        fontWeight: current ? FontWeight.w700 : FontWeight.w600,
        color: (inert || roadmap) ? CkColors.muted : CkColors.ink,
      ),
    );

    final Widget? trailing = switch (true) {
      _ when loading => CkShimmer(
        child: CkShimmerBox(width: skeletonWidth, height: 15, radius: 5),
      ),
      _ when inert || roadmap => const _Badge('Soon', _BadgeTone.soon),
      _ when badge != null => _Badge(
        badge!,
        badgeTone,
        // The place marker already fills the row with paper2, so a neutral
        // badge steps one notch up the ramp to stay legible.
        onPaper2: !current,
      ),
      _ when _empty => Text(
        '—',
        style: CkType.mono(
          fontSize: 11,
          letterSpacing: 0,
          color: CkColors.soft,
        ),
      ),
      _ => null,
    };

    // Chevron sits 6dp from a badge, 8dp from the empty state's em-dash, and
    // the full 14dp row gap when there is nothing between it and the label.
    final double chevronGap = trailing == null ? 14 : (_empty ? 8 : 6);

    final row = Row(
      children: [
        V2Svg(
          glyph,
          size: _scaled(context, roadmap ? 20 : 22),
          color: glyphColor,
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              subtitle != null && _empty
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      label0,
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(fontSize: 11, color: CkColors.muted),
                      ),
                    ],
                  )
                  : label0,
        ),
        if (trailing != null) ...[const SizedBox(width: 14), trailing],
        if (!inert && !roadmap) ...[
          SizedBox(width: chevronGap),
          V2Svg(
            _Glyphs.chevronRight,
            size: _scaled(context, 18),
            color: (loading || _empty) ? CkColors.soft : CkColors.muted,
          ),
        ],
      ],
    );

    // min-height, not height: at 120% text scale the row grows to ~67 rather
    // than clipping. The 6dp vertical padding is what gives it room.
    final body = Container(
      constraints: BoxConstraints(minHeight: _scaled(context, height)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      alignment: Alignment.centerLeft,
      child: row,
    );

    if (inert || roadmap || loading) {
      return Semantics(enabled: false, child: body);
    }

    return Stack(
      children: [
        _Pressable(
          restColor: current ? CkColors.paper2 : null,
          onTap:
              route == null
                  ? null
                  : () {
                    Navigator.of(context).pop();
                    context.push(route!);
                  },
          child: body,
        ),
        // Place marker: 3 × 20 rail at x = 0, vertically centred. One row max.
        if (current)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 3,
                height: 20,
                decoration: const BoxDecoration(
                  color: CkColors.red,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.tone, {this.onPaper2 = true});

  final String text;
  final _BadgeTone tone;

  /// False when the row already carries a paper2 fill (the current place).
  final bool onPaper2;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color? border) = switch (tone) {
      _BadgeTone.neutral => (
        onPaper2 ? CkColors.paper2 : CkColors.hairline,
        CkColors.ink,
        null,
      ),
      _BadgeTone.live => (CkColors.redSoft, CkInk.red, null),
      _BadgeTone.pending => (CkColors.cream, CkInk.amber, CkColors.creamBorder),
      _BadgeTone.soon => (CkColors.cream, CkInk.amber, CkColors.creamBorder),
    };

    return Container(
      padding:
          tone == _BadgeTone.soon
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(
        text.toUpperCase(),
        style: _tabular(
          CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.09,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ─── Footer ─────────────────────────────────────────────────────────────────

class _Footer extends ConsumerWidget {
  const _Footer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          _SignOutButton(onTap: () => _confirmSignOut(context, ref)),
          const SizedBox(height: 12),
          Text(
            'MATCHDAY · v2.0',
            textAlign: TextAlign.center,
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.09,
              color: CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            backgroundColor: CkColors.paper,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            buttonPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.end,
            title: Text('Sign out', style: CkType.display(fontSize: 18)),
            content: Text(
              'Are you sure you want to sign out of Matchday?',
              style: CkType.body(
                fontSize: 13.5,
                height: 1.5,
                color: CkColors.ink2,
              ),
            ),
            actions: [
              _DialogAction(
                label: 'Cancel',
                style: CkType.body(fontSize: 13, color: CkColors.muted),
                onTap: () => Navigator.of(dialogCtx).pop(),
              ),
              const SizedBox(width: 8),
              _DialogAction(
                label: 'Sign out',
                style: CkType.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CkColors.red,
                ),
                onTap: () async {
                  Navigator.of(dialogCtx).pop();
                  Navigator.of(context).pop();
                  await ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
          ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(label, style: style),
        ),
      ),
    );
  }
}

/// Pressed = redSoft fill + `CkInk.red`, per the redline.
class _SignOutButton extends StatefulWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final fg = _down ? CkInk.red : CkColors.red;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Duration(milliseconds: _down ? 90 : 120),
          curve: Curves.linear,
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _down ? CkColors.redSoft : CkColors.paper2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              V2Svg(_Glyphs.signOut, size: _scaled(context, 17), color: fg),
              const SizedBox(width: 8),
              Text(
                'Sign out',
                style: CkType.body(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Press state ────────────────────────────────────────────────────────────

/// Row press: fill in 90ms linear, out 120ms. No scale, and deliberately no
/// ripple — a Material splash bleeds past the panel's edge and reads wrong on
/// paper.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    this.onTap,
    this.restColor,
    this.pressedColor,
    this.radius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? restColor;
  final Color? pressedColor;
  final BorderRadius? radius;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final rest = widget.restColor ?? Colors.transparent;
    final pressed = widget.pressedColor ?? CkColors.paper2;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp:
          widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel:
          widget.onTap == null ? null : () => setState(() => _down = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: _down ? 90 : 120),
        curve: Curves.linear,
        decoration: BoxDecoration(
          color: _down ? pressed : rest,
          borderRadius: widget.radius,
        ),
        child: widget.child,
      ),
    );
  }
}
