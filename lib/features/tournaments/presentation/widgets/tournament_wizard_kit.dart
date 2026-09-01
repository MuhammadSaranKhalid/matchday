import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/circk_theme.dart';

/// The create-wizard component kit, redlined from artboards 16–21.
///
/// The wizard has its own visual language, distinct from the rest of the app:
/// 14pt-radius white fields on paper, 13px Inter labels, and selection
/// expressed as a bordered card with a radio and a sentence of consequence —
/// never a switch, because a switch has nowhere to put the sentence.

/// Field-box radius. The canvas uses 14 everywhere in this flow, which is
/// [CkRadii.md]; named here so the intent reads at each call site.
const double _kField = CkRadii.md;

// ─── Chrome ──────────────────────────────────────────────────────────────────

/// 56pt nav: a circular close affordance on the left, "Save & exit" on the
/// right. No title — the step header below carries it.
class WizardNavBar extends StatelessWidget {
  const WizardNavBar({
    super.key,
    required this.onClose,
    required this.onSaveAndExit,
  });

  final VoidCallback onClose;
  final VoidCallback onSaveAndExit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Close',
              child: InkWell(
                onTap: onClose,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: CkColors.paper2,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: CkColors.ink),
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onSaveAndExit,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  'Save & exit',
                  style: CkType.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 4pt progress rail, the "STEP N OF 6" eyebrow, and the 26px step title.
class WizardStepHeader extends StatelessWidget {
  const WizardStepHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
  });

  /// 1-based.
  final int step;
  final int totalSteps;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: step / totalSteps),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: CkColors.paper2,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(CkColors.ink),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'STEP $step OF $totalSteps',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: CkType.display(fontSize: 26, height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// Back + Continue. Continue takes 1.6× the width of Back, and goes inert —
/// paper2 fill, soft label, **no red** — while the step is invalid. The field
/// error already carries the alarm; a red button would double it.
class WizardFooter extends StatelessWidget {
  const WizardFooter({
    super.key,
    required this.onBack,
    required this.onContinue,
    this.continueLabel = 'Continue',
    this.showChevron = true,
    this.busy = false,
  });

  /// Null on the first step — the button still renders, greyed, so the footer
  /// does not change shape between steps.
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool showChevron;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onContinue != null && !busy;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: _Btn(
              onTap: busy ? null : onBack,
              height: 52,
              fill: null,
              border: CkColors.line,
              child: Text(
                'Back',
                style: CkType.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onBack == null ? CkColors.soft : CkColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 16,
            child: _Btn(
              onTap: enabled ? onContinue : null,
              height: 52,
              fill: enabled ? CkColors.ink : CkColors.paper2,
              border: null,
              child: busy
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
                        Text(
                          continueLabel,
                          style: CkType.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: enabled ? CkColors.paper : CkColors.soft,
                          ),
                        ),
                        if (showChevron && enabled) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: CkColors.paper,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.onTap,
    required this.height,
    required this.fill,
    required this.border,
    required this.child,
  });

  final VoidCallback? onTap;
  final double height;
  final Color? fill;
  final Color? border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill ?? Colors.transparent,
      borderRadius: BorderRadius.circular(_kField),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kField),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kField),
            border: border == null ? null : Border.all(color: border!),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Labels & helpers ────────────────────────────────────────────────────────

/// 13px Inter 500 field label, with the canvas's soft "· optional" suffix.
class WizardLabel extends StatelessWidget {
  const WizardLabel(this.text, {super.key, this.optional = false, this.trailing});

  final String text;
  final bool optional;

  /// Right-aligned mono value, e.g. "2 added".
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text.rich(
      TextSpan(
        style: CkType.body(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CkColors.ink2,
        ),
        children: [
          TextSpan(text: text),
          if (optional)
            TextSpan(
              text: ' · optional',
              style: CkType.body(fontSize: 13, color: CkColors.soft),
            ),
        ],
      ),
    );

