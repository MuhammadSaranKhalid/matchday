import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_shimmer.dart';
import '../../domain/entities/match_request.dart';
import '../providers/challenges_providers.dart';
import '../providers/match_pool_providers.dart';
import '../providers/matches_providers.dart';
import '../providers/my_matches_providers.dart';
import '../state/challenges_view.dart';
import '../widgets/challenges/challenge_card.dart';
import '../widgets/withdraw_sheet.dart';

/// Match Challenges — implements `Challenges.dc.html`.
///
/// A pushed page, not a tab and not a sheet: "a sheet is for one decision you
/// return from; this is a list you work down, so it gets its own page."
///
/// Two tabs split by OBLIGATION (`Needs you` / `Waiting on them`), never by
/// provenance — a challenge you sent that has been countered is back on your
/// desk, and Received/Sent would file it wrongly.
///
/// NOT implemented here (deliberately): the designer's 1b recommendation to
/// fold open-pool posts into `Needs you` as their own mono-headed group. It
/// needs applicant counts and crests on this screen, which is a data change
/// rather than a layout one. Open posts stay on `/my/pool-requests` until that
/// lands — which does mean the nav count here counts only direct challenges.
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  bool _needsYouTab = true;

  /// Rows sitting out their 5-second undo window after a decline. Declining is
  /// reversible; accepting is not, which is why only this one is optimistic.
  final Set<String> _declined = {};

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(challengesViewProvider);
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: async.when(
          // "Chrome is real from the first frame; only counts and rows are
          // skeletal. No spinner: the page never blanks, so returning from a
          // detail screen feels instant."
          loading:
              () => const _Frame(
                count: null,
                countSkeleton: true,
                tabs: _TabsSkeleton(),
                child: _Skeleton(),
              ),
          error:
              (e, _) => _Frame(
                count: null,
                tabs: null,
                child: _ErrorState(
                  onRetry: () => ref.invalidate(challengesViewProvider),
                ),
              ),
          data: (view) => _body(view),
        ),
      ),
    );
  }

  Widget _body(ChallengesView view) {
    final visibleNeeds =
        view.needsYou.where((r) => !_declined.contains(r.requestId)).toList();
    final rows = _needsYouTab ? visibleNeeds : view.waitingOnThem;

    // First run: two empty tabs is a filing cabinet with no files, so the
    // segmented control is suppressed entirely and the screen becomes a single
    // invitation.
    if (view.isEmpty) {
      return const _Frame(count: null, tabs: null, child: _FirstRunEmpty());
    }

    return _Frame(
      count: rows.length,
      tabs: _Tabs(
        needsYou: _needsYouTab,
        needsYouCount: visibleNeeds.length,
        waitingCount: view.waitingOnThem.length,
        onSelect: (v) => setState(() => _needsYouTab = v),
      ),
      header:
          _needsYouTab && visibleNeeds.isNotEmpty
              ? _HeaderLine(
                waiting: visibleNeeds.length,
                oldest: view.oldestWait,
                urgent:
                    visibleNeeds
                        .where((r) => r.tier == ExpiryTier.urgent)
                        .length,
              )
              : null,
      child:
          rows.isEmpty
              ? (_needsYouTab
                  ? _QueueEmpty(
                    outstanding: view.waitingOnThem.length,
                    onSwitch: () => setState(() => _needsYouTab = false),
                  )
                  : _WaitingEmpty(
                    onSwitch: () => setState(() => _needsYouTab = true),
                  ))
              : RefreshIndicator.adaptive(
                onRefresh: () async {
                  ref.invalidate(challengesViewProvider);
                  await ref.read(challengesViewProvider.future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(15, 4, 15, 28),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final row = rows[i];
                    return ChallengeCard(
                      row: row,
                      onOpen:
                          () => context.push('/challenges/${row.requestId}'),
                      onAccept: () => _accept(row),
                      onCounter:
                          () => context.push(
                            '/challenges/${row.requestId}/counter',
                          ),
                      onDecline: () => _decline(row),
                      onWithdraw: () => _withdraw(row),
                    );
                  },
                ),
              ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Accept is heavyweight: it writes a `matches` row AND both lineups, so it
  /// cannot be undone with a flag flip the way a decline can. The design gives
  /// it a confirm sheet rather than a one-tap, and says so on the sheet.
  Future<void> _accept(ChallengeRow row) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AcceptSheet(row: row),
    );
    if (ok != true || !mounted) return;

    final res = await ref
        .read(matchesRepositoryProvider)
        .acceptMatchChallenge(requestId: MatchRequestId(row.requestId));
    if (!mounted) return;
    res.fold(
      (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        _invalidate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Match created against ${row.opponentName}')),
        );
      },
    );
  }

  /// Decline leaves the queue immediately and offers Undo for 5 seconds — the
  /// tournament-requests pattern, and the reason accept and decline are
  /// deliberately asymmetric.
  Future<void> _decline(ChallengeRow row) async {
    setState(() => _declined.add(row.requestId));
    final messenger = ScaffoldMessenger.of(context);
    var undone = false;

    final controller = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text('Declined ${row.opponentName}'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            undone = true;
            if (mounted) setState(() => _declined.remove(row.requestId));
          },
        ),
      ),
    );

    await controller.closed;
    if (undone || !mounted) return;

    final res = await ref
        .read(matchesRepositoryProvider)
        .declineMatchChallenge(requestId: MatchRequestId(row.requestId));
    if (!mounted) return;
    res.fold((f) {
      setState(() => _declined.remove(row.requestId));
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }, (_) => _invalidate());
  }

  Future<void> _withdraw(ChallengeRow row) async {
    final result = await showModalBottomSheet<WithdrawResult>(
      context: context,
      backgroundColor: CkColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WithdrawSheet(opponentName: row.opponentName),
    );
    if (result == null || !mounted) return;
    final res = await ref
        .read(matchesRepositoryProvider)
        .withdrawMatchChallenge(
          requestId: MatchRequestId(row.requestId),
          decisionNote: result.note,
        );
    if (!mounted) return;
    res.fold(
      (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(f.message))),
      (_) => _invalidate(),
    );
  }

  void _invalidate() {
    ref.invalidate(challengesViewProvider);
    ref.invalidate(myChallengesProvider);
    ref.invalidate(myMatchChallengesProvider);
    ref.invalidate(myMatchesViewProvider);
  }
}

