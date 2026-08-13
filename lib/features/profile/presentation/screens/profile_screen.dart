// Faithful Flutter port of the matchday v2 prototype's identity-first profile
// (`V21Profile` in design/app/screens/v2-IA.jsx).
//
// Three modes:
//   • Self ("You" tab)        → real signed-in profile (myProfileProvider),
//                               Edit profile + Share, compose FAB.
//   • By username (/u/:user)  → real public profile (profileByUsernameProvider)
//                               for a shared link; Follow/Message/Share, back
//                               chevron, no FAB. Unknown handle → not-found.
//   • Spectator demo          → a fictional other user from hard-coded mock
//                               copy (legacy; reached only from the feed demo).
// Cricket stats and the posts grid are intentionally removed — the profile
// shows the feed-style LIST view only. Follow/Message remain to-be-wired.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/features/posts/presentation/widgets/post_card.dart';
import 'package:matchday/core/widgets/v2/ck_shimmer.dart';
import 'package:matchday/core/widgets/v2/v2_kit.dart';
import 'package:matchday/core/widgets/v2/v2_modals.dart';
import 'package:matchday/features/auth/presentation/providers/auth_providers.dart';
import 'package:matchday/features/follows/domain/entities/follow_direction.dart';
import 'package:matchday/features/follows/presentation/providers/follows_providers.dart';
import 'package:matchday/features/follows/presentation/screens/followers_list_screen.dart';
import 'package:matchday/features/onboarding/domain/entities/player_profile.dart';
import 'package:matchday/features/onboarding/domain/entities/profile.dart';
import 'package:matchday/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:matchday/features/posts/presentation/providers/posts_providers.dart';
import 'package:matchday/features/posts/presentation/screens/composer_screen.dart';
import 'package:matchday/features/posts/presentation/screens/photo_viewer_screen.dart';

import 'profile_edit_screen.dart';

// One-off oklch literals from PROFILE_POSTS in the JSX, converted to approx sRGB.
const Color _hueRed = Color(0xFFC2362B); // oklch(0.62 0.19 28) — "SIX" highlight
const Color _hueIndigo = Color(0xFF2E3E63); // oklch(0.42 0.10 260)
const Color _hueGold = Color(0xFFB98A2E); // oklch(0.55 0.13 80)

/// Canonical web base for a shared profile link. The app resolves
/// `joinmatchday.com/u/<username>` in-app via the `/u/:username` route + the
/// App/Universal Links config; the OS only hands the link over once the
/// verification files (`assetlinks.json` / `apple-app-site-association`) are
/// hosted on the domain. Kept as a single constant so the host is easy to swap.
const String _profileShareBase = 'https://joinmatchday.com/u';

