import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/error/failures.dart';
import '../providers/challenges_providers.dart';
import '../providers/my_matches_providers.dart';
import '../state/challenges_view.dart';
import '../state/my_matches_view.dart';
import '../widgets/challenges/challenges_nav_button.dart';
import '../widgets/my_matches/fixture_card.dart';
import '../widgets/my_matches/past_card.dart';

/// My Matches — implements `My Matches.dc.html`.
///
/// A pushed page reached from the drawer. It lists **only matches that exist**:
/// challenges are a negotiation, not a fixture, and they live on their own
/// screen. The only trace of them here is the badged header icon and — when
/// something is genuinely about to expire — a cream banner.
class MyMatchesScreen extends ConsumerStatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  ConsumerState<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends ConsumerState<MyMatchesScreen> {
  bool _confirmedTab = true;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myMatchesViewProvider);
    return ScreenLayout(
      header: PushHeader(
        title: 'My Matches',
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
        actions: [
          const ChallengesNavButton(),
          const SizedBox(width: Spacing.xs),
          ActionButton(
            label: 'CHALLENGE',
            icon: const Icon(Icons.add, size: 16),
            size: ControlSize.compact,
            expand: false,
            onPressed: () => context.push('/challenge'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const _Skeleton(),
        error:
            (e, _) => StateRegion(
              child: ErrorState(
                title: "Couldn't load your matches",
                description:
                    e is FailureWrapper
                        ? e.failure.message
                        : 'Nothing has been lost — fixtures, lineups and scorecards all '
                            'live on the server. Check your connection and try again.',
                onRetry: () => ref.invalidate(myMatchesViewProvider),
              ),
            ),
        data: _body,
      ),
    );
  }

  Widget _body(MyMatchesView view) {
    // First run: tabs are suppressed, exactly as on the Challenges board —
    // two empty tabs is a filing cabinet with no files.
    if (view.confirmed.isEmpty && view.past.isEmpty) {
      return StateRegion(
        child: EmptyState(
          kind: EmptyStateKind.firstRun,
          icon: Icons.sports_cricket,
          title: 'No matches yet',
          description:
              'Every fixture starts as a challenge: propose a day, a ground '
              'and a format, and it appears here the moment the other manager '
              'accepts.',
          primaryAction: StateAction(
            label: 'Challenge a team',
            onPressed: () => context.push('/challenge'),
          ),
          secondaryAction: StateAction(
            label: 'Post to the open pool',
            onPressed: () => context.push('/matches/send-challenge?mode=open'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.sm,
            Spacing.md,
            Spacing.xs,
          ),
          child: Row(
            children: [
              SelectionChip(
                label: 'Confirmed',
                count: view.confirmed.length,
                selected: _confirmedTab,
                onPressed: () => setState(() => _confirmedTab = true),
              ),
              const SizedBox(width: Spacing.xs),
              SelectionChip(
                label: 'Past',
                count: view.totalPastCount,
                selected: !_confirmedTab,
                onPressed: () => setState(() => _confirmedTab = false),
              ),
            ],
          ),
        ),
        const _ChallengesBanner(),
        Expanded(
          child: RefreshIndicator.adaptive(
            onRefresh: () async {
              ref.invalidate(myMatchesViewProvider);
              await ref.read(myMatchesViewProvider.future);
            },
            child: _confirmedTab ? _confirmedBody(view) : _pastBody(view),
          ),
        ),
      ],
    );
  }

  Widget _confirmedBody(MyMatchesView view) {
    if (view.confirmed.isEmpty) {
      final needs =
          ref.watch(challengesViewProvider).value?.needsYou ??
          const <ChallengeRow>[];
      return StateRegion(
        child: EmptyState(
          kind: EmptyStateKind.filtered,
          icon: Icons.calendar_today_outlined,
          title: 'Nothing on the schedule',
          description:
              needs.isEmpty
                  ? 'Fixtures appear here once a challenge is accepted.'
                  : 'Fixtures appear here once a challenge is accepted. Send one, or '
                      'answer the ${needs.length} already waiting on you.',
          primaryAction: StateAction(
            label: 'Challenge a team',
            onPressed: () => context.push('/challenge'),
          ),
          secondaryAction:
              needs.isNotEmpty
                  ? StateAction(
                    label:
                        needs.length == 1
                            ? '1 challenge needs you'
                            : '${needs.length} challenges need you',
                    onPressed: () => context.push('/my/challenges'),
                  )
                  : null,
        ),
      );
    }
    final groups = _groupByDay(view.confirmed, (c) => c.startTime);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm,
        Spacing.md,
        Spacing.xl,
      ),
      children: [
        for (final g in groups) ...[
          _DateRule(label: g.label, first: g == groups.first),
          const SizedBox(height: Spacing.sm),
          for (final c in g.items) ...[
            FixtureCard(v: c, onTap: () => _openFixture(c)),
            const SizedBox(height: Spacing.sm),
          ],
        ],
      ],
    );
  }

  Widget _pastBody(MyMatchesView view) {
    if (view.past.isEmpty) {
      return StateRegion(
        child: EmptyState(
          kind: EmptyStateKind.passive,
          icon: Icons.history,
          title: 'No past matches',
          description:
              'Scorecards land here the moment a match finishes — yours and '
              'every match you were in the squad for.',
          primaryAction:
              view.confirmed.isNotEmpty
                  ? StateAction(
                    label: 'View confirmed (${view.confirmed.length})',
                    onPressed: () => setState(() => _confirmedTab = true),
                  )
                  : null,
        ),
      );
    }
    final groups = _groupByDay(view.past, (p) => p.startTime);
    final hidden = view.totalPastCount - view.past.length;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm,
        Spacing.md,
        Spacing.xl,
      ),
      children: [
        for (final g in groups) ...[
          _DateRule(label: g.label, first: g == groups.first),
          const SizedBox(height: Spacing.sm),
          for (final p in g.items) ...[
            PastCard(
              v: p,
              onTap: () => context.push('/matches/${p.id}/summary'),
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ],
        if (hidden > 0) _SeeAll(total: view.totalPastCount),
      ],
    );
  }

  /// A live card goes to scoring; a toss-ready one to match start; anything
  /// else to the match itself.
  void _openFixture(MyMatchConfirmed c) {
    if (c.live) {
      context.push('/matches/${c.id}/score');
    } else {
      context.push('/matches/${c.id}');
    }
  }
}

