import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_shimmer.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../../core/widgets/modals/modals.dart';
import '../../../follows/domain/entities/follow_direction.dart';
import '../../../follows/presentation/controllers/follow_toggle_controller.dart';
import '../../../follows/presentation/providers/follows_providers.dart';
import '../../../follows/presentation/screens/followers_list_screen.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../posts/presentation/providers/posts_providers.dart';
import '../../../posts/presentation/screens/composer_screen.dart';
import '../../../posts/presentation/screens/photo_viewer_screen.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../../../teams/domain/entities/user_team_affiliation.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/player_profile.dart';
import '../../../safety/presentation/widgets/safety_menu.dart';
import '../../domain/entities/profile.dart';

// ── Profile Main Views ────────────────────────────────────────────────────────

/// Main profile view rendering the user identity, plays-for section, and posts feed.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key, required this.profile, this.isSelf = true});

  final bool isSelf;
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(authorPostsProvider(profile.userId.value));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Photo banner + Overlapping Avatar
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _coverPhoto(),
                            if (!isSelf) Positioned(top: 12, right: 14, child: Material(color: CkColors.paper, shape: const CircleBorder(), child: SafetyMenu(userId: profile.userId.value, kind: 'user', targetId: profile.userId.value))),
                            Positioned(
                              left: 22,
                              bottom: -40,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CkColors.paper,
                                    width: 3.5,
                                  ),
                                ),
                                child: _avatar(context),
                              ),
                            ),
                            if (context.canPop() || !isSelf)
                              Positioned(
                                top: 12,
                                left: 14,
                                child: _buildNavCircle(
                                  icon: Icons.arrow_back,
                                  onTap: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/home');
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 48, 22, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display name & handle
                              Text(
                                _name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: CkType.display(
                                  fontSize: 26,
                                  letterSpacing: -0.025,
                                  height: 1.15,
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

                              // Role & styles (Cricket Identity)
                              if (_hasRoleContent)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _RoleStyleLine(
                                    playerProfile: profile.playerProfile,
                                  ),
                                ),

                              // Bio
                              if ((profile.bio?.trim() ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 320,
                                    ),
                                    child: Text(
                                      profile.bio!.trim(),
                                      style: CkType.body(
                                        fontSize: 13.5,
                                        color: CkColors.ink,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ),

                              // Social followers / following signals
                              _RealSignals(
                                userId: profile.userId.value,
                                name: _name,
                                handle: _handle,
                              ),

                              // Action buttons (Follow / Edit Profile / Share)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child:
                                    isSelf
                                        ? Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => context.push(
                                                  '/profile/edit',
                                                ),
                                                child: Container(
                                                  height: 38,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: CkColors.ink,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Edit profile',
                                                    style: CkType.body(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: CkColors.paper,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap:
                                                    () => _shareProfile(
                                                      context,
                                                      name: _name,
                                                      handle: _handle,
                                                    ),
                                                child: Container(
                                                  height: 38,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: CkColors.paper,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                    border: Border.all(
                                                      color: CkColors.hairline,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Share',
                                                    style: CkType.body(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: CkColors.ink,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                        : Row(
                                          children: [
                                            _FollowButton(
                                              userId: profile.userId.value,
                                            ),
                                            const SizedBox(width: 8),
                                            _MessageButton(
                                              userId: profile.userId.value,
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap:
                                                  () => _shareProfile(
                                                    context,
                                                    name: _name,
                                                    handle: _handle,
                                                  ),
                                              child: Container(
                                                width: 38,
                                                height: 38,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: CkColors.paper,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  border: Border.all(
                                                    color: CkColors.hairline,
                                                  ),
                                                ),
                                                child: const V2Svg(
                                                  V2Icons.share,
                                                  size: 16,
                                                  color: CkColors.ink,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(child: _PlaysForSection(userId: profile.userId.value)),

                  // ── Posts Header & Filter Strip ──
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
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
                                  text: ' · ${postsAsync.value?.length ?? 0}',
                                  style: CkType.body(
                                    fontSize: 11,
                                    color: CkColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // COMMENTED OUT — the All / Posts / Photos / Moments filter chips.
                        // Photos and Moments have no filtering behind them (they were hard-
                        // coded to 0), and All and Posts counted the same list, so the row
                        // offered four choices that all showed the same thing. Restore it
                        // with the `_chip` helper below once the filters are real.
                        // SingleChildScrollView(
                        //   scrollDirection: Axis.horizontal,
                        //   padding: const EdgeInsets.symmetric(horizontal: 18),
                        //   child: Row(
                        //     children: [
                        //       _chip(
                        //         label: 'All',
                        //         count: postsAsync.value?.length ?? 0,
                        //         active: true,
                        //       ),
                        //       const SizedBox(width: 6),
                        //       _chip(
                        //         label: 'Posts',
                        //         count: postsAsync.value?.length ?? 0,
                        //       ),
                        //       const SizedBox(width: 6),
                        //       _chip(label: 'Photos', count: 0),
                        //       const SizedBox(width: 6),
                        //       _chip(label: 'Moments', count: 0),
                        //     ],
                        //   ),
                        // ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // ── Posts List / Empty / Skeleton ──
                  switch (postsAsync) {
                    AsyncData(:final value) when value.isEmpty =>
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No posts yet.',
                              style: TextStyle(
                                fontSize: 13,
                                color: CkColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    AsyncData(:final value) => SliverList.builder(
                      itemCount: value.length,
                      itemBuilder: (context, i) {
                        final post = value[i];
                        return FeedPostCard(
                          post: post,
                          showAuthor: true,
                          onComment: () => showCommentsSheet(
                            context,
                            postId: post.id.value,
                            postAuthorHandle: post.authorUsername != null && post.authorUsername!.isNotEmpty
                                ? '@${post.authorUsername}'
                                : post.authorName,
                            onOpenProfile: (username) => context.push('/u/$username'),
                          ),
                          onLike: () => ref.read(postsRepositoryProvider).togglePostLike(post.id),
                          onBookmark: () => ref.read(postsRepositoryProvider).toggleBookmark(post.id),
                          onOpenPhoto:
                              (int idx) => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).push(
                                MaterialPageRoute<void>(
                                  builder:
                                      (_) => PhotoViewerScreen(
                                        media: post.media,
                                        initialIndex: idx,
                                      ),
                                ),
                              ),
                        );
                      },
                    ),
                    AsyncError() => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            "Couldn't load posts.",
                            style: TextStyle(
                              fontSize: 13,
                              color: CkColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _ => const SliverToBoxAdapter(child: _PostsListSkeleton()),
                  },

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          isSelf
              ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:
                    () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ComposerScreen(),
                      ),
                    ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: CkColors.ink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF281E0F).withValues(alpha: 0.18),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: V2Svg(
                      V2Icons.plus,
                      size: 24,
                      color: CkColors.paper,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  // Parked with the commented-out filter row above.
  // ignore: unused_element
  Widget _chip({
    required String label,
    required int count,
    bool active = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: active ? null : Border.all(color: CkColors.hairline),
      ),
      child: Text(
        '$label · $count',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: active ? CkColors.paper : CkColors.muted,
        ),
      ),
    );
  }

  String get _name =>
      (profile.displayName?.trim().isNotEmpty ?? false)
          ? profile.displayName!.trim()
          : 'matchday player';

  String get _handle =>
      (profile.username?.isNotEmpty ?? false) ? '@${profile.username}' : '@you';

  String get _monogram {
    final parts =
        _name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final letters =
        parts.length == 1 ? parts.first : '${parts.first[0]}${parts[1][0]}';
    return letters.substring(0, letters.length >= 2 ? 2 : 1).toUpperCase();
  }

  bool get _hasRoleContent {
    final pp = profile.playerProfile;
    if (pp == null) return false;
    return pp.role != null ||
        pp.battingStyle != null ||
        (pp.bowlingStyle != null && pp.bowlingStyle != BowlingStyle.doesntBowl);
  }

  Widget _avatar(BuildContext context) {
    final url = profile.avatarUrl;
    final inner =
        (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
              imageUrl: url,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              memCacheWidth:
                  (88 * MediaQuery.devicePixelRatioOf(context)).round(),
              errorWidget: (_, __, ___) => _monogramFallback(),
            )
            : _monogramFallback();

    return ClipOval(child: SizedBox(width: 88, height: 88, child: inner));
  }

  Widget _monogramFallback() => Container(
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

  Widget _coverPhoto() {
    final url = profile.coverUrl;
    final hasUrl = url != null && url.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        image:
            hasUrl
                ? DecorationImage(
                  image: CachedNetworkImageProvider(url.trim()),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child:
          hasUrl
              ? null
              : Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CkColors.paper.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      V2Svg(V2Icons.camera, size: 14, color: CkColors.muted),
                      SizedBox(width: 6),
                      Text(
                        'Cover Photo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildNavCircle({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = CkColors.ink,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: CkColors.paper.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: CkColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Center(
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}

/// Loading skeleton view for profile.
class ProfileLoadingView extends StatelessWidget {
  const ProfileLoadingView({super.key, this.isSelf = false});
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (context.canPop() || !isSelf)
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: CkColors.paper2,
                      shape: BoxShape.circle,
                      border: Border.all(color: CkColors.hairline),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: CkColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const Expanded(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: _IdentityHeroSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 404 Empty State when profile username is not found.
class ProfileNotFoundView extends StatelessWidget {
  const ProfileNotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CkColors.ink),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: const SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                V2Svg(V2Icons.pin, size: 28, color: CkColors.muted),
                SizedBox(height: 12),
                Text(
                  "We couldn't find that profile.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: CkColors.ink),
                ),
                SizedBox(height: 4),
                Text(
                  'The link may be broken or the account is no longer active.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: CkColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role Style Line ─────────────────────────────────────────────────────────

class _RoleStyleLine extends StatelessWidget {
  const _RoleStyleLine({required this.playerProfile});
  final PlayerProfile? playerProfile;

  @override
  Widget build(BuildContext context) {
    final pp = playerProfile;
    final role =
        pp?.role != null
            ? switch (pp!.role!) {
              PlayerRole.batter => 'BATTER',
              PlayerRole.bowler => 'BOWLER',
              PlayerRole.allRounder => 'ALL-ROUNDER',
              PlayerRole.wicketKeeper => 'WICKET-KEEPER',
            }
            : null;

    final styles = <String>[];
    if (pp?.battingStyle != null) {
      styles.add(switch (pp!.battingStyle!) {
        BattingStyle.rightHand => 'Right-hand bat',
        BattingStyle.leftHand => 'Left-hand bat',
      });
    }
    if (pp?.bowlingStyle != null &&
        pp!.bowlingStyle != BowlingStyle.doesntBowl) {
      styles.add(switch (pp.bowlingStyle!) {
        BowlingStyle.rightArmFast => 'Right-arm fast',
        BowlingStyle.rightArmMedium => 'Right-arm medium',
        BowlingStyle.rightArmSpin => 'Right-arm spin',
        BowlingStyle.leftArmFast => 'Left-arm fast',
        BowlingStyle.leftArmSpin => 'Left-arm spin',
        BowlingStyle.doesntBowl => '',
      });
    }
    final styleText = styles.isNotEmpty ? styles.join(' · ') : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
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
              style: CkType.mono(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: CkColors.ink2,
              ),
            ),
          ),
          if (styleText != null) const SizedBox(width: 7),
        ],
        if (styleText != null)
          Flexible(
            child: Text(
              styleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 11.5, color: CkColors.ink2),
            ),
          ),
      ],
    );
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return Expanded(
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Follow',
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CkColors.paper,
            ),
          ),
        ),
      );
    }

    final isFollowing =
        ref.watch(followToggleProvider('user', userId!)).value ?? false;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:
            () =>
                ref
                    .read(followToggleProvider('user', userId!).notifier)
                    .toggle(),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? CkColors.paper : CkColors.ink,
            borderRadius: BorderRadius.circular(999),
            border: isFollowing ? Border.all(color: CkColors.hairline) : null,
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isFollowing ? CkColors.ink : CkColors.paper,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageButton extends ConsumerStatefulWidget {
  const _MessageButton({required this.userId});
  final String? userId;

  @override
  ConsumerState<_MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends ConsumerState<_MessageButton> {
  bool _loading = false;

  Future<void> _handleMessage() async {
    if (widget.userId == null || _loading) return;
    setState(() => _loading = true);
    final result = await ref
        .read(messagesRepositoryProvider)
        .getOrCreateDmChat(widget.userId!);
    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (chatId) {
        context.push('/messages/${chatId.value}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleMessage,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CkColors.hairline),
          ),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Message',
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

class _RealSignals extends ConsumerWidget {
  const _RealSignals({
    required this.userId,
    required this.name,
    required this.handle,
  });
  final String? userId;
  final String name;
  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = userId;
    final counts =
        uid != null ? ref.watch(followCountsProvider(uid)).value : null;
    final followers = counts?.followers ?? 0;
    final following = counts?.following ?? 0;
    final username = handle.startsWith('@') ? handle.substring(1) : handle;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          _stat(
            context,
            count: followers,
            label: 'followers',
            onTap:
                uid == null
                    ? null
                    : () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => FollowersListScreen(
                              userId: uid,
                              profileName: name,
                              profileUsername: username,
                              initialTab: FollowDirection.followers,
                            ),
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '·',
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
          ),
          _stat(
            context,
            count: following,
            label: 'following',
            onTap:
                uid == null
                    ? null
                    : () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => FollowersListScreen(
                              userId: uid,
                              profileName: name,
                              profileUsername: username,
                              initialTab: FollowDirection.following,
                            ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context, {
    required int count,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: CkType.display(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
            ),
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

// ── Plays For & Teams Strip ───────────────────────────────────────────────────

class _PlaysForSection extends ConsumerWidget {
  const _PlaysForSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final affiliationsAsync = ref.watch(userAffiliatedTeamsProvider(userId));

    return affiliationsAsync.when(
      data: (affiliations) {
        if (affiliations.isEmpty) return const SizedBox.shrink();

        final captains = affiliations.where((a) => a.isCaptain).toList();
        final playsFor = affiliations.where((a) => !a.isCaptain).toList();

        if (captains.isEmpty && playsFor.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (captains.isNotEmpty) ...[
              _ChipStrip(
                label: 'Captains',
                main: true,
                teams: captains,
              ),
              if (playsFor.isNotEmpty) const SizedBox(height: 14),
            ],
            if (playsFor.isNotEmpty) ...[
              _ChipStrip(
                label: 'Plays for',
                main: false,
                teams: playsFor,
              ),
            ],
            const SizedBox(height: 6),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ChipStrip extends StatelessWidget {
  const _ChipStrip({
    required this.label,
    required this.teams,
    required this.main,
  });

  final String label;
  final List<UserTeamAffiliation> teams;
  final bool main;

  Color _parsePrimaryColor(String? hex) {
    if (hex == null || hex.isEmpty) return CkColors.ink;
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return CkColors.ink;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: teams.map((t) {
              final crestBg = _parsePrimaryColor(t.primaryColor);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => context.push('/teams/${t.teamId}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: main ? CkColors.ink : CkColors.paper,
                      borderRadius: BorderRadius.circular(999),
                      border: main ? null : Border.all(color: CkColors.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Crest / Monogram / Logo
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: crestBg,
                            shape: BoxShape.circle,
                          ),
                          child: t.logoUrl != null && t.logoUrl!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: t.logoUrl!,
                                    width: 18,
                                    height: 18,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Text(
                                      t.logoMonogram,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  t.logoMonogram,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t.teamName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: main ? CkColors.paper : CkColors.ink,
                          ),
                        ),
                        if (!main && t.role != 'PLAYER') ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${t.role})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: main ? CkColors.paper.withValues(alpha: 0.7) : CkColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Skeletons & Floating FAB ──────────────────────────────────────────────────

class _IdentityHeroSkeleton extends StatelessWidget {
  const _IdentityHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const CkShimmerBox(width: double.infinity, height: 130, radius: 0),
            Positioned(
              left: 22,
              bottom: -40,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: CkColors.paper, width: 3.5),
                ),
                child: const CkShimmerBox(
                  width: 88,
                  height: 88,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 48, 22, 8),
          child: CkShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CkShimmerBox(width: 200, height: 26, radius: 6),
                SizedBox(height: 8),
                CkShimmerBox(width: 110, height: 13, radius: 4),
                SizedBox(height: 10),
                CkShimmerBox(width: 96, height: 12, radius: 4),
                SizedBox(height: 18),
                CkShimmerBox(height: 13, radius: 4),
                SizedBox(height: 8),
                CkShimmerBox(width: 220, height: 13, radius: 4),
                SizedBox(height: 18),
                Row(
                  children: [
                    CkShimmerBox(width: 50, height: 16, radius: 4),
                    SizedBox(width: 16),
                    CkShimmerBox(width: 50, height: 16, radius: 4),
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
        ),
      ],
    );
  }
}

class _PostsListSkeleton extends StatelessWidget {
  const _PostsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const CkShimmer(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CkShimmerBox(
              width: double.infinity,
              height: 110,
              radius: 14,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CkShimmerBox(
              width: double.infinity,
              height: 140,
              radius: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Share Helper ──────────────────────────────────────────────────────

Future<void> _shareProfile(
  BuildContext originContext, {
  required String name,
  required String handle,
}) {
  final slug = handle.startsWith('@') ? handle.substring(1) : handle;
  final link = 'https://joinmatchday.com/u/$slug';
  final box = originContext.findRenderObject() as RenderBox?;
  final origin =
      (box != null && box.hasSize)
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
