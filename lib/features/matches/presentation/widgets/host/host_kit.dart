import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../pool/pool_icons.dart';

/// Shared parts of the host's challenge surfaces — `Pool.dc.html` section C
/// (artboards 12–19). Kept in one file because the pills in particular only
/// mean anything as a set: the design draws two tiers on purpose, and putting
/// them side by side is what keeps them from drifting apart.

/// The 56px stacked-screen bar: back, title, one optional action.
class HostTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HostTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.action,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;

  /// Right-hand glyph from [PoolIcons]. Null leaves the slot empty.
  final String? action;
  final VoidCallback? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          _Slot(
            onTap: onBack,
            child: const V2Svg(
              V2Icons.chevronLeft,
              size: 22,
              color: CkColors.ink,
              strokeWidth: 1.7,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CkColors.ink,
                letterSpacing: -0.01,
              ),
            ),
          ),
          if (action != null)
            _Slot(onTap: trailing, child: PoolIcon(action!, size: 18)),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 40, height: 40, child: Center(child: child)),
    );
  }
}

/// Status pills come in two tiers, and the design is explicit that they must
/// not be mixed: a **card** pill is cream and quiet, a **banner** pill is solid
/// and states a role. [CkStatusPill.card] and [CkStatusPill.banner] are the
/// only two constructors so a call site has to choose one.
class CkStatusPill extends StatelessWidget {
  const CkStatusPill._({
    required this.label,
    required this.background,
    required this.foreground,
    required this.fontSize,
    required this.padding,
    required this.radius,
    required this.weight,
  });

  /// Cream on a card — the single Pending treatment for a challenge card.
  factory CkStatusPill.card(
    String label, {
    Color background = CkColors.cream,
    Color foreground = CkColors.amberInk,
  }) => CkStatusPill._(
    label: label,
    background: background,
    foreground: foreground,
    fontSize: 9,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    radius: 6,
    weight: FontWeight.w600,
  );

  /// Solid, and states a role rather than a state — Hosting, Matched.
  factory CkStatusPill.banner(
    String label, {
    required Color background,
    Color foreground = CkColors.ink,
    bool compact = false,
  }) => CkStatusPill._(
    label: label,
    background: background,
    foreground: foreground,
    fontSize: compact ? 9 : 10,
    padding:
        compact
            ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    radius: compact ? 5 : 6,
    weight: compact ? FontWeight.w700 : FontWeight.w600,
  );

  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;
  final EdgeInsets padding;
  final double radius;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0.06,
          color: foreground,
        ),
      ),
    );
  }
}

/// The 6-digit code, set in tabular figures so a column of them lines up.
///
/// Host surfaces only. The code is a hand-to-hand token, so it never appears
/// on the public board or on an applicant's screen.
class ShareCodeChip extends StatelessWidget {
  const ShareCodeChip(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CkColors.line),
      ),
      child: Text(
        code,
        style: CkType.mono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.12,
          color: CkColors.ink2,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

/// Mono, wide-tracked, muted — the one section-header treatment.
class HostSectionLabel extends StatelessWidget {
  const HostSectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 6),
    this.trailing,
  });

  final String text;
  final EdgeInsets padding;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: CkType.mono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.10,
        color: CkColors.muted,
      ),
    );

    return Padding(
      padding: padding,
      child:
          trailing == null
              ? label
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [label, trailing!],
              ),
    );
  }
}

/// The bar pinned under a host screen's content.
class HostBottomBar extends StatelessWidget {
  const HostBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.line)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

/// A filled action. [tone] picks the ground: ink for positive and neutral
/// confirmations, red only where the action destroys something.
class HostActionButton extends StatelessWidget {
  const HostActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.tone = CkColors.ink,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color tone;
  final String? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: busy ? tone.withValues(alpha: 0.55) : tone,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child:
              busy
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CkColors.paper,
                    ),
                  )
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        PoolIcon(icon!, size: 15),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: CkType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CkColors.paper,
                          letterSpacing: -0.01,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

/// The one Withdraw treatment in the app — a red text link, never a button.
class WithdrawLink extends StatelessWidget {
  const WithdrawLink({
    super.key,
    required this.onTap,
    this.label = 'Withdraw challenge',
  });

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: CkType.mono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
              color: CkColors.redInk,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet chrome for artboards 17–19: rounded top, grabber, safe-area padding
/// and room for the keyboard.
class HostSheet extends StatelessWidget {
  const HostSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2, bottom: 18),
                  decoration: BoxDecoration(
                    color: CkColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// The quiet "Cancel" / "Keep it live" that sits under a sheet's confirm.
class SheetDismiss extends StatelessWidget {
  const SheetDismiss({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Center(
          child: Text(
            label,
            style: CkType.display(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CkColors.muted,
              letterSpacing: -0.01,
            ),
          ),
        ),
      ),
    );
  }
}
