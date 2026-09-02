import 'package:flutter/material.dart';

import '../theme/circk_theme.dart';

/// The 56pt nav every drawer-pushed "My …" screen wears.
///
/// My Tournaments, My Teams, My Matches and My Challenges are the same kind of
/// screen — reached from the side panel, no bottom tabs, one thing you own per
/// row — so they carry one nav. It had been copy-pasted into two of them and
/// re-invented in the other two, which is how the titles ended up at three
/// different sizes with two different back buttons.
class CkPushNav extends StatelessWidget implements PreferredSizeWidget {
  const CkPushNav({
    super.key,
    required this.title,
    required this.onBack,
    this.action,
  });

  final String title;
  final VoidCallback onBack;

  /// Trailing slot — a [CkNavPill] for a create action, or a quiet count.
  final Widget? action;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: CkColors.paper2,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: CkColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(fontSize: 17),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 10), action!],
        ],
      ),
    );
  }
}

/// The nav's ink pill — "+ CREATE", "+ CHALLENGE".
class CkNavPill extends StatelessWidget {
  const CkNavPill({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CkColors.ink,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: CkColors.paper),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: CkColors.paper,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A quiet mono count in the nav's trailing slot ("2 live").
class CkNavCount extends StatelessWidget {
  const CkNavCount(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06,
          color: CkColors.muted,
        ),
      );
}