// ─── Chrome ─────────────────────────────────────────────────────────────────

/// Nav bar + optional tabs + optional header line, wrapping whatever body the
/// current state needs. Every state shares this frame so the title never moves.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.count,
    required this.tabs,
    required this.child,
    this.header,
    this.countSkeleton = false,
  });

  final int? count;

  /// Loading: the chrome is real from the first frame, so the title stays and
  /// only the count becomes a placeholder pill.
  final bool countSkeleton;
  final Widget? tabs;
  final Widget? header;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        // 12 rather than the design's 16: the canvas pulls the 44px tap
        // target 4px left with `margin-left:-4px` so the 36px circle
        // optically aligns to the 16px page gutter. Flutter's Container
        // asserts `margin.isNonNegative`, so the same result is reached by
        // taking the 4px off the gutter instead. Circle centre is 12+22=34
        // either way.
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap:
                  () =>
                      context.canPop()
                          ? context.pop()
                          : context.go('/my/matches'),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: CkColors.paper2,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 17,
                    color: CkColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Challenges',
                style: CkType.display(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                  color: CkColors.ink,
                ),
              ),
            ),
            if (countSkeleton)
              const CkShimmerBox(width: 22, height: 11, radius: 4)
            else if (count != null)
              Text(
                count!.toString().padLeft(2, '0'),
                style: CkType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.muted,
                ),
              ),
          ],
        ),
      ),
      if (tabs != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: tabs!,
        ),
      if (header != null) header!,
      Expanded(child: child),
    ],
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.needsYou,
    required this.needsYouCount,
    required this.waitingCount,
    required this.onSelect,
  });

  final bool needsYou;
  final int needsYouCount;
  final int waitingCount;
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
            label: 'Needs you',
            count: needsYouCount,
            active: needsYou,
            onTap: () => onSelect(true),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _tab(
            label: 'Waiting on them',
            count: waitingCount,
            active: !needsYou,
            onTap: () => onSelect(false),
          ),
        ),
      ],
    ),
  );

  Widget _tab({
    required String label,
    required int count,
    required bool active,
    required VoidCallback onTap,
  }) => GestureDetector(
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
        mainAxisAlignment: MainAxisAlignment.center,
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
          // The active tab's count is a solid pill — it is the badge the
          // menu row mirrors. The inactive one is plain muted type.
          if (active)
            Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: const BoxDecoration(
                color: CkColors.ink,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              child: Text(
                '$count',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
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
                color: CkColors.soft,
              ),
            ),
        ],
      ),
    ),
  );
}