/// Opens the OS share sheet with a link to [handle]'s matchday profile.
/// [name]/[handle] are already resolved to real-or-mock values by the hero,
/// so this works for both the self view and the spectator demo. [originContext]
/// anchors the share-sheet popover on iPad (ignored on phones).
Future<void> _shareProfile(
  BuildContext originContext, {
  required String name,
  required String handle,
}) {
  final slug = handle.startsWith('@') ? handle.substring(1) : handle;
  final link = '$_profileShareBase/$slug';
  final box = originContext.findRenderObject() as RenderBox?;
  final origin = (box != null && box.hasSize)
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  return SharePlus.instance.share(
    ShareParams(
      text: 'Check out $name ($handle) on matchday 🏏\n$link',
      subject: '$name on matchday',
      sharePositionOrigin: origin,
    ),
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    this.isTab = false,
    this.spectator = false,
    this.username,
  });

  /// True when shown as the authenticated "You" tab (shell owns the bottom nav,
  /// so this screen renders none).
  final bool isTab;

  /// True for the legacy spectator DEMO — a fictional other user rendered from
  /// hard-coded mock data (back chevron, Follow/Message, mutual count, no FAB).
  /// For viewing a *real* other user, pass [username] instead.
  final bool spectator;

  /// When set, render the REAL public profile for this `@username`
  /// (the `/u/:username` route + shared-link landing). Chrome matches the
  /// spectator layout, but every field is live data.
  final String? username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byUsername = username != null;
    // Self = the signed-in "You" tab. Everything else is an "other" view
    // (back chevron, Follow/Message/Share, no compose FAB).
    final isSelf = !spectator && !byUsername;
    // Only the legacy demo renders hard-coded mock copy.
    final mock = spectator && !byUsername;

    // Profile source per mode. Watch the full AsyncValue so the hero can show a
    // shimmer while the first fetch is in-flight.
    final profileAsync = byUsername
        ? ref.watch(profileByUsernameProvider(username!))
        : mock
            ? const AsyncValue<Profile?>.data(null)
            : ref.watch(myProfileProvider);
    final profile = profileAsync.value;
    final loading = profileAsync.isLoading && profile == null;
    // A resolved-but-absent real profile (unknown / inactive username) — or a
    // fetch error — lands here. Only meaningful in the by-username mode.
    final notFound = byUsername && !loading && profile == null;

    // Whose posts + follow counts to show. Self → signed-in uid; by-username →
    // the resolved profile's uid; mock → null (keeps the mock posts list).
    // Stream-backed auth entity (same source as the router/app); UserId.value
    // is the uid that matches posts.author_id.
    final subjectUserId = byUsername
        ? profile?.userId.value
        : mock
            ? null
            : ref.watch(currentUserStreamProvider).value?.id.value;

    if (notFound) {
      return const ColoredBox(
        color: CkColors.paper,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _CompactNav(spectator: true),
              Expanded(child: _ProfileNotFound()),
            ],
          ),
        ),
      );
    }

    final scroll = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdentityHero(
            isSelf: isSelf,
            mock: mock,
            profile: profile,
            loading: loading,
            subjectUserId: subjectUserId,
            onEdit: () => _openEdit(context),
          ),
          const _PlaysForSection(),
          _PostsSection(
            onOpenComments: () => showCommentsSheet(context),
            authorId: subjectUserId,
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
            _CompactNav(spectator: !isSelf),
            Expanded(child: scroll),
          ],
        ),
      ),
    );

    // Compose FAB overlays only on the self view.
    if (!isSelf) return content;

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

/// Empty state for `/u/:username` when the handle resolves to no active
/// profile (or the fetch failed). Keeps the back-chevron nav so the user can
/// retreat.
class _ProfileNotFound extends StatelessWidget {
  const _ProfileNotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const V2Svg(V2Icons.pin, size: 28, color: CkColors.muted),
            const SizedBox(height: 12),
            Text(
              "We couldn't find that profile.",
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 14, color: CkColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              'The link may be broken or the account is no longer active.',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
          ],
        ),
      ),
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
            // Self view: empty 30px left spacer so the title is visually
            // centered against the right-side gear button (matches the
            // matchday-challenge profile-you design).
            const SizedBox(width: 30),
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
          if (spectator)
            _IconButton(
              icon: V2Icons.dotsV,
              size: 18,
              strokeWidth: 2,
              onTap: () {},
            )
          else
            // Self view: gear icon (settings affordance). Material's
            // `Icons.settings_outlined` is close enough to the design's
            // 1.7px-stroke gear without inlining a custom SVG path.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Settings entry — future Pavilion settings push.
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  duration: Duration(milliseconds: 1400),
                  content: Text('Settings coming soon'),
                ));
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.settings_outlined,
                  size: 22,
                  color: CkColors.ink,
                ),
              ),
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
class _IdentityHero extends ConsumerWidget {
  const _IdentityHero({
    required this.isSelf,
    required this.mock,
    this.profile,
    this.loading = false,
    this.subjectUserId,
    required this.onEdit,
  });

  /// True for the signed-in "You" tab (Edit profile + Share, compose FAB).
  /// False for any "other" view (Follow/Message/Share).
  final bool isSelf;

