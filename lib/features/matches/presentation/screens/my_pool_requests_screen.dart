import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_push_nav.dart';
import '../providers/match_pool_providers.dart';
import '../widgets/host/host_kit.dart';
import '../widgets/host/my_challenge_card.dart';
import '../widgets/pool/pool_icons.dart';
import '../widgets/pool/pool_states.dart';

/// My challenges (`/my/pool-requests`) — `Pool.dc.html` artboards 12 and 13.
///
/// The host's own fixtures. This is a you-noun, so it is reached from the side
/// panel rather than the bottom nav, and unlike the Pool board it *does*
/// create: posting starts here.
class MyPoolRequestsScreen extends ConsumerWidget {
  const MyPoolRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(myChallengesProvider);

    // This screen is the pool's own surface, so both CTAs post an open
    // challenge. The wizard drops its open-vs-direct step accordingly.
    void post() => context.push('/matches/send-challenge?mode=open');

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: CkPushNav(
              title: 'My Challenges',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/pool'),
              // The create action stays pinned at the bottom (artboard 12), so
              // the nav's trailing slot carries the live count instead.
              action: switch (view) {
                AsyncData(value: final v) when v.live.isNotEmpty =>
                  CkNavCount('${v.live.length} live'),
                _ => null,
              },
            ),
          ),
          Expanded(
            child: switch (view) {
              AsyncLoading() => const _Scroll(child: PoolLoadingState()),
              AsyncError(:final error) => Center(
                  child: PoolErrorState(
                    onRetry: () => ref.invalidate(myChallengesProvider),
                    code: error.toString(),
                  ),
                ),
              AsyncData(value: final v) when v.isEmpty =>
                _Empty(onPost: post),
              AsyncData(value: final v) => _List(view: v),
            },
          ),
          if (view.value?.isEmpty == false)
            HostBottomBar(
              child: HostActionButton(
                label: 'New challenge',
                icon: PoolIcons.plusPaper,
                onTap: post,
              ),
            ),
        ],
      ),
    );
  }
}

/// Artboard 12 — live challenges, then the settled ledger.
class _List extends ConsumerWidget {
  const _List({required this.view});

  final MyChallengesView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(String id) => context.push('/challenges/$id');

    return RefreshIndicator(
      color: CkColors.ink,
      backgroundColor: CkColors.paper,
      onRefresh: () async {
        ref.invalidate(myChallengesProvider);
        await ref.read(myChallengesProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          for (final row in view.live) ...[
            MyChallengeCard(
              row: row,
              onTap: () => open(row.request.id.value),
            ),
            const SizedBox(height: 13),
          ],
          if (view.past.isNotEmpty) ...[
            const HostSectionLabel(
              'Past · closed',
              padding: EdgeInsets.symmetric(vertical: 4),
            ),
            const SizedBox(height: 4),
            for (final row in view.past) ...[
              PastChallengeRow(
                row: row,
                onTap: () => open(row.request.id.value),
              ),
              const SizedBox(height: 13),
            ],
          ],
        ],
      ),
    );
  }
}

/// Artboard 13 — nothing posted yet. Unlike the Pool board's empty state this
/// one *does* route into the wizard: creating is what this screen is for.
class _Empty extends StatelessWidget {
  const _Empty({required this.onPost});

  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 34, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CkColors.line),
            ),
            child: const PoolIcon(PoolIcons.silentBoardMuted, size: 26),
          ),
          const SizedBox(height: 18),
          Text(
            'No challenges yet',
            textAlign: TextAlign.center,
            style: CkType.display(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CkColors.ink,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 270,
            child: Text(
              'Post an open challenge to the pool and any team can apply. '
              "You'll manage applicants right here.",
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                height: 1.6,
                color: CkColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: HostActionButton(label: 'Post a challenge', onTap: onPost),
          ),
        ],
      ),
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SingleChildScrollView(child: child);
}
