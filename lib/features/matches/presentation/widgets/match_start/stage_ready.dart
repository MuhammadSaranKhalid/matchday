import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/theme/circk_theme.dart';
import '../../providers/match_start_providers.dart';
import '../../state/match_start_state.dart';
import '../../state/match_start_views.dart';
import 'match_start_atoms.dart';

/// Stage 3 — the pre-first-ball confirmation. Every string shown here is
/// resolved by [matchStartReadyProvider]; this widget only lays it out.
class MatchStartReadyStage extends ConsumerWidget {
  const MatchStartReadyStage({
    super.key,
    required this.matchId,
    required this.state,
  });

  final String matchId;
  final MatchStartState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(matchStartReadyProvider(matchId));

    return switch (ready) {
      AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              failureMessageOf(error),
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 13, color: CkColors.muted),
            ),
          ),
        ),
      AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          children: [
            _ScoreboardPreview(view: value),
            const SizedBox(height: 14),
            _SummaryCard(view: value),
            const SizedBox(height: 14),
            _ScorerNote(isScorer: state.isViewerBattingCaptain),
          ],
        ),
      _ => const MatchStartLoader(),
    };
  }
}

/// The 0/0 scoreboard the scorer is about to start filling in.
class _ScoreboardPreview extends StatelessWidget {
  const _ScoreboardPreview({required this.view});

  final MatchStartReadyView view;

  static const _onInk = Color(0xB3FDFAF4);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIRST BALL · OVER 0.1',
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: _onInk,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  view.battingTeamName,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CkColors.paper,
                  ),
                ),
              ),
              Text(
                '0/0',
                style: CkType.display(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: CkColors.paper,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  view.bowlingTeamName,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _onInk,
                  ),
                ),
              ),
              Text(
                '—',
                style: CkType.display(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _onInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Label/value rundown of the agreed terms.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.view});

  final MatchStartReadyView view;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (view.tossLine.isNotEmpty)
            _SummaryRow(label: 'Toss', value: view.tossLine),
          if (view.strikerName != null)
            _SummaryRow(
              label: 'On strike',
              value: view.strikerName!,
              valueColor: CkColors.red,
            ),
          if (view.nonStrikerName != null)
            _SummaryRow(label: 'Non-striker', value: view.nonStrikerName!),
          const _SummaryRow(
            label: 'Opening bowler',
            value: 'Picked at ball 1',
            valueColor: CkColors.muted,
          ),
          _SummaryRow(label: 'Format', value: view.formatLine),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label.toUpperCase(),
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: CkType.body(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? CkColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tells this phone whether it is about to score or spectate.
class _ScorerNote extends StatelessWidget {
  const _ScorerNote({required this.isScorer});

  final bool isScorer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isScorer ? CkColors.red : CkColors.ink,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: CkColors.paper,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isScorer
                      ? 'You’re scoring this innings'
                      : 'You’re spectating this innings',
                  style: CkType.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isScorer
                      ? 'Your team is batting — you enter every ball.'
                      : 'See the live scoreboard. You score when your team bats.',
                  style: CkType.body(
                    fontSize: 11.5,
                    color: CkColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
