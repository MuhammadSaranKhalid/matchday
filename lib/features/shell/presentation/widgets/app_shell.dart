import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import 'app_drawer.dart';

/// The authenticated app shell (v2 IA): hosts the four branch navigators
/// (Home · Explore · Matches · Pool) and renders the shared persistent fixed
/// [V2Header] at the top and [V2BottomNav] beneath them.
///
/// The side panel (You) is mounted as [Scaffold.drawer] ([AppDrawer]) and opened
/// from the left by the management icon in [V2Header].
///
/// Wired via [StatefulShellRoute] in `app_router.dart` with a custom
/// `navigatorContainerBuilder` ([SwipeableBranchView]) that lays the branches
/// out in a [PageView], so the tabs can be swiped through with a smooth,
/// finger-tracking transition while each tab keeps its own navigation state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Branch index ↔ tab identity: Home · Explore · Matches · Pool.
  // (Organising rule: Bottom nav is the world; side panel is you.)
  static const _tabs = <V2Tab>[
    V2Tab.home,
    V2Tab.explore,
    V2Tab.matches,
    V2Tab.pool,
  ];

  static const _tabTitles = <String>[
    'Home',
    'Explore',
    'Matches',
    'Pool',
  ];

  @override
  Widget build(BuildContext context) {
    final int index = navigationShell.currentIndex;
    final String title = (index >= 0 && index < _tabTitles.length)
        ? _tabTitles[index]
        : 'Home';

    return Scaffold(
      backgroundColor: CkColors.paper,
      drawer: const AppDrawer(),
      drawerEdgeDragWidth: 20.0,
      // Scrim is flat ink @ 32% — no blur. Material's default black54 is both
      // too dark and the wrong hue against warm paper.
      drawerScrimColor: CkColors.ink.withValues(alpha: 0.32),
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (scaffoldContext) => Column(
            children: [
              V2Header(
                title: title,
                onBell: () => context.push('/notifications'),
                onManagement: () {
                  HapticFeedback.mediumImpact();
                  Scaffold.of(scaffoldContext).openDrawer();
                },
              ),
              Expanded(child: navigationShell),
            ],
          ),
        ),
      ),
      bottomNavigationBar: V2BottomNav(
        active: (index >= 0 && index < _tabs.length)
            ? _tabs[index]
            : V2Tab.home,
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


