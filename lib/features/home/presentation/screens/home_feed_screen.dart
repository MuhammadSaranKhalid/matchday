// Home feed — data-driven from the real `posts` feature (online-only).
//
// Keeps the v2 chrome (header, filter chips, live-now rail) and renders posts
// via a virtualized ListView.builder with pull-to-refresh + keyset pagination.
// Photos load through CkFeedImage (cached, sized decode, blurhash placeholder).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:novex_clean_arch/core/theme/circk_theme.dart';
import 'package:novex_clean_arch/features/posts/presentation/widgets/post_card.dart';
import 'package:novex_clean_arch/core/widgets/v2/v2_kit.dart';
import 'package:novex_clean_arch/core/widgets/v2/v2_modals.dart';
import 'package:novex_clean_arch/features/posts/domain/entities/post.dart';
import 'package:novex_clean_arch/features/posts/domain/entities/post_media.dart';
import 'package:novex_clean_arch/features/posts/presentation/controllers/feed_controller.dart';
import 'package:novex_clean_arch/features/posts/presentation/screens/photo_viewer_screen.dart';

// ─── Temporary visibility flags ──────────────────────────────────────────
//
// Both the live-match cards rail and the feed-filter chip row are hidden
// temporarily — neither has its underlying data/behaviour wired yet, and
// they were taking up visual space without serving the user. Flip either
// flag to `true` to re-enable.
//
//   • _kShowLiveCards   — ticket #1 (Hide live match cards from home page)
//   • _kShowFeedFilters — ticket #2 (Hide feed filter chip row from home page)
//
// The widget classes (`_LiveRail`, `_LiveCard`, `FeedFilters`) stay defined
// below so re-enabling is a one-line change. They are referenced from the
// const-false branches below, which keeps the analyzer's unused-element
// check happy.
const bool _kShowLiveCards = false;
const bool _kShowFeedFilters = false;

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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider);
    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            V2Header(
              title: 'Home',
              onBell: widget.onBell,
            ),
            if (_kShowFeedFilters) const FeedFilters(),
            Expanded(
              child: RefreshIndicator(
                color: CkColors.ink,
                onRefresh: () =>
                    ref.read(feedControllerProvider.notifier).refresh(),
                child: switch (feed) {
                  AsyncData(:final value) => _dataList(value),
                  AsyncError(:final error) => _scrollable([
                      if (_kShowLiveCards) const _LiveRail(),
                      _ErrorState(error: error),
                    ]),
                  _ => _scrollable([
                      if (_kShowLiveCards) const _LiveRail(),
                      const _Loader(),
                    ]),
                },
              ),
            ),
          ],
        ),
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
    // [LiveRail] + posts + [footer]. LiveRail collapses to SizedBox.shrink
    // while _kShowLiveCards is false so itemCount + indexing stay constant —
    // re-enabling is a one-line flag flip with no surrounding changes.
    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: posts.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _kShowLiveCards ? const _LiveRail() : const SizedBox.shrink();
        }
        if (i == posts.length + 1) {
          if (posts.isEmpty) return const _EmptyState();
          return hasMore ? const _Loader() : const _FeedFooter();
        }
        final post = posts[i - 1];
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

// ─── feed filters (static chip row) ───────────────────
class FeedFilters extends StatefulWidget {
  const FeedFilters({super.key, this.active = 'all'});
  final String active;
  @override
  State<FeedFilters> createState() => _FeedFiltersState();
}

class _FeedFiltersState extends State<FeedFilters> {
  static const _labels = ['All', 'People', 'Teams', 'Tournaments', 'Matches'];
  late String _active = widget.active;

  @override
  Widget build(BuildContext context) {
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
          final isActive = _active == k;
          return GestureDetector(
            onTap: () => setState(() => _active = k),
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

// ─── live-now rail ────────────────────────────────────
class _LiveRail extends StatelessWidget {
  const _LiveRail();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Container(
        decoration: BoxDecoration(
          color: CkColors.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: CkColors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE NOW · 2',
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  'see all →',
                  style: CkType.body(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 66,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _LiveCard(
                    aShort: 'LL',
                    aColor: CkCrest.ll,
                    bShort: 'KC',
                    bColor: CkCrest.kc,
                    aScore: '142/6',
                    bScore: '119/9',
                    need: 'L need 24 (12)',
                  ),
                  SizedBox(width: 8),
                  _LiveCard(
                    aShort: 'MT',
                    aColor: CkCrest.mt,
                    bShort: 'OB',
                    bColor: CkCrest.ob,
                    aScore: '98/2',
                    bScore: '—',
                    need: 'MT 12.4 ov',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.aShort,
    required this.aColor,
    required this.bShort,
    required this.bColor,
    required this.aScore,
    required this.bScore,
    required this.need,
  });

  final String aShort;
  final Color aColor;
  final String bShort;
  final Color bColor;
  final String aScore;
  final String bScore;
  final String need;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Crest(short: aShort, color: aColor, size: 22, radius: 5),
              const SizedBox(width: 8),
              Text(
                aScore,
                style: CkType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                bScore,
                style: CkType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Crest(short: bShort, color: bColor, size: 22, radius: 5),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            need,
            style: CkType.body(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
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
            child: CircularProgressIndicator(strokeWidth: 2, color: CkColors.muted),
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
        decoration:
            const BoxDecoration(border: Border(top: BorderSide(color: CkColors.hairline))),
        alignment: Alignment.center,
        child: Text('END OF FEED · PULL TO REFRESH',
            style: CkType.mono(fontSize: 9)),
      );
}
