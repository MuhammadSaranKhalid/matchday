import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'tp_atoms.dart';
import 'tp_view.dart';

/// Manage tab — action queue with red/amber/ink left border + squad capacity
/// bar (joined/invited/unclaimed) + 2×2 quick-grid of common owner actions.
class TpManageTab extends StatelessWidget {
  const TpManageTab({super.key, required this.team});
  final TpTeam team;

  @override
  Widget build(BuildContext context) {
    final queue = team.actionQueue;
    final active =
        team.squad.where((p) => p.status == TpPlayerStatus.app).length;
    final invited =
        team.squad.where((p) => p.status == TpPlayerStatus.sms).length;
    final unclaimed = team.squad
        .where((p) => p.status == TpPlayerStatus.unclaimed)
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      children: [
        Text('ACTION QUEUE · ${queue.length}', style: tpMono()),
        const SizedBox(height: 8),
        if (queue.isEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.hairline),
            ),
            alignment: Alignment.center,
            child: Text(
              'Inbox clear. ✓',
              style: CkType.body(
                fontSize: 13,
                color: CkColors.muted,
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < queue.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                _QueueRow(item: queue[i]),
              ],
            ],
          ),
        const SizedBox(height: 18),
        Text('SQUAD CAPACITY', style: tpMono()),
        const SizedBox(height: 8),
        _CapacityCard(
          total: team.squad.length,
          cap: team.maxSize,
          active: active,
          invited: invited,
          unclaimed: unclaimed,
        ),
        const SizedBox(height: 18),
        Text('QUICK', style: tpMono()),
        const SizedBox(height: 8),
        const _QuickGrid(),
      ],
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.item});
  final TpActionQueueItem item;

  Color get _accent {
    switch (item.tone) {
      case TpQueueTone.red:
        return CkColors.red;
      case TpQueueTone.amber:
        return CkColors.amber;
      case TpQueueTone.ink:
        return CkColors.ink;
    }
  }

  Color get _kindBg => item.tone == TpQueueTone.red
      ? CkColors.redSoft
      : CkColors.cream;

  Color get _kindFg =>
      item.tone == TpQueueTone.red ? CkColors.red : CkColors.ink2;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: _accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _kindBg,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  item.kind,
                                  style: tpMono(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: _kindFg,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(item.when, style: tpMono(fontSize: 9)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: CkType.display(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.01,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.body,
                            style: CkType.body(
                              fontSize: 12,
                              color: CkColors.ink2,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SmallPillBtn(label: item.primary, primary: true),
                        const SizedBox(height: 4),
                        const _SmallPillBtn(label: 'Reject', primary: false),
                      ],
                    ),
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

class _SmallPillBtn extends StatelessWidget {
  const _SmallPillBtn({required this.label, required this.primary});
  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: primary ? null : Border.all(color: CkColors.hairline),
      ),
      child: Text(
        label,
        style: CkType.body(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: primary ? CkColors.paper : CkColors.ink,
        ),
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard({
    required this.total,
    required this.cap,
    required this.active,
    required this.invited,
    required this.unclaimed,
  });
  final int total;
  final int cap;
  final int active;
  final int invited;
  final int unclaimed;

  @override
  Widget build(BuildContext context) {
    final pct = cap == 0 ? 0 : ((total / cap) * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$total of $cap',
                style: CkType.display(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                ),
              ),
              const Spacer(),
              Text('$pct%', style: tpMono(fontSize: 9)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: active,
                    child: Container(color: CkColors.green),
                  ),
                  Expanded(
                    flex: invited,
                    child: Container(color: CkColors.amber),
                  ),
                  Expanded(
                    flex: unclaimed,
                    child: Container(color: CkColors.cream),
                  ),
                  Expanded(
                    flex: (cap - total).clamp(0, cap),
                    child: Container(color: CkColors.paper2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _LegendDot(label: 'Joined', count: active, color: CkColors.green),
              _LegendDot(
                  label: 'Invited', count: invited, color: CkColors.amber),
              _LegendDot(
                label: 'Unclaimed',
                count: unclaimed,
                color: CkColors.cream,
                bordered: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.count,
    required this.color,
    this.bordered = false,
  });
  final String label;
  final int count;
  final Color color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: bordered ? Border.all(color: CkColors.hairline) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label · $count',
          style: CkType.body(fontSize: 11, color: CkColors.ink2),
        ),
      ],
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid();

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (Icons.calendar_month, 'Schedule match'),
      (Icons.lock_outline, 'Lock playing XI'),
      (Icons.edit, 'Edit team'),
      (Icons.settings, 'Settings'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final item in items) _QuickBtn(icon: item.$1, label: item.$2),
      ],
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: CkColors.ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.01,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
