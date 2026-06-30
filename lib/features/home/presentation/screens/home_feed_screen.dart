// Home feed — data-driven from the real `posts` feature (online-only).
//
// Layout mirrors `HomeFeed` in design_handoff_matchday's home-messages.jsx:
// a two-pill `Following / Discover` toggle sits above the post list. The
// shared matchday [GlobalHeader] (avatar → Menu, search pill, messages
// bubble) is owned by [AppShell] above us, so it stays pixel-identical and
// persistent as the user swipes between Home · Matches · Alerts.
//
// `Following` / `Discover` is presentation-only for the moment (both render
// the same feed). The backend split lives in a follow-up ticket.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:novex_clean_arch/core/theme/circk_theme.dart';
import 'package:novex_clean_arch/features/posts/presentation/widgets/post_card.dart';
import 'package:novex_clean_arch/core/widgets/v2/v2_modals.dart';
import 'package:novex_clean_arch/features/posts/domain/entities/post.dart';
import 'package:novex_clean_arch/features/posts/domain/entities/post_media.dart';
import 'package:novex_clean_arch/features/posts/presentation/controllers/feed_controller.dart';
import 'package:novex_clean_arch/features/posts/presentation/screens/photo_viewer_screen.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key, this.onOpenProfile});

  /// Fires when a feed author is tapped, with their @username. The router
  /// pushes `/u/<username>` to open the public profile.
  final ValueChanged<String>? onOpenProfile;

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _scroll = ScrollController();
  _FeedScope _scope = _FeedScope.following;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider);
    return ColoredBox(
      color: CkColors.paper,
      child: Column(
        children: [
          _ScopeToggle(
            active: _scope,
            onSelect: (s) => setState(() => _scope = s),
          ),
          Expanded(
            child: RefreshIndicator(
              color: CkColors.ink,
              onRefresh: () =>
                  ref.read(feedControllerProvider.notifier).refresh(),
              child: switch (feed) {
                AsyncData(:final value) => _dataList(value),
                AsyncError(:final error) =>
                    _scrollable([_ErrorState(error: error)]),
                _ => _scrollable(const [_Loader()]),
              },
            ),
          ),
        ],
      ),
    );
  }

  // A single-child scroll so RefreshIndicator always has a scrollable child.
  Widget _scrollable(List<Widget> children) => ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      );

  Widget _dataList(List<Post> posts) {
    final hasMore = ref.read(feedControllerProvider.notifier).hasMore;
    if (posts.isEmpty) {
      return _scrollable(const [_EmptyState()]);
    }
    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: posts.length + 1,
      itemBuilder: (context, i) {
        if (i == posts.length) {
          return hasMore ? const _Loader() : const _FeedFooter();
        }
        final post = posts[i];
        return RepaintBoundary(
          child: FeedPostCard(
            post: post,
            onComment: () => showCommentsSheet(context),
            onAuthorTap: (username) => widget.onOpenProfile?.call(username),
            onOpenPhoto: (index) => _openPhoto(post.media, index),
          ),
        );
      },
    );
  }

  void _openPhoto(List<PostMedia> media, int index) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewerScreen(media: media, initialIndex: index),
      ),
    );
  }
}

// ─── Following / Discover toggle ──────────────────────────────────────
// Two pills under the GlobalHeader, defaulting to Following. UI-only for
// now — both render the same feed; the server-side split is a follow-up
// (the FeedController + posts repo need a `scope` param).
enum _FeedScope { following, discover }

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.active, required this.onSelect});

  final _FeedScope active;
  final ValueChanged<_FeedScope> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          _pill('Following', active == _FeedScope.following,
              () => onSelect(_FeedScope.following)),
          const SizedBox(width: 6),
          _pill('Discover', active == _FeedScope.discover,
              () => onSelect(_FeedScope.discover)),
        ],
      ),
    );
  }

  Widget _pill(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? CkColors.ink : CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: on ? FontWeight.w700 : FontWeight.w600,
            color: on ? CkColors.paper : CkColors.ink2,
          ),
        ),
      ),
    );
  }
}

// ─── states ───────────────────────────────────────────
class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: CkColors.muted),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 48, 18, 48),
        child: Column(
          children: [
            Text('No posts yet', style: CkType.display(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              'Follow captains and teams, or share the first ball.',
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 13, color: CkColors.muted),
            ),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 40, 18, 40),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: CkColors.soft, size: 30),
            const SizedBox(height: 10),
            Text("Couldn't load the feed",
                style: CkType.display(fontSize: 16)),
            const SizedBox(height: 6),
            Text('Pull to refresh and try again.',
                style: CkType.body(fontSize: 13, color: CkColors.muted)),
          ],
        ),
      );
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        alignment: Alignment.center,
        child: Text('END OF FEED · PULL TO REFRESH',
            style: CkType.mono(fontSize: 9)),
      );
}
