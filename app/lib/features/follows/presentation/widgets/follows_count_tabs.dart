import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/follow_direction.dart';

/// Big-count tabs displaying Followers and Following counts with active indicator.
class FollowsCountTabs extends StatelessWidget {
  const FollowsCountTabs({
    super.key,
    required this.tab,
    required this.followers,
    required this.following,
    required this.onSelect,
  });

  final FollowDirection tab;
  final int followers;
  final int following;
  final ValueChanged<FollowDirection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(
            children: [
              _TabItem(
                value: followers,
                label: 'FOLLOWERS',
                active: tab == FollowDirection.followers,
                onTap: () => onSelect(FollowDirection.followers),
              ),
              _TabItem(
                value: following,
                label: 'FOLLOWING',
                active: tab == FollowDirection.following,
                onTap: () => onSelect(FollowDirection.following),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: CkColors.hairline),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.value,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final int value;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? CkColors.ink : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: CkType.display(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.03,
                  height: 1.1,
                  color: active ? CkColors.ink : CkColors.ink2,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: active ? CkColors.ink : CkColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
