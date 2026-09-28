import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_shimmer.dart';
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
///
/// That is the design's option (c): "the badged icon lives in the header
/// permanently, so the queue has a fixed, learnable address and the count is
/// always visible; the cream banner appears only when something is inside 6h."
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
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading:
              () =>
                  const _Frame(confirmed: null, past: null, child: _Skeleton()),
          error:
              (e, _) => _Frame(
                confirmed: null,
                past: null,
                child: _ErrorState(
                  message:
                      e is FailureWrapper
                          ? e.failure.message
                          : 'err_net_timeout',
                  onRetry: () => ref.invalidate(myMatchesViewProvider),
                ),
              ),
          data: _body,
        ),
      ),
    );
  }

  Widget _body(MyMatchesView view) {
    // First run: tabs are suppressed, exactly as on the Challenges board —
    // two empty tabs is a filing cabinet with no files.
    if (view.confirmed.isEmpty && view.past.isEmpty) {
      return const _Frame(confirmed: null, past: null, child: _FirstRunEmpty());
    }

    return _Frame(
      confirmed: view.confirmed.length,
      past: view.totalPastCount,
      confirmedActive: _confirmedTab,
      onSelect: (v) => setState(() => _confirmedTab = v),
      banner: const _ChallengesBanner(),
      child: RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(myMatchesViewProvider);
          await ref.read(myMatchesViewProvider.future);
        },
        child: _confirmedTab ? _confirmedBody(view) : _pastBody(view),
      ),
    );
  }

  Widget _confirmedBody(MyMatchesView view) {
    if (view.confirmed.isEmpty) {
      return _ConfirmedEmpty(
        onSwitch: () => setState(() => _confirmedTab = false),
      );
    }
    final groups = _groupByDay(view.confirmed, (c) => c.startTime);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        for (final g in groups) ...[
          _DateRule(label: g.label, first: g == groups.first),
          const SizedBox(height: 10),
          for (final c in g.items) ...[
            FixtureCard(v: c, onTap: () => _openFixture(c)),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _pastBody(MyMatchesView view) {
    if (view.past.isEmpty) {
      return _PastEmpty(
        confirmedCount: view.confirmed.length,
        onSwitch: () => setState(() => _confirmedTab = true),
      );
    }
    final groups = _groupByDay(view.past, (p) => p.startTime);
    final hidden = view.totalPastCount - view.past.length;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        for (final g in groups) ...[
          _DateRule(label: g.label, first: g == groups.first),
          const SizedBox(height: 10),
          for (final p in g.items) ...[
            PastCard(
              v: p,
              onTap: () => context.push('/matches/${p.id}/summary'),
            ),
            const SizedBox(height: 10),
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

/// "TODAY · SAT 12 SEP", "TOMORROW · SUN 13 SEP", then plain "SAT 19 SEP".
///
/// Relative and absolute, in that order, and only for the two days a person
/// plans in words: "relative alone answers 'where do I need to be?' but strands
/// you when you're arranging a lift for the 19th; absolute alone makes you
/// count." Pushing it to "in 3 days" would be arithmetic dressed as language.
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
          style: CkType.mono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: CkColors.ink,
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(child: Divider(height: 1, color: CkColors.line)),
      ],
    ),
  );
}

// ─── Chrome ─────────────────────────────────────────────────────────────────

class _Frame extends StatelessWidget {
  const _Frame({
    required this.confirmed,
    required this.past,
    required this.child,
    this.confirmedActive = true,
    this.onSelect,
    this.banner,
  });

  /// Null on loading / error / first-run — the tabs are suppressed entirely.
  final int? confirmed;
  final int? past;
  final bool confirmedActive;
  final ValueChanged<bool>? onSelect;
  final Widget? banner;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Header(),
      if (confirmed != null && past != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _Tabs(
            confirmedActive: confirmedActive,
            confirmed: confirmed!,
            past: past!,
            onSelect: onSelect ?? (_) {},
          ),
        ),
      if (banner != null) banner!,
      Expanded(child: child),
    ],
  );
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: CkColors.hairline)),
    ),
    child: Row(
      children: [
        InkWell(
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 17, color: CkColors.ink),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'My Matches',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.022,
              color: CkColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const ChallengesNavButton(),
        const SizedBox(width: 8),
        _CreatePill(onTap: () => context.push('/challenge')),
      ],
    ),
  );
}