/// "4 WAITING · OLDEST 46H AGO · 1 EXPIRES IN 2H". The red clause appears only
/// when something is actually inside the urgent tier, so a calm queue has no
/// red anywhere on the screen.
class _HeaderLine extends StatelessWidget {
  const _HeaderLine({
    required this.waiting,
    required this.oldest,
    required this.urgent,
  });

  final int waiting;
  final Duration? oldest;
  final int urgent;

  @override
  Widget build(BuildContext context) {
    final o = oldest;
    final oldestLabel =
        o == null
            ? null
            : (o.inHours >= 1
                ? 'OLDEST ${o.inHours}H AGO'
                : 'OLDEST ${o.inMinutes}M AGO');
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 10, 17, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              [
                '$waiting WAITING',
                if (oldestLabel != null) oldestLabel,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.09,
                color: CkColors.muted,
              ),
            ),
          ),
          if (urgent > 0) ...[
            const SizedBox(width: 7),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: CkColors.soft,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '$urgent EXPIRING SOON',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.09,
                color: CkColors.redInk,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── States ─────────────────────────────────────────────────────────────────

/// Tabs during loading — real labels, placeholder counts.
class _TabsSkeleton extends StatelessWidget {
  const _TabsSkeleton();

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
        Expanded(child: _tab('Needs you', active: true, pill: 18)),
        const SizedBox(width: 4),
        Expanded(child: _tab('Waiting on them', active: false, pill: 14)),
      ],
    ),
  );

  Widget _tab(String label, {required bool active, required double pill}) =>
      Container(
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
            CkShimmerBox(width: pill, height: 12, radius: 4),
          ],
        ),
      );
}

/// The loading list — `Challenges.dc.html` artboard 07.
///
/// Three cards fading back (1.0 / .75 / .45) so the list reads as continuing
/// past the fold rather than as exactly three items. Only the header bar and
/// the first card's crest + name bar animate; everything else is a flat fill.
/// Restricting the shimmer to the top of the list is what keeps a loading
/// screen from looking like it is vibrating.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    children: const [
      // Stands in for "4 WAITING · OLDEST 46H AGO".
      Padding(
        padding: EdgeInsets.fromLTRB(17, 15, 17, 12),
        child: CkShimmer(
          child: CkShimmerBox(width: 168, height: 10, radius: 4),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            _SkeletonCard(
              opacity: 1,
              live: true,
              nameFactor: 0.62,
              statusFactor: 0.34,
              whenFactor: 0.56,
              metaFactor: 0.74,
              timerWidth: 52,
            ),
            SizedBox(height: 11),
            _SkeletonCard(
              opacity: 0.75,
              live: false,
              nameFactor: 0.52,
              statusFactor: 0.30,
              whenFactor: 0.48,
              metaFactor: 0.68,
              timerWidth: 44,
            ),
            SizedBox(height: 11),
            // The last card is clipped by the fold: no timer, no second
            // meta line, no actions.
            _SkeletonCard(
              opacity: 0.45,
              live: false,
              nameFactor: 0.58,
              statusFactor: 0.26,
              whenFactor: 0.44,
            ),
          ],
        ),
      ),
    ],
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.opacity,
    required this.live,
    required this.nameFactor,
    required this.statusFactor,
    required this.whenFactor,
    this.metaFactor,
    this.timerWidth,
  });

  /// Only the first card animates; the ones behind it are static.
  final bool live;
  final double opacity;
  final double nameFactor;
  final double statusFactor;
  final double whenFactor;
  final double? metaFactor;
  final double? timerWidth;

  static const _flat = CkColors.paper2;

  Widget _bar(double factor, double height, double radius, Color color) =>
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: factor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // The crest and the name bar are the only parts of a card that move.
    Widget shim(Widget child) => live ? CkShimmer(child: child) : child;

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shim(const CkShimmerBox(width: 36, height: 36, radius: 8)),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shim(_bar(nameFactor, 14, 5, CkColors.hairline)),
                      const SizedBox(height: 7),
                      _bar(statusFactor, 9, 4, _flat),
                    ],
                  ),
                ),
                if (timerWidth != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: timerWidth,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _flat,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
            // 47 = crest (36) + gap (11), so the body aligns with the real
            // card's indented terms block.
            Padding(
              padding: const EdgeInsets.only(left: 47, top: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(whenFactor, 12, 4, _flat),
                  if (metaFactor != null) ...[
                    const SizedBox(height: 7),
                    _bar(metaFactor!, 9, 4, _flat),
                  ],
                ],
              ),
            ),
            if (metaFactor != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 66,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _flat,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _flat,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // The Accept slot is a shade darker, as on a real card.
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: CkColors.hairline,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A failed fetch is not an emergency, so it is not red — red is reserved for
/// expiry and destruction.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Centered(
    title: "Couldn't load your challenges.",
    body:
        'Nothing has been lost — every challenge and its clock live on the '
        'server. Check your connection and try again.',
    action: _PrimaryButton(label: 'Try again', onTap: onRetry),
  );
}

