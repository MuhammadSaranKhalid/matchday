import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_bottom_nav.dart';

/// The authenticated app shell: hosts the three branch navigators
/// (HOME · MATCH · PAVILION) inside an indexed stack and renders the shared
/// [CkBottomNav] beneath them.
///
/// Wired via [StatefulShellRoute.indexedStack] in `app_router.dart`, so each
/// tab keeps its own navigation state when switching tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: navigationShell,
      bottomNavigationBar: CkBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // Re-tapping the active tab pops it back to its initial route.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
