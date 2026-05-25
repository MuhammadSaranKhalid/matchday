import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// The authenticated app shell (v2 IA): hosts the five branch navigators
/// (Home · Matches · Pavilion · Messages · You) inside an indexed stack and
/// renders the shared [V2BottomNav] beneath them.
///
/// Wired via [StatefulShellRoute.indexedStack] in `app_router.dart`, so each
/// tab keeps its own navigation state when switching tabs. The Notifications
/// bell lives in each screen's header, not in the bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Branch index ↔ tab identity. Order must match the router's branch order.
  static const _tabs = <V2Tab>[
    V2Tab.home,
    V2Tab.matches,
    V2Tab.pavilion,
    V2Tab.messages,
    V2Tab.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
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