  /// Legacy spectator DEMO — render hard-coded mock copy (name, bio, counts).
  /// Mutually exclusive with a real [profile].
  final bool mock;

  /// Real profile for the self view and the by-username view; null for the
  /// spectator mock (and transiently while a real fetch is in flight).
  final Profile? profile;

  /// True while the profile is being fetched for the first time — render a
  /// shimmer skeleton instead of the placeholder strings.
  final bool loading;

  /// The viewed subject's uid — drives the real follower/following counts.
  /// Null for the mock demo.
  final String? subjectUserId;

  final VoidCallback onEdit;

  String get _name {
    final dn = profile?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    return mock ? 'Bilal Ahmed' : 'matchday player';
  }

  String get _handle {
    final u = profile?.username;
    return (u != null && u.isNotEmpty) ? '@$u' : (mock ? '@bilala' : '@you');
  }

  String get _city {
    final c = profile?.city?.trim();
    return (c != null && c.isNotEmpty) ? c : (mock ? 'Karachi' : '—');
  }

  /// True when the role/style row has anything to render — used to skip
  /// the whole `Padding` block when the player profile is null or both
  /// the role and bowling/batting styles are unset.
  bool get _roleLineHasContent {
    final pp = profile?.playerProfile;
    if (mock) return true; // the mock demo always has content
    if (pp == null) return false;
    return pp.role != null ||
        pp.battingStyle != null ||
        (pp.bowlingStyle != null && pp.bowlingStyle != BowlingStyle.doesntBowl);
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (loading) return const _IdentityHeroSkeleton();
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

          // Role pill + batting/bowling style line — single horizontal row,
          // never wraps (the matchday-challenge spec is explicit: "ALL-/
          // ROUNDER" splitting mid-word was a bug). Rendered only when at
          // least the role OR a style is available; collapsed otherwise.
          if (_roleLineHasContent)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: _RoleStyleLine(playerProfile: profile?.playerProfile),
            ),

