import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';

/// Pill-shaped chip (full radius). Reproduces `Chip` from
/// `challenge-shared.jsx` lines 170–180 — active fills ink + paper text,
/// disabled dims the foreground to `CkColors.soft`.
class ChChip extends StatelessWidget {
  const ChChip({
    super.key,
    required this.label,
    this.onTap,
    this.active = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final bg = active ? CkColors.ink : CkColors.paper;
    final fg =
        active ? CkColors.paper : (disabled ? CkColors.soft : CkColors.ink);
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? CkColors.ink : CkColors.hairline),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}
