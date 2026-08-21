import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../management/presentation/widgets/management_sheet.dart';

/// The authenticated app shell (v2 IA): hosts the five branch navigators
/// (Home · Search · Matches · Pool · Profile) and renders the shared
/// persistent fixed [V2Header] at the top and [V2BottomNav] beneath them.
///
/// Wired via [StatefulShellRoute] in `app_router.dart` with a custom
/// `navigatorContainerBuilder` ([SwipeableBranchView]) that lays the branches
/// out in a [PageView], so the tabs can be swiped through with a smooth,
/// finger-tracking transition while each tab keeps its own navigation state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Branch index ↔ tab identity: Home · Explore · Matches · Pool · Profile.
  // (Pavilion held slot 3 until 2026-08-21; it moved to the Management sheet
  // as a full-screen route and the open match Pool took the slot.)
  static const _tabs = <V2Tab>[
    V2Tab.home,
    V2Tab.explore,
    V2Tab.matches,
    V2Tab.pool,
    V2Tab.profile,
  ];

  static const _tabTitles = <String>[
    'Home',
    'Explore',
    'Matches',
    'Pool',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final int index = navigationShell.currentIndex;
    final String title = (index >= 0 && index < _tabTitles.length)
        ? _tabTitles[index]
        : 'Home';

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            V2Header(
              title: title,
              onBell: () => context.push('/notifications'),
              onManagement: () => ManagementSheet.show(context),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: V2BottomNav(
        active: _tabs[navigationShell.currentIndex],
        onSelect: (tab) {
          final targetIndex = _tabs.indexOf(tab);
          navigationShell.goBranch(
            targetIndex,
            // Re-tapping the active tab pops it back to its initial route.
            initialLocation: targetIndex == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