          // Bio — four states:
          //   1. Has a bio                → render body text (self or other)
          //   2. Self + empty bio         → dashed "+ Add a bio" pill (toasts;
          //                                 the real editor is its own ticket)
          //   3. Mock demo                → mock structured fallback
          //   4. Other real + empty bio   → render nothing (can't edit theirs)
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
          else if (isSelf && profile != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _AddBioPill(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    duration: Duration(milliseconds: 1400),
                    content: Text('Edit bio coming soon'),
                  ),
                ),
              ),
            )
          else if (mock)
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

          // Social signals — followers / following. The mock demo keeps its
          // placeholder counts; self + by-username views read live counts for
          // [subjectUserId].
          if (mock)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  const _Signal(value: '284', label: 'Followers'),
                  const SizedBox(width: 16),
                  const _Signal(value: '92', label: 'Following'),
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
              ),
            )
          else
            _RealSignals(
              userId: subjectUserId,
              name: _name,
              handle: _handle,
            ),

          // Actions.
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: !isSelf
                ? Row(
                    children: [
                      const _PrimaryBtn(label: 'Follow'),
                      const SizedBox(width: 8),
                      const _GhostBtn(label: 'Message'),
                      const SizedBox(width: 8),
                      _IconSquareBtn(
                        icon: V2Icons.share,
                        onTap: () => _shareProfile(
                          context,
                          name: _name,
                          handle: _handle,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Edit profile — solid ink CTA per the design.
                      _PrimaryBtn(label: 'Edit profile', onTap: onEdit),
                      const SizedBox(width: 8),
                      _GhostBtn(
                        label: 'Share',
                        onTap: () => _shareProfile(
                          context,
                          name: _name,
                          handle: _handle,
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

/// Shimmer-animated skeleton mirroring [_IdentityHero]'s layout — avatar
/// circle + name/handle/city stack + bio lines + social signals + action
/// buttons. Shown while the self-view profile is being fetched for the
/// first time.
class _IdentityHeroSkeleton extends StatelessWidget {
  const _IdentityHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 14, 22, 8),
      child: CkShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CkShimmerBox(
                    width: 88, height: 88, shape: BoxShape.circle),
                SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CkShimmerBox(width: 200, height: 26, radius: 6),
                        SizedBox(height: 10),
                        CkShimmerBox(width: 110, height: 13, radius: 4),
                        SizedBox(height: 12),
                        CkShimmerBox(width: 96, height: 12, radius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            CkShimmerBox(height: 13, radius: 4),
            SizedBox(height: 8),
            CkShimmerBox(width: 220, height: 13, radius: 4),
            SizedBox(height: 18),
            Row(
              children: [
                _SignalSkeleton(),
                SizedBox(width: 16),
                _SignalSkeleton(),
              ],
            ),
            SizedBox(height: 18),
            Row(
              children: [
                CkShimmerBox(width: 116, height: 38, radius: 999),
                SizedBox(width: 8),
                CkShimmerBox(width: 116, height: 38, radius: 999),
                SizedBox(width: 8),
                CkShimmerBox(width: 38, height: 38, radius: 999),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Followers / following signals for the self view. Reads live counts
/// from `followCountsProvider` keyed on the current user and renders a
/// single muted sentence of the form `**284** followers · **92** following`
/// per the matchday-challenge profile design. Each count is an inline
/// tappable target that pushes [FollowersListScreen] with the matching
/// initial tab.
class _RealSignals extends ConsumerWidget {
  const _RealSignals({
    required this.userId,
    required this.name,
    required this.handle,
  });

  /// The viewed subject's uid (signed-in user for the self view, the resolved
  /// profile's uid for a by-username view). Null → counts render as 0 and the
  /// taps are inert.
  final String? userId;

  /// Display name + `@handle` for the followers screen header.
  final String name;
  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local capture so the tap closures promote to non-null.
    final uid = userId;
    final countsAsync =
        uid == null ? null : ref.watch(followCountsProvider(uid));

    final followers = countsAsync?.value?.followers ?? 0;
    final following = countsAsync?.value?.following ?? 0;
    final username = handle.startsWith('@') ? handle.substring(1) : handle;

    // Single muted sentence with two inline tappable bold counts. We use
    // a Row of three widgets (count · label · separator · count · label)
    // instead of a RichText with GestureDetector spans — the tap targets
    // need to ignore the trailing word so "284 followers" only triggers
    // for tapping on "284", and Flutter's TapGestureRecognizer-in-span
    // doesn't compose cleanly with a parent ConstrainedBox.
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          _MetricCount(
            value: followers,
            label: 'followers',
            onTap: uid == null
                ? null
                : () => _open(
                      context,
                      uid,
                      username,
                      FollowDirection.followers,
                    ),
          ),
          // Centred separator dot — fontSize 12.5 / muted.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '·',
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
          ),
          _MetricCount(
            value: following,
            label: 'following',
            onTap: uid == null
                ? null
                : () => _open(
                      context,
                      uid,
                      username,
                      FollowDirection.following,
                    ),
          ),
        ],
      ),
    );
  }

  void _open(
    BuildContext context,
    String userId,
    String username,
    FollowDirection initialTab,
  ) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => FollowersListScreen(
          userId: userId,
          profileName: name,
          profileUsername: username,
          initialTab: initialTab,
        ),
      ),
    );
  }
}

/// Inline tappable metric — bold count followed by a muted noun, like
/// `**284** followers`. Used by [_RealSignals]; no public callers.
class _MetricCount extends StatelessWidget {
  const _MetricCount({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$value',
            style: CkType.display(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.01,
              color: CkColors.ink,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: CkType.body(fontSize: 12.5, color: CkColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Self-view empty-bio pill — dashed border, leading `+` icon, muted
/// label. Matches the `+ Add a bio` affordance in the matchday-challenge
/// profile-you design. Tapping fires a toast (the real editor lands in
/// its own ticket).
class _AddBioPill extends StatelessWidget {
  const _AddBioPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          // DashedBorder isn't in Flutter core; an OutlinedBorder with a
          // dashed PaintingStyle is a heavier add. The closest in-tree
          // approximation is `BorderRadius` + a custom-painted outline.
          // For v1 we use a solid 1px line — visually close enough at
          // the small size; upgrade to a true dashed border if/when this
          // becomes the canonical "add" pattern elsewhere.
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: CkColors.line, width: 1),
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+',
              style: CkType.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Add a bio',
              style: CkType.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CkColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Role pill + batting/bowling style line. Single horizontal row that
/// never wraps — the matchday-challenge design is explicit that breaking
/// "ALL-ROUNDER" across two lines is a bug.
///
/// When [playerProfile] is null the spectator's sample copy is rendered;
/// otherwise the real role + styles drive both halves.
class _RoleStyleLine extends StatelessWidget {
  const _RoleStyleLine({required this.playerProfile});
  final PlayerProfile? playerProfile;

  String? get _roleLabel {
    final r = playerProfile?.role;
    if (r != null) {
      return switch (r) {
        PlayerRole.batter => 'BATTER',
        PlayerRole.bowler => 'BOWLER',
        PlayerRole.allRounder => 'ALL-ROUNDER',
        PlayerRole.wicketKeeper => 'WICKET-KEEPER',
      };
    }
    // Spectator: no playerProfile is passed; default to the design's
    // sample copy.
    return playerProfile == null ? 'ALL-ROUNDER' : null;
  }

  String? get _styleLine {
    final pp = playerProfile;
    if (pp == null) return 'Right-hand bat · Off-spin';
    final parts = <String>[];
    final b = pp.battingStyle;
    if (b != null) {
      parts.add(switch (b) {
        BattingStyle.rightHand => 'Right-hand bat',
        BattingStyle.leftHand => 'Left-hand bat',
      });
    }
    final bo = pp.bowlingStyle;
    if (bo != null && bo != BowlingStyle.doesntBowl) {
      parts.add(switch (bo) {
        BowlingStyle.rightArmFast => 'Right-arm fast',
        BowlingStyle.rightArmMedium => 'Right-arm medium',
        BowlingStyle.rightArmSpin => 'Right-arm spin',
        BowlingStyle.leftArmFast => 'Left-arm fast',
        BowlingStyle.leftArmSpin => 'Left-arm spin',
        BowlingStyle.doesntBowl => '',
      });
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final role = _roleLabel;
    final style = _styleLine;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (role != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              role,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: CkType.mono(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: CkColors.ink2,
              ),
            ),
          ),
          if (style != null) const SizedBox(width: 7),
        ],
        if (style != null)
          Flexible(
            child: Text(
              style,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(
                fontSize: 11.5,
                color: CkColors.ink2,
              ),
            ),
          ),
      ],
    );
  }
}

/// Two-line stat block placeholder used in [_IdentityHeroSkeleton].
class _SignalSkeleton extends StatelessWidget {
  const _SignalSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CkShimmerBox(width: 44, height: 18, radius: 4),
        SizedBox(height: 6),
        CkShimmerBox(width: 60, height: 10, radius: 3),
      ],
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
  const _PrimaryBtn({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () {},
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
  const _IconSquareBtn({required this.icon, this.onTap});
  final String icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
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
/// CAPTAINS + PLAYS FOR — two distinct horizontal-scroll strips per the
/// matchday-challenge profile-you design. Currently driven by mock data
/// (one captain chip + two regular chips); real-data integration with
/// the teams feature is its own ticket.
///
/// The CAPTAINS strip uses ink-filled chips with paper text; PLAYS FOR
/// uses paper-filled chips with ink text. The chip definition itself
/// already supports both visual styles via `main` — only the data
/// partition changes here.
class _PlaysForSection extends StatelessWidget {
  const _PlaysForSection();

  // Mock-data partition: a single captain entry + the rest. Real data
  // would derive `cap` from the user's role on each team (owner /
  // captain vs anything else).
  static const _captainTeams = <_TeamChipData>[
    _TeamChipData(
      crest: CkCrest.ll,
      short: 'LL',
      name: 'Lahore Lions',
      role: 'CAPTAIN',
    ),
  ];

  static const _playsForTeams = <_TeamChipData>[
    _TeamChipData(
      crest: CkCrest.ob,
      short: 'OB',
      name: 'Old Boys',
      role: 'ALL-ROUNDER',
    ),
    _TeamChipData(
      crest: CkCrest.mk,
      short: 'MK',
      name: 'Mohalla Kings',
      role: 'BATTER',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Lists are mock-static today so the strips are always populated; the
    // future real-data path will swap these for live providers and guard
    // each strip on emptiness.
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipStrip(label: 'Captains', teams: _captainTeams, main: true),
        SizedBox(height: 14),
        _ChipStrip(label: 'Plays for', teams: _playsForTeams, main: false),
        SizedBox(height: 6),
      ],
    );
  }
}

/// Data record for a team-chip row entry. Kept private — the moment
/// real data arrives this becomes a thin adapter over the teams entity.
class _TeamChipData {
  const _TeamChipData({
    required this.crest,
    required this.short,
    required this.name,
    required this.role,
  });
  final Color crest;
  final String short;
  final String name;
  final String role;
}

class _ChipStrip extends StatelessWidget {
  const _ChipStrip({
    required this.label,
    required this.teams,
    required this.main,
  });

  final String label;
  final List<_TeamChipData> teams;

  /// Ink-filled chip variant (CAPTAINS) when true; paper-filled (PLAYS
  /// FOR) when false.
  final bool main;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 9),
          child: Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              for (var i = 0; i < teams.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _TeamChip(
                  crest: teams[i].crest,
                  short: teams[i].short,
                  name: teams[i].name,
                  role: teams[i].role,
                  main: main,
                ),
              ],
            ],
          ),
        ),
      ],
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
      _ => const _PostsListSkeleton(),
    };
  }
}

