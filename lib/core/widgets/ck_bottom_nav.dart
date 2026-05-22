import 'package:flutter/material.dart';

import '../theme/circk_theme.dart';

/// The Phase 1 bottom navigation bar: three tabs — HOME · MATCH · PAVILION.
///
/// Visual treatment is ported from `design/app/screens/AppShell.jsx`: the active
/// tab shows an ink rounded-square icon with a mono uppercase caption beneath;
/// inactive tabs show a muted line icon only. A hairline separates the bar from
/// the body, and the bar respects the bottom safe-area inset.
///
/// (The design's full shell has four tabs incl. Tournaments/Create; those are
/// v1.1+ per the Phase 1 scope, so only these three ship now.)
class CkBottomNav extends StatelessWidget {
  const CkBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItemData>[
    _NavItemData(label: 'HOME', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _NavItemData(label: 'MATCH', icon: Icons.sports_cricket_outlined, activeIcon: Icons.sports_cricket),
    _NavItemData(label: 'PAVILION', icon: Icons.account_circle_outlined, activeIcon: Icons.account_circle),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    data: _items[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.active,
    required this.onTap,
  });

  final _NavItemData data;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (active)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: CkColors.ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(data.activeIcon, size: 18, color: CkColors.paper),
            )
          else
            Icon(data.icon, size: 22, color: CkColors.muted),
          if (active) ...[
            const SizedBox(height: 3),
            Text(
              data.label,
              style: CkType.mono(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: CkColors.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
