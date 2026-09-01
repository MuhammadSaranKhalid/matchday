import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../providers/match_pool_providers.dart';
import '../providers/matches_feed_providers.dart';
import '../widgets/pool/pool_challenge_card.dart';
import '../widgets/pool/pool_facet_bar.dart';
import '../widgets/pool/pool_states.dart';
import '../widgets/pool/share_code_sheet.dart';

/// The Pool tab (`/pool`) — the open match board.
///
/// Ported from `Pool.dc.html` section A (artboards 01–05).
///
/// The board is the world and nothing else: facets, then challenges. It
/// creates nothing — not a challenge, not even a team. Posting and your own
/// challenges are you-nouns and live in the side panel, which is why there is
/// no create button, no "Looking for a match?" banner and no My-challenges row
/// here. Bottom nav is the world; the side panel is you.
///
/// [AppShell] supplies the Scaffold, the "Pool" header and the nav bar, so
/// this renders a bare tab body.
class OpenMatchPoolScreen extends ConsumerWidget {
  const OpenMatchPoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canTakePart = ref.watch(viewerManagesTeamProvider);
    final board = ref.watch(filteredOpenMatchPoolProvider);

    Future<void> refresh() async {
      ref.invalidate(openMatchPoolProvider);
      ref.invalidate(viewerManagesTeamProvider);
      await ref.read(filteredOpenMatchPoolProvider.future);
    }

    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: CkColors.ink,
          backgroundColor: CkColors.paper,
          onRefresh: refresh,
          child: _body(context, ref, canTakePart, board, refresh),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<bool> canTakePart,
    AsyncValue<List<OpenMatchPoolItem>> board,
    Future<void> Function() refresh,
  ) {
    // Loading and error are first-load states only. A pull-to-refresh re-emits
    // AsyncLoading over a board that is already on screen, and swapping it for
    // skeletons under the indicator's own spinner would be a flash, not
    // feedback — so anything holding a value keeps rendering it.
    final settling =
        (canTakePart.isLoading && !canTakePart.hasValue) ||
        (board.isLoading && !board.hasValue);
    if (settling) return const _Scroll(child: PoolLoadingState());

    final broken =
        (canTakePart.hasError && !canTakePart.hasValue) ||
        (board.hasError && !board.hasValue);
    if (broken) {
      return _Scroll(
        fill: true,
        child: PoolErrorState(
          onRetry: refresh,
          code: 'Error · pool_unavailable',
        ),
      );
    }

    // Artboard 05 — manages no team, so nothing on the board is actionable.
    if (canTakePart.value == false) return const _NoTeamBoard();

    return _Board(
      items: board.value ?? const [],
      facet: ref.watch(openMatchPoolFilterProvider),
      onSelect: (f) =>
          ref.read(openMatchPoolFilterProvider.notifier).setFilter(f),
      onEnterCode: () => showShareCodeSheet(context),
    );
  }
}

/// Artboard 01 — the populated board, and its empty / filtered-empty forms.
class _Board extends ConsumerWidget {
  const _Board({
    required this.items,
    required this.facet,
    required this.onSelect,
    required this.onEnterCode,
  });

  final List<OpenMatchPoolItem> items;
  final PoolFacet facet;
  final ValueChanged<PoolFacet> onSelect;
  final VoidCallback onEnterCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A board emptied by a facet is not an empty board. Artboard 02 speaks for
    // a genuinely quiet pool, so only show it when nothing is filtered out —
    // otherwise the facets have to stay reachable to undo the cut.
    final unfiltered = ref.watch(openMatchPoolProvider).value ?? items;

    if (items.isEmpty && unfiltered.isEmpty) {
      return _Scroll(child: PoolEmptyState(onEnterCode: onEnterCode));
    }

    return _Scroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PoolFacetBar(selected: facet, onSelect: onSelect),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 40),
              child: Text(
                'No open challenges under ${facet.label}.',
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 13, color: CkColors.muted),
              ),
            )
          else ...[
            _SectionLabel('Open challenges · ${items.length}'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
              child: Column(
                children: [
                  for (final item in items) ...[
                    PoolChallengeCard(
                      item: item,
                      onTap: () => context.push(
                        '/challenges/${item.request.id.value}',
                      ),
                    ),
                    if (item != items.last) const SizedBox(height: 11),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Artboard 05 — the board read-only behind the paper gate.
class _NoTeamBoard extends ConsumerWidget {
  const _NoTeamBoard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(openMatchPoolProvider).value ?? const [];

    return _Scroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PoolNoTeamGate(),
          if (items.isNotEmpty) ...[
            const _SectionLabel("What's on the board", top: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Column(
                children: [
                  for (final item in items) ...[
                    PoolChallengeCard(item: item, dimmed: true),
                    if (item != items.last) const SizedBox(height: 11),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Text(
                'Browse only · join a team to apply'.toUpperCase(),
                textAlign: TextAlign.center,
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06,
                  color: CkColors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The board's one section header treatment — mono, wide-tracked, muted.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.top = 0});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: CkType.mono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.10,
          color: CkColors.muted,
        ),
      ),
    );
  }
}

/// Keeps every board state pull-to-refreshable, including the short ones that
/// would otherwise not scroll far enough to arm the gesture.
///
/// Only [fill] uses [SliverFillRemaining] — it measures its child's intrinsic
/// height, which the skeletons deliberately cannot report.
class _Scroll extends StatelessWidget {
  const _Scroll({required this.child, this.fill = false});

  final Widget child;

  /// Centre the child in the remaining viewport (the error state).
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (fill)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: child),
          )
        else
          SliverToBoxAdapter(child: child),
      ],
    );
  }
}