/// Queue-empty, not app-empty: the count zeroes and the only offer is the other
/// tab, because challenges of yours are still out there.
class _QueueEmpty extends StatelessWidget {
  const _QueueEmpty({required this.outstanding, required this.onSwitch});

  final int outstanding;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) => _Centered(
    title: 'Nothing needs you.',
    body:
        "You've cleared the queue. Challenges from other teams land "
        "here, and you'll get a push the moment one arrives.",
    action:
        outstanding == 0
            ? null
            : _GhostRow(
              label: '$outstanding of yours still out',
              trailing: 'Waiting on them',
              onTap: onSwitch,
            ),
  );
}

class _WaitingEmpty extends StatelessWidget {
  const _WaitingEmpty({required this.onSwitch});

  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) => _Centered(
    title: 'Nothing outstanding.',
    body: 'Challenges you send sit here until the other manager replies.',
    action: _GhostRow(
      label: 'Back to your queue',
      trailing: 'Needs you',
      onTap: onSwitch,
    ),
  );
}

class _FirstRunEmpty extends StatelessWidget {
  const _FirstRunEmpty();

  @override
  Widget build(BuildContext context) => _Centered(
    title: 'No challenges yet.',
    body:
        'A challenge is how a fixture starts: you propose a day, a '
        'ground and a format, and the other manager accepts, counters or '
        'declines.',
    action: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrimaryButton(
          label: '+  Challenge a team',
          onTap: () => _push(context, '/challenge'),
        ),
        const SizedBox(height: 10),
        _GhostRow(
          label: 'Post to the open pool',
          onTap: () => _push(context, '/matches/send-challenge?mode=open'),
        ),
        const SizedBox(height: 18),
        Text(
          'PENDING CHALLENGES EXPIRE AFTER 48H · COUNTERED ONES AFTER 24H',
          textAlign: TextAlign.center,
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: CkColors.soft,
          ),
        ),
      ],
    ),
  );

  static void _push(BuildContext context, String route) =>
      GoRouter.of(context).push(route);
}

class _Centered extends StatelessWidget {
  const _Centered({required this.title, required this.body, this.action});

  final String title;
  final String body;
  final Widget? action;

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
    ],
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

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
          // Both labels are long mono strings with wide letter-spacing;
          // at 393px "2 OF YOURS STILL OUT" + "WAITING ON THEM →" overran
          // the row (caught by challenges_screen_test).
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
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${trailing!.toUpperCase()}  →',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Accept confirm — artboard 11. Names the consequence rather than asking a
/// generic "are you sure", and says outright that this one cannot be undone.
class _AcceptSheet extends StatelessWidget {
  const _AcceptSheet({required this.row});

  final ChallengeRow row;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      18,
      20,
      20 + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: CkColors.soft,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Accept this challenge?',
          style: CkType.display(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.015,
            color: CkColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This turns the challenge into a real fixture against '
          '${row.opponentName}, with both line-ups created.',
          style: CkType.body(fontSize: 13, height: 1.55, color: CkColors.ink2),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CkColors.paper2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CkColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.whenLabel,
                style: CkType.display(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                row.metaLabel.toUpperCase(),
                style: CkType.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.07,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Accept · create match',
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(false),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            child: Text(
              'NOT YET',
              style: CkType.mono(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.muted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Declining can be undone for 5 seconds · accepting cannot',
          textAlign: TextAlign.center,
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.07,
            color: CkColors.soft,
          ),
        ),
      ],
    ),
  );
}
