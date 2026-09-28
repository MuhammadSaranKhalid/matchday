import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';

/// Shared chrome for the post-a-challenge wizard — `Pool.dc.html` section B
/// (artboards 06–11).
///
/// Every step wears the same 56px bar, the same segmented progress rule and
/// the same ink footer, so the only thing that changes between steps is the
/// question being asked.

/// The bar: back, title, and a right-hand counter that is usually "Step N / M"
/// but on Pick XI becomes the live selection count.
class WizardTopBar extends StatelessWidget {
  const WizardTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: V2Svg(
                  V2Icons.chevronLeft,
                  size: 22,
                  color: CkColors.ink,
                  strokeWidth: 1.7,
                ),
              ),
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
          if (trailing != null)
            Padding(padding: const EdgeInsets.only(right: 12), child: trailing),
        ],
      ),
    );
  }
}

/// "Step 3 / 6" — the quiet mono counter most steps carry.
class WizardStepCount extends StatelessWidget {
  const WizardStepCount({super.key, required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => Text(
    'STEP ${index + 1} / $total',
    style: CkType.mono(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.06,
      color: CkColors.muted,
    ),
  );
}

/// One 3px rule per step, filled up to and including the current one.
class WizardProgress extends StatelessWidget {
  const WizardProgress({super.key, required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: i <= index ? CkColors.ink : CkColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (i != total - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

/// The pinned footer. Posting is not destructive, so the primary is always
/// ink — the design spends red nowhere in this flow.
class WizardFooter extends StatelessWidget {
  const WizardFooter({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.busy = false,
    this.hint,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool busy;

  /// A line of context above the button (the format step's "both captains can
  /// change this" note).
  final String? hint;

  /// Paper ground with an ink rule — the success screen's "View my challenge".
  final bool outlined;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final live = enabled && !busy;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hint != null) ...[
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 11.5, color: CkColors.muted),
              ),
              const SizedBox(height: 10),
            ],
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: live ? onPressed : null,
              child: Builder(
                builder: (context) {
                  // A dimmed ink block reads as a broken button. Not-yet is
                  // paper-2 with a hairline, which reads as "there is
                  // something left to do" rather than "this is broken".
                  final ground =
                      !live && !outlined
                          ? CkColors.paper2
                          : (outlined ? CkColors.paper : CkColors.ink);
                  final onGround =
                      !live && !outlined
                          ? CkColors.soft
                          : (outlined ? CkColors.ink : CkColors.paper);

                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: ground,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          outlined
                              ? Border.all(color: CkColors.ink)
                              : (live
                                  ? null
                                  : Border.all(color: CkColors.line)),
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
                                    icon!,
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: CkType.display(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: onGround,
                                        letterSpacing: -0.01,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The step's question, in display 20.
class WizardHeading extends StatelessWidget {
  const WizardHeading(this.text, {super.key, this.sub});

  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: CkType.display(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CkColors.ink,
            letterSpacing: -0.02,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 6),
          Text(
            sub!,
            style: CkType.body(
              fontSize: 12.5,
              height: 1.5,
              color: CkColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Mono, wide-tracked field label. [optional] appends the italic qualifier the
/// venue field carries.
class WizardFieldLabel extends StatelessWidget {
  const WizardFieldLabel(
    this.text, {
    super.key,
    this.optional = false,
    this.trailing,
  });

  final String text;
  final bool optional;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          text.toUpperCase(),
          style: CkType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.10,
            color: CkColors.muted,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 8),
          Text(
            'optional',
            style: CkType.body(
              fontSize: 10,
              color: CkColors.soft,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );

    if (trailing == null) return label;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [label, trailing!],
    );
  }
}

/// A row of equal-width choices — ball type, players per side.
class WizardSegmented<T> extends StatelessWidget {
  const WizardSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.verticalPadding = 14,
  });

  /// Value → label, in display order.
  final Map<T, String> options;
  final T? selected;
  final ValueChanged<T> onSelect;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(entries[i].key),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                decoration: BoxDecoration(
                  color:
                      entries[i].key == selected
                          ? CkColors.ink
                          : CkColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      entries[i].key == selected
                          ? null
                          : Border.all(color: CkColors.line),
                ),
                child: Center(
                  child: Text(
                    entries[i].value,
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          entries[i].key == selected
                              ? CkColors.paper
                              : CkColors.ink2,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (i != entries.length - 1) const SizedBox(width: 9),
        ],
      ],
    );
  }
}

/// Strips the app-wide [InputDecorationTheme] off a field.
///
/// The theme fills every input white and gives it a 1.5px rule, which is right
/// for a standalone field and wrong for one nested inside a container that
/// already draws its own border — you get a box inside a box. Setting only
/// `border` does not help: `enabledBorder`, `focusedBorder` and `filled` are
/// resolved from the theme independently, so all four have to be answered.
InputDecoration bareInput({String? hintText, TextStyle? hintStyle}) =>
    InputDecoration(
      isDense: true,
      filled: false,
      fillColor: Colors.transparent,
      counterText: '',
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      hintText: hintText,
      hintStyle: hintStyle,
    );
