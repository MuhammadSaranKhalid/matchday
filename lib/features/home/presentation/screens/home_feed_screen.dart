// Home feed — data-driven from the real `posts` feature (online-only).
//
// Keeps the v2 chrome (header, filter chips, live-now rail) and renders posts
// via a virtualized ListView.builder with pull-to-refresh + keyset pagination.
// Photos load through CkFeedImage (cached, sized decode, blurhash placeholder).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:matchday/core/theme/circk_theme.dart';
import 'package:matchday/features/posts/presentation/widgets/pending_post_card.dart';
import 'package:matchday/features/posts/presentation/widgets/post_card.dart';
import 'package:matchday/core/widgets/modals/modals.dart';
import 'package:matchday/features/posts/domain/entities/post_media.dart';
import 'package:matchday/features/posts/presentation/controllers/feed_controller.dart';
import 'package:matchday/features/posts/presentation/controllers/post_query_state.dart';
import 'package:matchday/features/posts/presentation/providers/post_store_provider.dart';
import 'package:matchday/features/posts/presentation/providers/posts_providers.dart';
import 'package:matchday/core/widgets/v2/ck_shimmer.dart';
import 'package:matchday/features/posts/presentation/screens/photo_viewer_screen.dart';
import 'package:matchday/features/posts/presentation/widgets/post_card_skeleton.dart';
import '../widgets/live_match_rail.dart';

// ─── Temporary visibility flags ──────────────────────────────────────────
//
// Both the live-match cards rail and the feed-filter chip row are toggled
// via flags. The live-match cards rail is currently parked.
//
//   • _kShowLiveCards   — ticket #1 (Hide live match cards from home page)
//   • _kShowFeedFilters — ticket #2 (Show feed filter chip row from home page)
const bool _kShowLiveCards = false;
const bool _kShowFeedFilters = true;

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key, this.onBell, this.onOpenProfile});

  // ─────────────────────────────────────────────────────────────────────
  // onOpenProfile is fired with the tapped author's @username — the host
  // route should push `/u/<username>` to open their public profile.

  final VoidCallback? onBell;
  final ValueChanged<String>? onOpenProfile;

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _scroll = ScrollController();

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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 1500) {
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
          if (_kShowFeedFilters) const FeedFilters(),
          Expanded(
            child: RefreshIndicator(
              color: CkColors.ink,
              onRefresh: () =>
                  ref.read(feedControllerProvider.notifier).refresh(),
              child: switch (feed) {
                AsyncData(:final value) => _dataList(value),
                AsyncError(:final error) => _scrollable([
                    if (_kShowLiveCards) const LiveMatchRail(),
                    _ErrorState(error: error),
                  ]),
                _ => const FeedShimmerSkeleton(),
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

  Widget _dataList(PostQueryState queryState) {
    final pendingPosts = ref.watch(pendingPostsProvider).value ?? const [];
    final totalCount = 1 + pendingPosts.length + queryState.ids.length + 1;

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: totalCount,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _kShowLiveCards ? const LiveMatchRail() : const SizedBox.shrink();
        }
        final pendingIndex = i - 1;
        if (pendingIndex < pendingPosts.length) {
          return PendingPostCard(pendingPost: pendingPosts[pendingIndex]);
        }
        final postIndex = pendingIndex - pendingPosts.length;
        if (postIndex < queryState.ids.length) {
          final postId = queryState.ids[postIndex];
          final post = ref.watch(postFromStoreProvider(postId));
          if (post == null) return const SizedBox.shrink();

          return RepaintBoundary(
            child: FeedPostCard(
              post: post,
              onComment: () => showCommentsSheet(
                context,
                postId: post.id.value,
                postAuthorHandle: post.authorUsername != null && post.authorUsername!.isNotEmpty
                    ? '@${post.authorUsername}'
                    : post.authorName,
                onOpenProfile: (username) => widget.onOpenProfile?.call(username),
              ),
              onAuthorTap: (username) => widget.onOpenProfile?.call(username),
              onOpenPhoto: (index) => _openPhoto(post.media, index),
            ),
          );
        }
        if (queryState.ids.isEmpty && pendingPosts.isEmpty) return const _EmptyState();
        return queryState.hasMore ? const _Loader() : const _FeedFooter();
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

// ─── feed filters (static chip row) ───────────────────
class FeedFilters extends ConsumerWidget {
  const FeedFilters({super.key});

  static const _labels = ['All', 'People', 'Teams', 'Tournaments', 'Matches'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(feedFilterProvider);
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        itemCount: _labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final label = _labels[i];
          final k = label.toLowerCase();
          final isActive = active == k;
          return GestureDetector(
            onTap: () => ref.read(feedFilterProvider.notifier).setFilter(k),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isActive ? CkColors.ink : CkColors.paper,
                borderRadius: BorderRadius.circular(999),
                border:
                    isActive ? null : Border.all(color: CkColors.hairline),
              ),
              child: Text(
                label.toUpperCase(),
                style: CkType.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: isActive ? CkColors.paper : CkColors.ink2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── states ───────────────────────────────────────────
class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const CkShimmer(
        child: PostCardSkeleton(hasMedia: false),
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
        decoration:
            const BoxDecoration(border: Border(top: BorderSide(color: CkColors.hairline))),
        alignment: Alignment.center,
        child: Text('END OF FEED · PULL TO REFRESH',
            style: CkType.mono(fontSize: 9)),
      );
}