// ─── Date grouping ──────────────────────────────────────────────────────────

class _DayGroup<T> {
  const _DayGroup(this.label, this.items);
  final String label;
  final List<T> items;
}

List<_DayGroup<T>> _groupByDay<T>(List<T> items, DateTime? Function(T) at) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  final buckets = <DateTime, List<T>>{};
  final undated = <T>[];
  for (final item in items) {
    final t = at(item);
    if (t == null) {
      undated.add(item);
      continue;
    }
    final key = DateTime(t.year, t.month, t.day);
    buckets.putIfAbsent(key, () => []).add(item);
  }

  final keys = buckets.keys.toList()..sort();
  final groups = [
    for (final k in keys)
      _DayGroup<T>(
        k == today
            ? 'TODAY · ${_dayLabel(k)}'
            : k == tomorrow
            ? 'TOMORROW · ${_dayLabel(k)}'
            : _dayLabel(k),
        buckets[k]!,
      ),
  ];
  if (undated.isNotEmpty) {
    groups.add(_DayGroup<T>('DATE TO BE AGREED', undated));
  }
  return groups;
}

String _dayLabel(DateTime t) {
  const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${days[t.weekday - 1]} ${t.day} ${months[t.month - 1]}';
}

class _DateRule extends StatelessWidget {
  const _DateRule({required this.label, required this.first});

  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: first ? 0 : 4),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: Palette.ink,
          ),
        ),
        const SizedBox(width: Spacing.xs),
        const Expanded(child: Divider(height: 1, color: Palette.line)),
      ],
    ),
  );
}

// ─── Urgent Challenges Banner ────────────────────────────────────────────────

class _ChallengesBanner extends ConsumerWidget {
  const _ChallengesBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needs =
        ref.watch(challengesViewProvider).value?.needsYou ??
        const <ChallengeRow>[];
    final urgent = needs.where((r) => r.tier == ExpiryTier.urgent).toList();
    if (urgent.isEmpty) return const SizedBox.shrink();

    final soonest = urgent
        .map((r) => r.remaining)
        .whereType<Duration>()
        .reduce((a, b) => a < b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, Spacing.md, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/my/challenges'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: Palette.cream,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: Palette.creamBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      needs.length == 1
                          ? '1 CHALLENGE NEEDS YOU'
                          : '${needs.length} CHALLENGES NEED YOU',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.09,
                        color: Palette.ink,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      soonest.inHours >= 1
                          ? '${urgent.length} EXPIRES IN ${soonest.inHours}H'
                          : '${urgent.length} EXPIRES IN ${soonest.inMinutes}M',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.09,
                        color: Palette.redInk,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              const Text(
                '→',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skeletons ───────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(
      Spacing.md,
      Spacing.sm,
      Spacing.md,
      Spacing.xl,
    ),
    children: const [
      ShimmerLoading(child: ShimmerBox(width: 132, height: 10, radius: 4)),
      SizedBox(height: Spacing.sm),
      _SkeletonFixture(opacity: 1, live: true),
      SizedBox(height: Spacing.sm),
      _SkeletonFixture(opacity: 0.7, live: false),
      SizedBox(height: Spacing.sm),
      _SkeletonFixture(opacity: 0.4, live: false),
    ],
  );
}

class _SkeletonFixture extends StatelessWidget {
  const _SkeletonFixture({required this.opacity, required this.live});

  final double opacity;
  final bool live;

  @override
  Widget build(BuildContext context) {
    Widget shim(Widget c) => live ? ShimmerLoading(child: c) : c;
    return Opacity(
      opacity: opacity,
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: Palette.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 84,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Palette.paper,
                border: Border(right: BorderSide(color: Palette.hairline)),
              ),
              child: shim(const ShimmerBox(width: 44, height: 16, radius: 4)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    shim(const ShimmerBox(width: 150, height: 13, radius: 4)),
                    const SizedBox(height: Spacing.xs),
                    const ShimmerBox(width: 120, height: 13, radius: 4),
                    const SizedBox(height: Spacing.xs),
                    const ShimmerBox(width: 170, height: 9, radius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── See All Footer ──────────────────────────────────────────────────────────

class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.only(top: Spacing.sm),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Palette.hairline)),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SEE ALL MATCHES',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.09,
            color: Palette.ink2,
          ),
        ),
        SizedBox(width: Spacing.xs),
        Text(
          '→',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Palette.muted,
          ),
        ),
      ],
    ),
  );
}