    if (trailing == null) return label;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: label),
        Text(
          trailing!,
          style: CkType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// The 11.5px grey sentence under a field. Pairs with an optional right-aligned
/// mono character counter.
class WizardHelper extends StatelessWidget {
  const WizardHelper(this.text, {super.key, this.counter});

  final String text;
  final String? counter;

  @override
  Widget build(BuildContext context) {
    final body = Text(
      text,
      style: CkType.body(fontSize: 11.5, height: 1.5, color: CkColors.muted),
    );
    if (counter == null) return body;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: body),
        const SizedBox(width: 10),
        Text(
          counter!,
          style: CkType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// The inline validation message. 12px, red-ink, under the field — never a
/// toast.
class WizardFieldError extends StatelessWidget {
  const WizardFieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          message,
          style: CkType.body(
            fontSize: 12,
            height: 1.5,
            color: CkColors.redInk,
          ),
        ),
      );
}

// ─── Inputs ──────────────────────────────────────────────────────────────────

/// White field box on paper. The 1.5px red border is the **only** place the
/// destructive register is allowed in this flow.
class WizardTextField extends StatelessWidget {
  const WizardTextField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.hasError = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final bool hasError;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      style: CkType.body(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: maxLines > 1 ? 1.55 : null,
        color: CkColors.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: CkType.body(
          fontSize: maxLines > 1 ? 13 : 15,
          height: maxLines > 1 ? 1.55 : null,
          color: CkColors.muted,
        ),
        filled: true,
        fillColor: CkColors.surface,
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: _border(CkColors.line, 1),
        enabledBorder: _border(hasError ? CkColors.red : CkColors.line,
            hasError ? 1.5 : 1),
        focusedBorder: _border(hasError ? CkColors.red : CkColors.ink, 1.5),
      ),
    );
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kField),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// A read-only field box that opens a picker — dates, city.
class WizardPickerField extends StatelessWidget {
  const WizardPickerField({
    super.key,
    required this.value,
    required this.onTap,
    this.icon,
    this.hasError = false,
    this.trailing,
    this.mono = true,
  });

  final String value;
  final VoidCallback onTap;
  final IconData? icon;
  final bool hasError;
  final Widget? trailing;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CkColors.surface,
      borderRadius: BorderRadius.circular(_kField),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kField),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kField),
            border: Border.all(
              color: hasError ? CkColors.red : CkColors.line,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: hasError ? CkColors.redInk : CkColors.muted,
                ),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mono
                      ? CkType.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: CkColors.ink,
                        )
                      : CkType.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: CkColors.ink,
                        ),
                ),
              ),
              if (hasError)
                const Icon(Icons.error_outline, size: 17, color: CkColors.red)
              else if (trailing != null)
                trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// −/+ stepper in a field box. Used for team counts, overs and the bowler cap.
class WizardStepper extends StatelessWidget {
  const WizardStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(_kField),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        children: [
          _StepperButton(
            icon: Icons.remove,
            enabled: value - step >= min,
            onTap: () => onChanged(value - step),
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: CkType.mono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: CkColors.ink,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            enabled: value + step <= max,
            onTap: () => onChanged(value + step),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CkColors.paper2,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 15,
            color: enabled ? CkColors.ink : CkColors.soft,
          ),
        ),
      ),
    );
  }
}

/// A currency field: mono "PKR" prefix on the left, right-aligned tabular
/// figure.
class WizardMoneyField extends StatelessWidget {
  const WizardMoneyField({
    super.key,
    required this.controller,
    this.currency = 'PKR',
    this.onChanged,
    this.compact = false,
  });

  final TextEditingController controller;
  final String currency;
  final ValueChanged<String>? onChanged;

  /// Row variant used inside the prize list (no box, tighter type).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.right,
      style: CkType.mono(
        fontSize: compact ? 14 : 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: CkColors.ink,
      ),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: '0',
      ),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currency,
            style: CkType.mono(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 92, child: field),
        ],
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(_kField),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        children: [
          Text(
            currency,
            style: CkType.mono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: field),
        ],
      ),
    );
  }
}

// ─── Selection ───────────────────────────────────────────────────────────────

/// The canvas's selectable card: radio on one side, title, and a sentence of
/// consequence. Selected = 1.5px ink border and a thick-ring radio.
class WizardChoiceCard extends StatelessWidget {
  const WizardChoiceCard({
    super.key,
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.radioLeading = false,
  });

  final bool selected;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  /// The hairline mini-diagram on the structure cards.
  final Widget? leading;

  /// Step 1 puts the radio first; step 2 puts the diagram first and the radio
  /// last. Both shapes are in the canvas.
  final bool radioLeading;

  @override
  Widget build(BuildContext context) {
    final radio = _Radio(selected: selected);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: CkType.display(
            fontSize: leading == null ? 14.5 : 15,
            fontWeight: FontWeight.w700,
            color: selected ? CkColors.ink : CkColors.ink2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: CkType.body(
              fontSize: leading == null ? 12 : 11.5,
              height: 1.45,
              color: CkColors.muted,
            ),
          ),
        ],
      ],
    );

    return Material(
      color: CkColors.paper,
      borderRadius: BorderRadius.circular(_kField),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kField),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: leading == null ? 14 : 13,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kField),
            border: Border.all(
              color: selected ? CkColors.ink : CkColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: radioLeading
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (radioLeading) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: radio,
                ),
                const SizedBox(width: 11),
                Expanded(child: text),
              ] else ...[
                if (leading != null) ...[leading!, const SizedBox(width: 11)],
                Expanded(child: text),
                const SizedBox(width: 11),
                radio,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CkColors.paper,
        border: Border.all(
          color: selected ? CkColors.ink : CkColors.soft,
          width: selected ? 5 : 1.5,
        ),
      ),
    );
  }
}

