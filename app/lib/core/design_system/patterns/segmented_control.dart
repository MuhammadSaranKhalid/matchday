import 'package:flutter/material.dart';

import '../foundation/motion.dart';
import '../foundation/radii.dart';
import '../theme/app_theme.dart';

/// An individual option inside a [SegmentedControl].
class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.count,
    this.icon,
  });

  final T value;
  final String label;
  final int? count;
  final Widget? icon;
}

/// Standardized segmented view switcher.
///
/// Used for switching between mutually exclusive primary views of the same screen
/// (e.g. Confirmed | Past or Organizing | Playing | Following).
///
/// Distinct from [SelectionChip], which is intended for multi-select, independent
/// toggles, and faceted filtering.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.scrollable = false,
  });

  final T value;
  final List<SegmentOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final status = context.statusColors;

    final segments = options.map((opt) {
      final isSelected = opt.value == value;
      return _SegmentTile<T>(
        option: opt,
        isSelected: isSelected,
        onTap: () => onChanged(opt.value),
      );
    }).toList();

    Widget content = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: status.neutralSurface,
        borderRadius: BorderRadius.circular(layout.controlRadius),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (scrollable)
              segments[i]
            else
              Expanded(child: segments[i]),
            if (i < segments.length - 1)
              SizedBox(width: layout.inlineGap / 2),
          ],
        ],
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: layout.screenGutter),
        child: content,
      );
    } else {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: layout.screenGutter),
        child: content,
      );
    }

    return content;
  }
}

class _SegmentTile<T> extends StatelessWidget {
  const _SegmentTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final SegmentOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTokens = context.textTokens;

    final pill = AnimatedContainer(
      duration: Motion.durationFast,
      curve: Motion.curveFast,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: layout.compactCardPadding),
      alignment: Alignment.center,
      decoration: isSelected
          ? BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(layout.controlRadius - 4),
              border: Border.all(color: scheme.outline),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A281E0F),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (option.icon != null) ...[
            option.icon!,
            SizedBox(width: layout.inlineGap),
          ],
          Flexible(
            child: Text(
              option.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTokens.eyebrow.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.08,
                color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (option.count != null) ...[
            const SizedBox(width: 7),
            if (isSelected)
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
                ),
                child: Text(
                  '${option.count}',
                  style: textTokens.eyebrow.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: scheme.onPrimary,
                  ),
                ),
              )
            else
              Text(
                '${option.count}',
                style: textTokens.eyebrow.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ],
      ),
    );

    return Semantics(
      selected: isSelected,
      button: true,
      label: '${option.label}${option.count != null ? ', ${option.count}' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(layout.controlRadius - 4),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: layout.minimumTapTarget,
              minWidth: layout.minimumTapTarget,
            ),
            child: Center(child: pill),
          ),
        ),
      ),
    );
  }
}
