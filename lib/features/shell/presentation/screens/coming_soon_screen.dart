import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_screen_scaffold.dart';

/// Placeholder tab body used by the bottom-nav branches until each feature is
/// built (Match lifecycle: F4–F9, Pavilion: F10). It exists only so the shell
/// is navigable end-to-end in Feature 0.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.tab,
    this.showWordmark = false,
    this.showActions = false,
  });

  /// Display label for the tab (e.g. 'Match'). Ignored when [showWordmark].
  final String tab;

  /// When true the top bar shows the `matchday.` wordmark instead of [tab].
  final bool showWordmark;

  /// When true the top bar shows the bell + avatar actions (Home only).
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return CkScreenScaffold(
      title: showWordmark ? null : tab,
      hasUnread: showActions,
      onBell: showActions ? () => context.push('/notifications') : null,
      onAvatar: showActions ? () => context.go('/profile') : null,
      avatarInitials: showActions ? '·' : null,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              showWordmark ? 'Home' : tab,
              style: CkType.display(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: CkType.mono(fontSize: 11, color: CkColors.soft),
            ),
          ],
        ),
      ),
    );
  }
}
