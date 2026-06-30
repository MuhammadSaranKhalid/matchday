import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// The authenticated app shell (matchday IA): hosts the three branch
/// navigators (Home · Matches · Alerts — see
/// `design_handoff_matchday/README.md`) and renders the shared [GlobalHeader]
/// above them plus the [V2BottomNav] beneath. The header is owned by the
/// shell — not each tab — so it stays pixel-identical and persistent as the
/// user swipes between Home, Matches and Alerts (mirroring the prototype's
/// `Shell` which passes one `header={header}` instance into every tab).
///
/// Search, Messages and Profile/Pavilion are reached via the [GlobalHeader]
/// (search pill, messages bubble, avatar → Menu drawer), not from the bar.
///
/// Wired via [StatefulShellRoute] in `app_router.dart` with a custom
/// `navigatorContainerBuilder` ([SwipeableBranchView]) that lays the branches
/// out in a [PageView], so the tabs can be swiped through with a smooth,
/// finger-tracking transition while each tab still keeps its own navigation
/// state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Branch index ↔ tab identity. Order must match the router's branch order
  // AND the matchday IA nav order: Home · Matches · Alerts.
  static const _tabs = <V2Tab>[
    V2Tab.home,
    V2Tab.matches,
    V2Tab.alerts,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      // SafeArea(bottom:false) handles the top inset for the header; the
      // bottom nav handles its own SafeArea via Scaffold.bottomNavigationBar.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const GlobalHeader(),
            Expanded(child: navigationShell),
          ],
        ),
      ),
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
