import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import 'ch_icons.dart';

/// Wizard step chrome: 32px back button + mono kicker + optional progress
/// segments + display(24) title + optional sub. Reproduces `ChHeader` from
/// `challenge-shared.jsx` (lines 75–98).
class ChHeader extends StatelessWidget {
  const ChHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.sub,
    this.step,
    this.total,
    this.onBack,
    this.right,
  });

  final String kicker;
  final String title;
  final String? sub;

  /// 1-indexed current step number. When [total] is provided, fills the
  /// first [step] segments ink and the rest 10%-ink.
  final int? step;
  final int? total;

  final VoidCallback? onBack;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    final showProgress = total != null && step != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                _IconButton(onTap: onBack!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  kicker.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10,
                    color: CkColors.muted,
                  ),
                ),
              ),
              if (right != null) right!,
            ],
          ),
          SizedBox(height: showProgress ? 10 : 12),
          if (showProgress) ...[
            Row(
              children: List.generate(total!, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < step!
                          ? CkColors.ink
                          : CkColors.ink.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            title,
            style: CkType.display(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.025,
              height: 1.08,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 5),
            Text(
              sub!,
              style: CkType.body(
                fontSize: 13,
                color: CkColors.ink2,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CkColors.hairline),
        ),
        child: const V2Svg(
          ChIcons.back,
          size: 14,
          color: CkColors.ink,
          strokeWidth: 2.2,
        ),
      ),
    );
  }
}
