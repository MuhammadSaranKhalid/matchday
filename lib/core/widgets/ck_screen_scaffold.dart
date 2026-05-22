import 'package:flutter/material.dart';

import '../theme/circk_theme.dart';

/// Shared chrome for the bottom-nav screens, mirroring `CkTopBar` /
/// `CkAppShell` in `design/app/screens/AppShell.jsx`.
///
/// Renders a paper-background [Scaffold] with an optional top bar. When [title]
/// is null the `circk.` wordmark is shown (red period); otherwise the title is
/// rendered in the display face. Optional bell + avatar actions sit on the
/// right. The bottom navigation bar is supplied by the navigation shell, not
/// here, so this scaffold is just top bar + body.
class CkScreenScaffold extends StatelessWidget {
  const CkScreenScaffold({
    super.key,
    required this.child,
    this.title,
    this.livePulse = false,
    this.showTopBar = true,
    this.hasUnread = false,
    this.onBell,
    this.onAvatar,
    this.avatarInitials,
  });

  final Widget child;

  /// Null → render the `circk.` wordmark. Otherwise the title text.
  final String? title;
  final bool livePulse;
  final bool showTopBar;
  final bool hasUnread;
  final VoidCallback? onBell;
  final VoidCallback? onAvatar;
  final String? avatarInitials;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (showTopBar) _TopBar(
              title: title,
              livePulse: livePulse,
              hasUnread: hasUnread,
              onBell: onBell,
              onAvatar: onAvatar,
              avatarInitials: avatarInitials,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.livePulse,
    required this.hasUnread,
    required this.onBell,
    required this.onAvatar,
    required this.avatarInitials,
  });

  final String? title;
  final bool livePulse;
  final bool hasUnread;
  final VoidCallback? onBell;
  final VoidCallback? onAvatar;
  final String? avatarInitials;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
      child: Row(
        children: [
          Expanded(child: _leading()),
          if (onBell != null) _BellButton(hasUnread: hasUnread, onTap: onBell!),
          if (onAvatar != null)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: _Avatar(initials: avatarInitials ?? '', onTap: onAvatar!),
            ),
        ],
      ),
    );
  }

  Widget _leading() {
    final t = title;
    final Widget label = (t == null || t.isEmpty || t == 'circk')
        ? _Wordmark()
        : Text(
            t,
            style: CkType.display(fontSize: 22, letterSpacing: -0.025),
          );

    if (!livePulse) return Align(alignment: Alignment.centerLeft, child: label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        label,
        const SizedBox(width: 8),
        const _LiveChip(),
      ],
    );
  }
}

/// The `circk.` wordmark with the red period, per the designs.
class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'circk',
            style: CkType.display(fontSize: 26, letterSpacing: -0.045),
          ),
          TextSpan(
            text: '.',
            style: CkType.display(
              fontSize: 26,
              letterSpacing: -0.045,
              color: CkColors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: CkColors.redSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'LIVE',
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: CkColors.red,
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasUnread, required this.onTap});

  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded, color: CkColors.ink, size: 22),
          if (hasUnread)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: CkColors.red,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: CkColors.paper, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.onTap});

  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: CkColors.ink,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: CkType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: CkColors.paper,
          ),
        ),
      ),
    );
  }
}
