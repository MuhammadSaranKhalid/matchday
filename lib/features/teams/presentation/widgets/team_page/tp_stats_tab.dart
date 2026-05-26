import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'tp_atoms.dart';
import 'tp_view.dart';

/// Stats tab — win-% hero number block + top performers list. Empty state
/// when [TpTeam.stats] is null ("Stats unlock at first match").
class TpStatsTab extends StatelessWidget {
  const TpStatsTab({super.key, required this.team});
  final TpTeam team;

  @override
  Widget build(BuildContext context) {
    final stats = team.stats;
    if (stats == null) {
      return const TpEmptyTile(
        icon: Icons.bar_chart,
        title: 'Stats unlock at first match',
        body:
            'Once you play your first match, win rates and top performers appear here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      children: [
        _WinPctCard(stats: stats),
        const SizedBox(height: 16),
        Text('TOP PERFORMERS · THIS SEASON', style: tpMono()),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < stats.top.length; i++)
                _PerformerRow(performer: stats.top[i], isFirst: i == 0),
            ],
          ),
        ),
      ],
    );
  }
}

class _WinPctCard extends StatelessWidget {
  const _WinPctCard({required this.stats});
  final TpStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ALL-TIME', style: tpMono()),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stats.winPct}',
                style: CkType.display(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.04,
                  height: 0.9,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 8),
                child: Text(
                  '%',
                  style: CkType.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CkColors.muted,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('WIN RATE', style: tpMono()),
                  const SizedBox(height: 2),
                  Text(
                    stats.trend,
                    style: tpMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CkColors.green,
                    ).copyWith(letterSpacing: 0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformerRow extends StatelessWidget {
  const _PerformerRow({required this.performer, required this.isFirst});
  final TpPerformer performer;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : const Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              performer.kind,
              style: tpMono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: CkColors.ink2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(performer.label, style: tpMono()),
                const SizedBox(height: 2),
                Text(
                  performer.name,
                  style: CkType.display(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  performer.detail,
                  style: CkType.body(
                    fontSize: 11,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            performer.value,
            style: CkType.display(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
        ],
      ),
    );
  }
}
