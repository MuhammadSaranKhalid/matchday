import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'tp_atoms.dart';
import 'tp_view.dart';

/// Sticky tab strip — equal-flex tabs with an ink underline under the
/// active one and an optional cream count badge.
class TpTabs extends StatelessWidget {
  const TpTabs({
    super.key,
    required this.items,
    required this.active,
    required this.onSelect,
  });

  final List<TpTabItem> items;
  final TeamPageTab active;
  final ValueChanged<TeamPageTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final t in items)
              Expanded(
                child: _Tab(
                  item: t,
                  isActive: t.id == active,
                  onTap: () => onSelect(t.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

@immutable
class TpTabItem {
  const TpTabItem({required this.id, required this.label, this.badge});
  final TeamPageTab id;
  final String label;
  final int? badge;
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });
  final TpTabItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? CkColors.ink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.label,
              style: CkType.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? CkColors.ink : CkColors.muted,
              ),
            ),
            if (item.badge != null && item.badge! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? CkColors.ink : CkColors.cream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.badge}',
                  style: tpMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isActive ? CkColors.paper : CkColors.ink2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Human label for a tab id. "Recent" is a separate alias used by archived
/// teams that don't have an Upcoming list.
String tpTabLabel(TeamPageTab t) {
  switch (t) {
    case TeamPageTab.squad:
      return 'Squad';
    case TeamPageTab.matches:
      return 'Matches';
    case TeamPageTab.stats:
      return 'Stats';
    case TeamPageTab.about:
      return 'About';
    case TeamPageTab.manage:
      return 'Manage';
    case TeamPageTab.recent:
      return 'Recent';
  }
}
