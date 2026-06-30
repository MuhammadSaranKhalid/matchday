import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';

/// "My tournaments" — the Menu-drawer destination from
/// `design_handoff_matchday/README.md` §15. Renders the shared matchday
/// [SubPage] chrome (back arrow + title + bottom hairline) with the
/// "+ New tournament" FAB pinned bottom-right.
///
/// The body is a coming-soon empty state until the create-tournament wizard
/// (`design_handoff_matchday/prototype/tournament-create.jsx`) is ported.
/// The FAB shows the same "coming soon" toast so the affordance feels live
/// without dead-ending on a blank screen.
class MyTournamentsScreen extends StatelessWidget {
  const MyTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'My tournaments',
      eyebrow: 'MENU',
      fabLabel: 'New tournament',
      onFab: () => _showComingSoon(context),
      child: const _EmptyState(),
    );
  }

  void _showComingSoon(BuildContext context) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Tournament creation is coming soon.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CkColors.hairline),
              ),
              child: const V2Svg(
                V2Icons.trophy,
                size: 28,
                color: CkColors.ink2,
                strokeWidth: 1.8,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No tournaments yet',
              style: CkType.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Run a league or a knockout cup. Set the format, register '
              'teams, seed the draw and we handle fixtures, standings '
              'and awards.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                color: CkColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'COMING SOON',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
                color: CkColors.soft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
