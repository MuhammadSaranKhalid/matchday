import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/ck_shimmer.dart';
import '../../domain/scoring/scorecard.dart';
import '../providers/completed_match_providers.dart';
import '../state/completed_match_view.dart';
import '../widgets/completed_match/cm_atoms.dart';
import '../widgets/completed_match/cm_card_tab.dart';
import '../widgets/completed_match/cm_overs_tab.dart';
import '../widgets/completed_match/cm_record_page.dart';
import '../widgets/completed_match/cm_result_card.dart';
import '../widgets/completed_match/cm_stats_tab.dart';
import '../widgets/completed_match/cm_summary_tab.dart';

/// The completed-match screen: the artefact a match leaves behind.
///
/// Header and result card are persistent — they are the answer to "what
/// happened", and they must not scroll away while someone reads a bowling
/// figure. Below them, four tabs are four views of the same two innings.
///
/// The one structural branch: when no delivery was ever recorded (a walkover,
/// an abandonment) there is nothing to tab through, so the tab bar does not
/// render and the body becomes a printed record instead. See [CmRecordPage].
class CompletedMatchScreen extends ConsumerStatefulWidget {
  const CompletedMatchScreen({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<CompletedMatchScreen> createState() =>
      _CompletedMatchScreenState();
}

class _CompletedMatchScreenState extends ConsumerState<CompletedMatchScreen> {
  int _tab = 0;

  /// Which innings the Card / Overs / Stats tabs are showing. Summary and
  /// Stats speak about the whole match; Card and Overs are per-innings.
  int _innings = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(completedMatchProvider(widget.matchId));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (async) {
          AsyncData(:final value) => _Loaded(
            view: value,
            tab: _tab,
            innings: _innings,
            onTab: (i) => setState(() => _tab = i),
            onInnings: (i) => setState(() => _innings = i),
          ),
          AsyncError(:final error) => _Error(
            matchId: widget.matchId,
            message: _messageFor(error),
          ),
          _ => const _Skeleton(),
        },
      ),
    );
  }

  static String _messageFor(Object error) =>
      error.toString().contains('no longer exists')
          ? "That match no longer exists."
          : "Couldn't load this match.";
}

/// Back arrow, both team names, and a share affordance.
class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back,
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/my-matches');
            }
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const _CircleButton(icon: Icons.add),
      ],
    ),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: CkColors.paper2,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 17, color: CkColors.ink),
    ),
  );
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.view,
    required this.tab,
    required this.innings,
    required this.onTab,
    required this.onInnings,
  });

  final CompletedMatchView view;
  final int tab;
  final int innings;
  final ValueChanged<int> onTab;
  final ValueChanged<int> onInnings;

  @override
  Widget build(BuildContext context) {
    final safeInnings = innings.clamp(0, (view.innings.length - 1).clamp(0, 1));

    return Column(
      children: [
        _Header(title: view.title),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: CmResultCard(view: view),
        ),
        const Divider(height: 1, color: CkColors.line),
        // The central branch: no ledger, no tabs.
        if (!view.hasLedger)
          Expanded(child: CmRecordPage(view: view))
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
            child: _TabBar(index: tab, onChanged: onTab),
          ),
          // Card and Overs speak about ONE innings, so they carry a switcher.
          if ((tab == 1 || tab == 2) && view.innings.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
              child: _InningsSwitcher(
                view: view,
                index: safeInnings,
                onChanged: onInnings,
              ),
            ),
          Expanded(
            child: switch (tab) {
              1 => CmCardTab(
                card: view.innings[safeInnings],
                teamColor: _colorFor(view, view.innings[safeInnings]),
              ),
              2 => CmOversTab(card: view.innings[safeInnings]),
              3 => CmStatsTab(view: view),
              _ => CmSummaryTab(view: view),
            },
          ),
        ],
      ],
    );
  }

  static Color _colorFor(CompletedMatchView v, InningsCard card) =>
      v.sides
          .where((s) => s.sideLetter == card.battingTeamSide)
          .map((s) => s.color)
          .firstOrNull ??
      CkColors.ink;
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _labels = ['Summary', 'Card', 'Overs', 'Stats'];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: CkColors.paper2,
      border: Border.all(color: CkColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        for (final (i, label) in _labels.indexed)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 3),
                alignment: Alignment.center,
                decoration:
                    i == index
                        ? BoxDecoration(
                          color: CkColors.surface,
                          border: Border.all(color: CkColors.line),
                          borderRadius: BorderRadius.circular(10),
                        )
                        : null,
                child: Text(
                  label.toUpperCase(),
                  style: CmText.label(
                    size: 10,
                    color: i == index ? CkColors.ink : CkColors.muted,
                  ).copyWith(
                    fontWeight: i == index ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 10 * 0.07,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _InningsSwitcher extends StatelessWidget {
  const _InningsSwitcher({
    required this.view,
    required this.index,
    required this.onChanged,
  });

  final CompletedMatchView view;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, inn) in view.innings.indexed) ...[
        GestureDetector(
          onTap: () => onChanged(i),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: i == index ? CkColors.ink : Colors.transparent,
              border: Border.all(
                color: i == index ? CkColors.ink : CkColors.line,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_shortTeam(view, inn.battingTeamSide)} '
              '${inn.inningsNumber == 1 ? '1ST' : '2ND'}',
              style: CmText.label(
                size: 9.5,
                color: i == index ? CkColors.paper : CkColors.muted,
              ).copyWith(letterSpacing: 9.5 * 0.07),
            ),
          ),
        ),
        const SizedBox(width: 7),
      ],
    ],
  );

  static String _shortTeam(CompletedMatchView v, String side) =>
      v.sides
          .where((s) => s.sideLetter == side)
          .map((s) => s.short)
          .firstOrNull ??
      '';
}

/// Chrome, tabs and column headers are real from the first frame; only the
/// figures and names shim. The page does not reflow when the data lands.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            _CircleButton(icon: Icons.arrow_back),
            SizedBox(width: 10),
            Expanded(
              child: CkShimmer(
                child: CkShimmerBox(width: 170, height: 18, radius: 5),
              ),
            ),
            SizedBox(width: 10),
            _CircleButton(icon: Icons.add),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: CmPanel(
          children: [
            for (var i = 0; i < 2; i++)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                child: Row(
                  children: [
                    CkShimmer(
                      child: CkShimmerBox(width: 20, height: 20, radius: 6),
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: CkShimmer(
                        child: CkShimmerBox(width: 120, height: 13, radius: 4),
                      ),
                    ),
                    CkShimmer(
                      child: CkShimmerBox(width: 52, height: 14, radius: 4),
                    ),
                  ],
                ),
              ),
            Container(
              height: 36,
              color: CkColors.paper2,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.centerLeft,
              child: const CkShimmer(
                child: CkShimmerBox(width: 180, height: 12, radius: 4),
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: CkColors.line),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
        child: _TabBar(index: 0, onChanged: (_) {}),
      ),
      const Expanded(child: SizedBox.shrink()),
    ],
  );
}

/// Ink, never red — a failed read is not an error the reader caused.
class _Error extends ConsumerWidget {
  const _Error({required this.matchId, required this.message});

  final String matchId;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      const _Header(title: 'Match'),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: CkType.display(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => ref.invalidate(completedMatchProvider(matchId)),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: CkColors.line),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'TRY AGAIN',
                      style: CmText.label(size: 10, color: CkColors.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