/// A structure option that is not built yet: dashed, greyed, untappable.
class WizardComingSoonCard extends StatelessWidget {
  const WizardComingSoonCard({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return CkDashedBox(
      radius: _kField,
      color: CkColors.line,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: CkType.display(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CkColors.soft,
                ),
              ),
            ),
            CkDashedBox(
              radius: 4,
              color: CkColors.soft,
              fill: CkColors.paper2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'COMING SOON',
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ink-filled when selected, paper2 when not. Used for the match-format row.
class WizardChip extends StatelessWidget {
  const WizardChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CkColors.ink : CkColors.paper2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? CkColors.paper : CkColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Blocks ──────────────────────────────────────────────────────────────────

/// The cream consequence block — offline-payment disclaimer and friends.
class WizardCreamNote extends StatelessWidget {
  const WizardCreamNote({
    super.key,
    required this.eyebrow,
    required this.body,
    this.bold,
  });

  final String eyebrow;
  final String body;

  /// Optional phrase inside [body] to bold, matched on first occurrence.
  final String? bold;

  @override
  Widget build(BuildContext context) {
    final base = CkType.body(
      fontSize: 12.5,
      height: 1.55,
      color: CkColors.ink2,
    );

    Widget text;
    if (bold != null && body.contains(bold!)) {
      final i = body.indexOf(bold!);
      text = Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(text: body.substring(0, i)),
            TextSpan(
              text: bold,
              style: base.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: body.substring(i + bold!.length)),
          ],
        ),
      );
    } else {
      text = Text(body, style: base);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(_kField),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.amberDark,
            ),
          ),
          const SizedBox(height: 5),
          text,
        ],
      ),
    );
  }
}

/// The paper2 summary block — "Your match will run …".
class WizardSummaryBlock extends StatelessWidget {
  const WizardSummaryBlock({
    super.key,
    required this.eyebrow,
    required this.headline,
    this.footnote,
  });

  final String eyebrow;
  final String headline;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(_kField),
        border: Border.all(color: CkColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            headline,
            style: CkType.display(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 3),
            Text(
              footnote!,
              style: CkType.body(fontSize: 11.5, color: CkColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// A hairline-bordered list container — grounds, prizes, review groups.
class WizardListCard extends StatelessWidget {
  const WizardListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const WizardDivider());
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(_kField),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }
}

class WizardDivider extends StatelessWidget {
  const WizardDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: CkColors.hairline);
}

/// Dashed upload slot. Never a filled grey box.
class WizardUploadSlot extends StatelessWidget {
  const WizardUploadSlot({
    super.key,
    required this.label,
    required this.onTap,
    this.width,
    this.height = 74,
    this.preview,
    this.onClear,
  });

  final String label;
  final VoidCallback onTap;
  final double? width;
  final double height;
  final ImageProvider? preview;

  /// Shown as a small dismiss affordance once something is picked.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (preview != null) {
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(_kField),
              child: Material(
                color: CkColors.paper2,
                child: InkWell(
                  onTap: onTap,
                  child: Ink.image(image: preview!, fit: BoxFit.cover),
                ),
              ),
            ),
            if (onClear != null)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: CkColors.ink.withValues(alpha: 0.72),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onClear,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 13,
                        color: CkColors.paper,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: CkDashedBox(
        radius: _kField,
        color: CkColors.soft,
        fill: CkColors.paper2,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 17, color: CkColors.muted),
            const SizedBox(height: 5),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashed-border box. Flutter has no dashed BoxBorder, so this paints one.
/// Shared with the console's waitlist card.
class CkDashedBox extends StatelessWidget {
  const CkDashedBox({
    super.key,
    required this.radius,
    required this.color,
    required this.child,
    this.fill,
    this.onTap,
  });

  final double radius;
  final Color color;
  final Widget child;
  final Color? fill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = CustomPaint(
      painter: _DashedBorderPainter(radius: radius, color: color),
      child: child,
    );

    if (fill != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: content,
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      );
    }
    return content;
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    // Walk the rounded-rect path, drawing 4px on / 3px off.
    const on = 4.0;
    const off = 3.0;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + on),
          paint,
        );
        distance += on + off;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.radius != radius || old.color != color;
}
