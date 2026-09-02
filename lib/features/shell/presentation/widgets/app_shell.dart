import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// The authenticated app shell (v2 IA): hosts the five branch navigators
/// (Home · Matches · Pool · Messages · Menu) and renders the shared persistent
/// fixed [V2Header] at the top and [V2BottomNav] beneath them.
///
/// The "you" surface ([MenuScreen]) is the fifth branch, reached from the
/// avatar in the bottom nav. It used to be a [Scaffold.drawer] side panel
/// opened by a management icon in the header; that lost on two counts — its
/// edge-drag competed with [SwipeableBranchView]'s horizontal tab pager for the
/// left edge, and its only reliable entry point was the top-left corner, the
/// worst thumb-reach on a phone. As a branch it also keeps its own navigator,
/// so there is no menu screen stranded in the back stack behind a destination.
///
/// Wired via [StatefulShellRoute] in `app_router.dart` with a custom
/// `navigatorContainerBuilder` ([SwipeableBranchView]) that lays the branches
/// out in a [PageView], so the tabs can be swiped through with a smooth,
/// finger-tracking transition while each tab keeps its own navigation state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Branch index ↔ tab identity: Home · Matches · Pool · Messages · Menu.
  // (Organising rule: bottom nav is the world; Menu is you.)
  static const _tabs = <V2Tab>[
    V2Tab.home,
    V2Tab.matches,
    V2Tab.pool,
    V2Tab.messages,
    V2Tab.menu,
  ];

  static const _tabTitles = <String>[
    'Home',
    'Matches',
    'Pool',
    'Messages',
    'Menu',
  ];

  @override
  Widget build(BuildContext context) {
    final int index = navigationShell.currentIndex;
    final String title =
        (index >= 0 && index < _tabTitles.length) ? _tabTitles[index] : 'Home';

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            V2Header(
              title: title,
              showSearch: index == 0,
              onSearchTap: () => context.push('/explore'),
              onBell: () => context.push('/notifications'),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: V2BottomNav(
        active:
            (index >= 0 && index < _tabs.length) ? _tabs[index] : V2Tab.home,
        onSelect: (tab) {
          final targetIndex = _tabs.indexOf(tab);
          if (targetIndex != -1) {
            navigationShell.goBranch(
              targetIndex,
              // Re-tapping the active tab pops it back to its initial route.
              initialLocation: targetIndex == navigationShell.currentIndex,
            );
          }
        },
      ),
    );
  }
}