/// Three feed-card-shaped shimmer placeholders shown while the author's
/// posts are being fetched.
class _PostsListSkeleton extends StatelessWidget {
  const _PostsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const CkShimmer(
      child: Column(
        children: [
          _PostCardSkeleton(),
          _PostCardSkeleton(withImage: false),
          _PostCardSkeleton(),
        ],
      ),
    );
  }
}

/// Single post-card placeholder: header (timestamp + meta), 2 text lines,
/// optional image block, action row.
class _PostCardSkeleton extends StatelessWidget {
  const _PostCardSkeleton({this.withImage = true});
  final bool withImage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CkShimmerBox(width: 80, height: 10, radius: 3),
              SizedBox(width: 8),
              CkShimmerBox(width: 6, height: 6, shape: BoxShape.circle),
              SizedBox(width: 8),
              CkShimmerBox(width: 60, height: 10, radius: 3),
            ],
          ),
          const SizedBox(height: 12),
          const CkShimmerBox(height: 13, radius: 4),
          const SizedBox(height: 8),
          const CkShimmerBox(width: 240, height: 13, radius: 4),
          if (withImage) ...[
            const SizedBox(height: 14),
            const AspectRatio(
              aspectRatio: 4 / 3,
              child: CkShimmerBox(height: double.infinity, radius: 10),
            ),
          ],
          const SizedBox(height: 14),
          const Row(
            children: [
              CkShimmerBox(width: 44, height: 18, radius: 999),
              SizedBox(width: 10),
              CkShimmerBox(width: 44, height: 18, radius: 999),
              SizedBox(width: 10),
              CkShimmerBox(width: 44, height: 18, radius: 999),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: CkColors.hairline),
        ],
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
