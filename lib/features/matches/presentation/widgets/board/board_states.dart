import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/ck_shimmer.dart';
import '../../providers/matches_board_providers.dart';
import '../pool/pool_icons.dart';
import 'board_kit.dart';

/// Nothing on — `Matches.dc.html` artboard 05.
///
/// 11am on a Tuesday, the month-one default. The screen states what lands here
/// and when, then hands the viewer the next real thing. No "follow more
/// teams!", no button to press.
class BoardEmptyState extends StatelessWidget {
  const BoardEmptyState({
    super.key,
    required this.tab,
    this.next,
    this.onOpenNext,
  });

  final MatchesBoardTab tab;

  /// The next fixture today, if there is one.
  final BoardMatch? next;
  final VoidCallback? onOpenNext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 52, 32, 0),
          child: Column(
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
                child: const PoolIcon(PoolIcons.clockMuted, size: 26),
              ),
              const SizedBox(height: 18),
              Text(
                _title(),
                textAlign: TextAlign.center,
                style: CkType.display(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                  letterSpacing: -0.01,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 290,
                child: Text(
                  _body(),
                  textAlign: TextAlign.center,
                  style: CkType.body(
                    fontSize: 13,
                    height: 1.6,
                    color: CkColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (next case final n?) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 9),
            child: Text(
              'NEXT UP · TODAY',
              style: CkType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.10,
                color: CkColors.muted,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: UpcomingMatchRow(item: n, onTap: onOpenNext),
          ),
        ],
        // The "For you" rule, printed verbatim wherever the tab can be empty,
        // so it is explainable in one sentence rather than inferred.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CkColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHAT “FOR YOU” MEANS',
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.ink2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'A match is For you when a team or player you follow is '
                  'playing, or when it belongs to a tournament you are '
                  'registered in or organising.',
                  style: CkType.body(
                    fontSize: 12.5,
                    height: 1.6,
                    color: CkColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _title() => switch (tab) {
        MatchesBoardTab.live => 'No match is on right now',
        MatchesBoardTab.forYou => 'Nothing here for you yet',
        MatchesBoardTab.upcoming => 'No matches scheduled',
        MatchesBoardTab.finished => 'No matches finished this week',
      };

  String _body() => switch (tab) {
        MatchesBoardTab.live =>
          'Local cricket starts in the afternoon. Matches appear here the '
              'moment a scorer opens one, and the tab counts them while they '
              'run.',
        MatchesBoardTab.forYou =>
          'Follow a team, or join a tournament, and their matches will show '
              'up here.',
        MatchesBoardTab.upcoming =>
          'Nothing is on the calendar for the next seven days.',
        MatchesBoardTab.finished =>
          'Results from the last seven days land here once a match is over.',
      };
}

/// Loading — `Matches.dc.html` artboard 06.
///
/// Skeletons carry the real geometry: 28px group crest, two 22px team rows, a
/// state strip. Tabs render immediately because they are local state, not data.
class BoardLoadingState extends StatelessWidget {
  const BoardLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const CkShimmer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GroupSkeleton(cards: 2),
            SizedBox(height: 16),
            _GroupSkeleton(cards: 1),
          ],
        ),
      ),
    );
  }
}

class _GroupSkeleton extends StatelessWidget {
  const _GroupSkeleton({required this.cards});

  final int cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            CkShimmerBox(width: 28, height: 28, radius: 8),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    alignment: Alignment.centerLeft,
                    child: CkShimmerBox(height: 12, radius: 5),
                  ),
                  SizedBox(height: 7),
                  FractionallySizedBox(
                    widthFactor: 0.28,
                    alignment: Alignment.centerLeft,
                    child: CkShimmerBox(height: 8, radius: 5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        for (var i = 0; i < cards; i++) ...[
          const _CardSkeleton(),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(13, 10, 13, 4),
            child: FractionallySizedBox(
              widthFactor: 0.52,
              alignment: Alignment.centerLeft,
              child: CkShimmerBox(height: 9, radius: 5),
            ),
          ),
          _TeamSkeleton(),
          _TeamSkeleton(),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}

class _TeamSkeleton extends StatelessWidget {
  const _TeamSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      child: Row(
        children: [
          CkShimmerBox(width: 22, height: 22, radius: 6),
          SizedBox(width: 9),
          Expanded(child: CkShimmerBox(height: 12, radius: 5)),
          SizedBox(width: 9),
          CkShimmerBox(width: 52, height: 14, radius: 5),
        ],
      ),
    );
  }
}

/// Error — `Matches.dc.html` artboard 07.
///
/// Calm, matching Pool's error geometry. Red is spent only on the small
/// failure dot. Scores are cacheable, so the last-known state is offered as a
/// fallback rather than an empty page.
class BoardErrorState extends StatelessWidget {
  const BoardErrorState({
    super.key,
    required this.onRetry,
    this.onShowLast,
    this.code,
  });

  final VoidCallback onRetry;
  final VoidCallback? onShowLast;
  final String? code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 34, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CkColors.line),
                ),
                child: const PoolIcon(PoolIcons.disconnected, size: 26),
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: CkColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.paper, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "Couldn't load the board",
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
              "We couldn't reach matchday just now. Live scores need a "
              'connection — check yours and try again.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                height: 1.6,
                color: CkColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _Button(
            label: 'Retry',
            icon: PoolIcons.retry,
            filled: true,
            onTap: onRetry,
          ),
          if (onShowLast != null) ...[
            const SizedBox(height: 11),
            _Button(label: 'Show last loaded scores', onTap: onShowLast!),
          ],
          if (code != null) ...[
            const SizedBox(height: 14),
            Text(
              code!.toUpperCase(),
              textAlign: TextAlign.center,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
                color: CkColors.soft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(filled ? 15 : 14),
        decoration: BoxDecoration(
          color: filled ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: CkColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              PoolIcon(icon!, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: CkType.display(
                fontSize: filled ? 15 : 14,
                fontWeight: FontWeight.w600,
                color: filled ? CkColors.paper : CkColors.ink2,
                letterSpacing: -0.01,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
