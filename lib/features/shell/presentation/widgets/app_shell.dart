import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// The authenticated app shell (v2 IA): hosts the five branch navigators
/// (Home · Search · Matches · Messages · Pavilion — order per D9 in
/// docs/search-feature-design.md) and renders the shared [V2BottomNav]
/// beneath them. Own profile is reached via the header avatar, not a tab.
///
/// Wired via [StatefulShellRoute] in `app_router.dart` with a custom
/// `navigatorContainerBuilder` ([SwipeableBranchView]) that lays the branches
/// out in a [PageView], so the tabs can be swiped through with a smooth,
/// finger-tracking transition while each tab still keeps its own navigation
/// state. The Notifications bell lives in each screen's header, not in the bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Branch index ↔ tab identity. Order must match the router's branch order
  // AND the D9 nav order: Home · Search · Matches · Messages · Pavilion.
  static const _tabs = <V2Tab>[
    V2Tab.home,
    V2Tab.search,
    V2Tab.matches,
    V2Tab.messages,
    V2Tab.pavilion,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      // [navigationShell] renders the branches via the router's custom
      // container builder (a PageView — see SwipeableBranchView).
      body: navigationShell,
      bottomNavigationBar: V2BottomNav(
        active: _tabs[navigationShell.currentIndex],
        onSelect: (tab) {
          final index = _tabs.indexOf(tab);
          navigationShell.goBranch(
            index,
            // Re-tapping the active tab pops it back to its initial route.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