class _CreatePill extends StatelessWidget {
  const _CreatePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+',
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CkColors.paper,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'CHALLENGE',
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: CkColors.paper,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.confirmedActive,
    required this.confirmed,
    required this.past,
    required this.onSelect,
  });

  final bool confirmedActive;
  final int confirmed;
  final int past;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: CkColors.paper2,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: CkColors.line),
    ),
    child: Row(
      children: [
        Expanded(
          child: _tab(
            'Confirmed',
            confirmed,
            confirmedActive,
            () => onSelect(true),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _tab('Past', past, !confirmedActive, () => onSelect(false)),
        ),
      ],
    ),
  );

  Widget _tab(String label, int count, bool active, VoidCallback onTap) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration:
              active
                  ? BoxDecoration(
                    color: CkColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CkColors.line),
                  )
                  : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0.08,
                    color: active ? CkColors.ink : CkColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              if (active)
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: const BoxDecoration(
                    color: CkColors.ink,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    '$count',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: CkColors.paper,
                    ),
                  ),
                )
              else
                Text(
                  '$count',
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: CkColors.muted,
                  ),
                ),
            ],
          ),
        ),
      );
}

/// Option (c): the banner is NOT a permanent fixture above the schedule — that
/// is the exact mixing this screen was split to end, and it desensitises the
/// one case that matters. It appears only when a challenge is inside 6h.
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
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/my/challenges'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: CkColors.cream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.creamBorder),
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
                      style: CkType.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.09,
                        color: CkColors.ink,
                      ).copyWith(height: 1.5),
                    ),
                    Text(
                      soonest.inHours >= 1
                          ? '${urgent.length} EXPIRES IN ${soonest.inHours}H'
                          : '${urgent.length} EXPIRES IN ${soonest.inMinutes}M',
                      style: CkType.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.09,
                        color: CkColors.redInk,
                      ).copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '→',
                style: CkType.mono(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CkColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── States ─────────────────────────────────────────────────────────────────

/// Chrome real from the first frame, only rows skeletal — no spinner, so the
/// page never blanks.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
    children: const [
      CkShimmer(child: CkShimmerBox(width: 132, height: 10, radius: 4)),
      SizedBox(height: 12),
      _SkeletonFixture(opacity: 1, live: true),
      SizedBox(height: 10),
      _SkeletonFixture(opacity: 0.7, live: false),
      SizedBox(height: 10),
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
    Widget shim(Widget c) => live ? CkShimmer(child: c) : c;
    return Opacity(
      opacity: opacity,
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 84,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: CkColors.paper,
                border: Border(right: BorderSide(color: CkColors.hairline)),
              ),
              child: shim(const CkShimmerBox(width: 44, height: 16, radius: 4)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    shim(const CkShimmerBox(width: 150, height: 13, radius: 4)),
                    const SizedBox(height: 8),
                    const CkShimmerBox(width: 120, height: 13, radius: 4),
                    const SizedBox(height: 9),
                    const CkShimmerBox(width: 170, height: 9, radius: 4),
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

/// Identical in language to the Challenges error board on purpose — one failure
/// vocabulary across both screens, and no red: a failed fetch is not an
/// emergency.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Centered(
    title: "Couldn't load your matches.",
    body:
        'Nothing has been lost — fixtures, lineups and scorecards all '
        'live on the server. Check your connection and try again.',
    action: _InkButton(label: 'Try again', onTap: onRetry),
    footnote: message,
  );
}

/// The offer is a challenge, and if a queue exists it is named: an empty
/// schedule with unanswered challenges has an obvious next move.
class _ConfirmedEmpty extends ConsumerWidget {
  const _ConfirmedEmpty({required this.onSwitch});

  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needs =
        ref.watch(challengesViewProvider).value?.needsYou ??
        const <ChallengeRow>[];
    return _Centered(
      title: 'Nothing on the schedule.',
      body:
          needs.isEmpty
              ? 'Fixtures appear here once a challenge is accepted.'
              : 'Fixtures appear here once a challenge is accepted. Send one, or '
                  'answer the ${needs.length} already waiting on you.',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InkButton(
            label: '+  Challenge a team',
            onTap: () => context.push('/challenge'),
          ),
          if (needs.isNotEmpty) ...[
            const SizedBox(height: 10),
            _GhostRow(
              label:
                  needs.length == 1
                      ? '1 challenge needs you'
                      : '${needs.length} challenges need you',
              onTap: () => context.push('/my/challenges'),
            ),
          ],
        ],
      ),
    );
  }
}

