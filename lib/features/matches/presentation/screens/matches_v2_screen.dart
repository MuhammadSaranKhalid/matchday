import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/match.dart';
import '../providers/matches_board_providers.dart';
import '../widgets/board/board_kit.dart';
import '../widgets/board/board_states.dart';
import '../widgets/board/match_score_row.dart';

/// The Matches tab (`/matches`) — the world's match board.
///
/// Ported from `Matches.dc.html` sections A and B.
///
/// **Bottom nav is the world; the side panel is you.** This tab no longer
/// lists the signed-in user's own matches — "My matches" is a you-noun and
/// lives in the side panel. What is here is what is being played around you:
/// predominantly tournament fixtures, plus public friendlies.
///
/// Grouped by competition, never flat, because that is how cricket is
/// actually followed. The tab creates nothing: no FAB, no "+ Match".
///
/// [AppShell] supplies the Scaffold, the "Matches" header and the nav bar, so
/// this renders a bare tab body.
class MatchesV2Screen extends ConsumerStatefulWidget {
  const MatchesV2Screen({super.key});

  @override
  ConsumerState<MatchesV2Screen> createState() => _MatchesV2ScreenState();
}

class _MatchesV2ScreenState extends ConsumerState<MatchesV2Screen> {
  /// Groups the viewer folded, by tournament id. Local and deliberately not
  /// persisted — a fold is a glance, not a preference.
  final _collapsed = <String>{};

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(matchesBoardTabControllerProvider);
    final board = ref.watch(matchesBoardProvider(tab));

    // The count is of the whole board, so it survives an error or an empty
    // cut of the currently selected tab.
    final liveCount = board.value?.liveCount ?? 0;

    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            BoardTabs(
              selected: tab,
              liveCount: liveCount,
              onSelect:
                  (t) => ref
                      .read(matchesBoardTabControllerProvider.notifier)
                      .select(t),
            ),
            Expanded(
              child: RefreshIndicator(
                color: CkColors.ink,
                backgroundColor: CkColors.paper,
                onRefresh: () async {
                  ref.invalidate(matchesBoardProvider);
                  await ref.read(matchesBoardProvider(tab).future);
                },
                child: switch (board) {
                  AsyncLoading(hasValue: false) => const _Scroll(
                    child: BoardLoadingState(),
                  ),
                  AsyncError(hasValue: false) => _Scroll(
                    fill: true,
                    child: BoardErrorState(
                      onRetry: () => ref.invalidate(matchesBoardProvider),
                      code: 'Error · matches_unavailable',
                    ),
                  ),
                  AsyncValue(value: final view?) when view.isEmpty =>
                    BoardEmptyState(tab: tab),
                  AsyncValue(value: final view?) => _Board(
                    view: view,
                    collapsed: _collapsed,
                    onToggle:
                        (id) => setState(() {
                          if (!_collapsed.remove(id)) _collapsed.add(id);
                        }),
                  ),
                  _ => const _Scroll(child: BoardLoadingState()),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The populated board — artboards 01, 03 and 04.
class _Board extends StatelessWidget {
  const _Board({
    required this.view,
    required this.collapsed,
    required this.onToggle,
  });

  final MatchesBoardView view;
  final Set<String> collapsed;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        for (final group in view.groups) ...[
          _Group(
            group: group,
            collapsed: collapsed.contains(_key(group)),
            onToggle: () => onToggle(_key(group)),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  static String _key(BoardGroup g) => g.tournament?.id ?? '__friendlies__';
}

class _Group extends StatelessWidget {
  const _Group({
    required this.group,
    required this.collapsed,
    required this.onToggle,
  });

  final BoardGroup group;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BoardGroupHeader(
          group: group,
          collapsed: collapsed,
          onToggle: onToggle,
          onOpen:
              group.tournament == null
                  ? null
                  : () => context.push('/tournaments/${group.tournament!.id}'),
        ),
        if (!collapsed)
          for (final item in group.matches) ...[
            const SizedBox(height: 9),
            // Upcoming fixtures have no score, so the time becomes the figure.
            if (item.match.status == MatchStatus.scheduled)
              UpcomingMatchRow(item: item, onTap: () => _open(context, item))
            else
              MatchScoreRow(item: item, onTap: () => _open(context, item)),
          ],
      ],
    );
  }

  void _open(BuildContext context, BoardMatch item) =>
      context.push('/matches/${item.match.id.value}');
}

/// Keeps every state pull-to-refreshable, including the short ones.
class _Scroll extends StatelessWidget {
  const _Scroll({required this.child, this.fill = false});

  final Widget child;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (fill)
          SliverFillRemaining(hasScrollBody: false, child: Center(child: child))
        else
          SliverToBoxAdapter(child: child),
      ],
    );
  }
}
