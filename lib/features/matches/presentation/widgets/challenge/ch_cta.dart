import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import 'ch_icons.dart';

/// Sticky wizard footer: hint OR error-pill (with RETRY) followed by a
/// full-width primary CTA + optional secondary ghost button.
/// Reproduces `ChCta` from `challenge-shared.jsx` (lines 110–155).
/// Bottom padding adds `MediaQuery.viewPadding.bottom` for the safe area.
class ChCta extends StatelessWidget {
  const ChCta({
    super.key,
    required this.cta,
    this.onCta,
    this.hint,
    this.secondary,
    this.onSecondary,
    this.error,
    this.onRetry,
    this.disabled = false,
    this.busy = false,
  });

  final String cta;
  final VoidCallback? onCta;
  final String? hint;
  final String? secondary;
  final VoidCallback? onSecondary;
  final String? error;
  final VoidCallback? onRetry;
  final bool disabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 12 + safeBottom),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null)
            _ErrorPill(message: error!, onRetry: onRetry)
          else if (hint != null && hint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(
                hint!,
                textAlign: TextAlign.center,
                style: CkType.body(
                  fontSize: 11.5,
                  color: CkColors.muted,
                  height: 1.35,
                ),
              ),
            ),
          Row(
            children: [
              if (secondary != null) ...[
                _SecondaryButton(label: secondary!, onTap: onSecondary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _PrimaryButton(
                  label: cta,
                  onTap: (disabled || busy) ? null : onCta,
                  disabled: disabled,
                  busy: busy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  const _ErrorPill({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CkColors.redSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: CkColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: CkType.body(
                fontSize: 11.5,
                color: CkInk.red,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: CkColors.red,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'RETRY',
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: CkColors.paper,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.onTap,
    this.disabled = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bg = disabled ? CkColors.paper2 : CkColors.ink;
    final fg = disabled ? CkColors.muted : CkColors.paper;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CkColors.paper,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                  if (!disabled) ...[
                    const SizedBox(width: 8),
                    V2Svg(
                      ChIcons.arrow,
                      size: 15,
                      color: fg,
                      strokeWidth: 2.2,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CkColors.ink,
          ),
        ),
      ),
    );
  }
}