/// No call to action: you cannot manufacture a past. It points at the schedule
/// instead, which is where the first result will come from.
class _PastEmpty extends StatelessWidget {
  const _PastEmpty({required this.confirmedCount, required this.onSwitch});

  final int confirmedCount;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) => _Centered(
    title: 'No past matches.',
    body:
        'Scorecards land here the moment a match finishes — yours and '
        'every match you were in the squad for.',
    action:
        confirmedCount == 0
            ? null
            : _GhostRow(
              label: 'Confirmed',
              trailing: '$confirmedCount',
              onTap: onSwitch,
            ),
  );
}

class _FirstRunEmpty extends StatelessWidget {
  const _FirstRunEmpty();

  @override
  Widget build(BuildContext context) => _Centered(
    title: 'No matches yet.',
    body:
        'Every fixture starts as a challenge: propose a day, a ground '
        'and a format, and it appears here the moment the other manager '
        'accepts.',
    action: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InkButton(
          label: '+  Challenge a team',
          onTap: () => context.push('/challenge'),
        ),
        const SizedBox(height: 10),
        _GhostRow(
          label: 'Post to the open pool',
          onTap: () => context.push('/matches/send-challenge?mode=open'),
        ),
      ],
    ),
    footnote: 'Accepted challenges become fixtures · nothing else does',
  );
}

class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.only(top: 14),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: CkColors.hairline)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SEE ALL $total MATCHES',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.09,
            color: CkColors.ink2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '→',
          style: CkType.mono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: CkColors.muted,
          ),
        ),
      ],
    ),
  );
}

// ─── Shared bits ────────────────────────────────────────────────────────────

class _Centered extends StatelessWidget {
  const _Centered({
    required this.title,
    required this.body,
    this.action,
    this.footnote,
  });

  final String title;
  final String body;
  final Widget? action;
  final String? footnote;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(28, 72, 28, 28),
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: CkType.display(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.015,
          color: CkColors.ink,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        body,
        textAlign: TextAlign.center,
        style: CkType.body(fontSize: 13, height: 1.6, color: CkColors.muted),
      ),
      if (action != null) ...[const SizedBox(height: 22), action!],
      if (footnote != null) ...[
        const SizedBox(height: 18),
        Text(
          footnote!.toUpperCase(),
          textAlign: TextAlign.center,
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: CkColors.soft,
          ),
        ),
      ],
    ],
  );
}

class _InkButton extends StatelessWidget {
  const _InkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: CkColors.paper,
        ),
      ),
    ),
  );
}

class _GhostRow extends StatelessWidget {
  const _GhostRow({required this.label, this.trailing, required this.onTap});

  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.ink2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (trailing != null)
            Text(
              trailing!,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.muted,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '→',
            style: CkType.mono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CkColors.muted,
            ),
          ),
        ],
      ),
    ),
  );
}
