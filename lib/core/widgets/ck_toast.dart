import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/circk_theme.dart';

/// The app's toast — one ink ground for every outcome, success or failure.
///
/// Failure is signalled by a red dot, never a red ground: `#DC4D32` as a 13px
/// label on ink measures 3.3:1 and fails. The ink ground with paper text
/// measures 11.7:1 and carries every message in the family.
///
/// Only ever one on screen. A second toast replaces the first rather than
/// stacking — a stack of transient messages is unreadable by the time the
/// third arrives.
class CkToast {
  const CkToast._();

  static OverlayEntry? _current;
  static Timer? _timer;

  /// Shows a toast over the current route.
  ///
  /// [actionLabel] + [onAction] add a trailing button and extend the dwell
  /// from 2.4s to 4.5s — an action nobody has time to read is not an action.
  /// [isError] swaps the leading icon for the red dot.
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    bool isError = false,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismiss();

    final hasAction = actionLabel != null && onAction != null;
    // 12 above the home indicator / tab bar, 16 in from the sides.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: bottomInset + 12,
        child: _ToastBody(
          message: message,
          icon: icon,
          isError: isError,
          actionLabel: actionLabel,
          onAction: hasAction
              ? () {
                  _dismiss();
                  onAction();
                }
              : null,
        ),
      ),
    );

    _current = entry;
    overlay.insert(entry);
    _timer = Timer(
      Duration(milliseconds: hasAction ? 4500 : 2400),
      _dismiss,
    );
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

class _ToastBody extends StatefulWidget {
  const _ToastBody({
    required this.message,
    required this.icon,
    required this.isError,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final IconData? icon;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_ToastBody> createState() => _ToastBodyState();
}

class _ToastBodyState extends State<_ToastBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Cubic(0.2, 0.9, 0.25, 1),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: Tween<Offset>(
          // 12px rise, expressed against the pill's own height.
          begin: const Offset(0, 0.24),
          end: Offset.zero,
        ).animate(_fade),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              color: CkColors.ink,
              borderRadius: BorderRadius.circular(CkRadii.md),
              boxShadow: [
                BoxShadow(
                  color: CkColors.ink.withValues(alpha: 0.28),
                  offset: const Offset(0, 8),
                  blurRadius: 22,
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.isError)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: CkColors.red,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (widget.icon != null)
                  Icon(widget.icon, size: 19, color: CkColors.paper),
                if (widget.isError || widget.icon != null)
                  const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    widget.message,
                    style: CkType.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: CkColors.paper,
                    ),
                  ),
                ),
                if (widget.onAction != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onAction,
                    child: Text(
                      widget.actionLabel!,
                      style: CkType.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        // Amber clears 5.6:1 on ink; cream underlined is the
                        // recovery affordance on the failure toasts.
                        color: widget.isError ? CkColors.cream : CkColors.amber,
                      ).copyWith(
                        decoration:
                            widget.isError ? TextDecoration.underline : null,
                        decorationColor: CkColors.cream,
                        decorationThickness: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
