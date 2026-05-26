import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/my_teams_view.dart';

/// Horizontal segmented chips: All / Playing / Manage / Following / Archived.
/// Hidden chips for filters with zero count (except All).
class MyTeamsFilterChips extends StatelessWidget {
  const MyTeamsFilterChips({
    super.key,
    required this.active,
    required this.counts,
    this.onSelect,
  });

  final MyTeamsFilter active;
  final Map<MyTeamsFilter, int> counts;
  final ValueChanged<MyTeamsFilter>? onSelect;

  static const _all = [
    (MyTeamsFilter.all, 'All'),
    (MyTeamsFilter.playing, 'Playing'),
    (MyTeamsFilter.managing, 'Manage'),
    (MyTeamsFilter.following, 'Following'),
    (MyTeamsFilter.archived, 'Archived'),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _all
        .where((p) =>
            p.$1 == MyTeamsFilter.all || (counts[p.$1] ?? 0) > 0)
        .toList();

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final (filter, label) = visible[i];
          final isActive = filter == active;
          final count = counts[filter] ?? 0;
          return InkWell(
            onTap: onSelect == null ? null : () => onSelect!(filter),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? CkColors.ink : CkColors.paper,
                borderRadius: BorderRadius.circular(999),
                border:
                    isActive ? null : Border.all(color: CkColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: CkType.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? CkColors.paper : CkColors.ink2,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: CkType.mono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.10,
                      color: isActive
                          ? CkColors.paper.withValues(alpha: 0.55)
                          : CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
