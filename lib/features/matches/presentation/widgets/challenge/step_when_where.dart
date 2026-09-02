import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../pool/pool_icons.dart';
import '../wizard/wizard_kit.dart';

/// When & where — `Pool.dc.html` artboard 08.
///
/// Two of the three answers here may be absent, and the design says so out
/// loud: the venue is explicitly optional, and Flexible drops the start time
/// so the card reads "Flexible" rather than committing to an hour nobody
/// agreed. That is why the board's card renders its meta block conditionally.
class StepWhenWhere extends StatelessWidget {
  const StepWhenWhere({
    super.key,
    required this.day,
    required this.time,
    required this.flexible,
    required this.venueController,
    required this.onDay,
    required this.onTime,
    required this.onFlexible,
  });

  /// The chosen calendar day, time-of-day stripped.
  final DateTime? day;

  /// Minutes since midnight. Null until picked.
  final int? time;
  final bool flexible;
  final TextEditingController venueController;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<int> onTime;
  final ValueChanged<bool> onFlexible;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final t1 = t0.add(const Duration(days: 1));
    final isToday = day != null && _sameDay(day!, t0);
    final isTomorrow = day != null && _sameDay(day!, t1);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        const WizardHeading('When & where'),
        const SizedBox(height: 20),
        const WizardFieldLabel('Day'),
        const SizedBox(height: 11),
        Row(
          children: [
            _DayChip(
              label: 'Today',
              selected: isToday,
              onTap: () => onDay(t0),
            ),
            const SizedBox(width: 8),
            _DayChip(
              label: 'Tomorrow',
              selected: isTomorrow,
              onTap: () => onDay(t1),
            ),
            const SizedBox(width: 8),
            _DayChip(
              label: day != null && !isToday && !isTomorrow
                  ? _shortDate(day!)
                  : 'Pick',
              selected: day != null && !isToday && !isTomorrow,
              icon: PoolIcons.calendar,
              onTap: () => _pickDay(context, t0),
            ),
          ],
        ),
        const SizedBox(height: 22),
        WizardFieldLabel(
          'Start time',
          trailing: _FlexibleToggle(value: flexible, onChanged: onFlexible),
        ),
        const SizedBox(height: 12),
        _TimeField(
          minutes: time,
          disabled: flexible,
          onTap: () => _pickTime(context),
        ),
        const SizedBox(height: 22),
        const WizardFieldLabel('Venue', optional: true),
        const SizedBox(height: 11),
        _VenueField(controller: venueController),
        const SizedBox(height: 9),
        Text(
          "Leave blank if you'll agree the ground with your opponent later.",
          style: CkType.body(fontSize: 11.5, height: 1.4, color: CkColors.muted),
        ),
      ],
    );
  }

  Future<void> _pickDay(BuildContext context, DateTime today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 120)),
    );
    if (picked != null) onDay(DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTime(BuildContext context) async {
    if (flexible) return;
    final initial = time == null
        ? const TimeOfDay(hour: 16, minute: 30)
        : TimeOfDay(hour: time! ~/ 60, minute: time! % 60);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) onTime(picked.hour * 60 + picked.minute);
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

/// "4:30 PM" from minutes since midnight.
String clockLabel(int minutes) {
  final h24 = minutes ~/ 60;
  final h = h24 % 12 == 0 ? 12 : h24 % 12;
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m ${h24 >= 12 ? 'PM' : 'AM'}';
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: icon == null ? 16 : 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: selected ? null : Border.all(color: CkColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && !selected) ...[
              PoolIcon(icon!, size: 15),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: CkType.display(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? CkColors.paper : CkColors.ink2,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlexibleToggle extends StatelessWidget {
  const _FlexibleToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FLEXIBLE',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
              color: value ? CkColors.ink : CkColors.muted,
            ),
          ),
          const SizedBox(width: 9),
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 38,
            height: 22,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? CkColors.ink : CkColors.line,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: CkColors.paper,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.minutes,
    required this.disabled,
    required this.onTap,
  });

  final int? minutes;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CkColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                disabled
                    ? 'Flexible'
                    : (minutes == null ? 'Pick a time' : clockLabel(minutes!)),
                // A placeholder set at the value's own size and weight reads
                // as a value. Empty steps down to body scale so the field
                // looks unanswered rather than answered with words.
                style: CkType.display(
                  fontSize: minutes == null && !disabled ? 15 : 20,
                  fontWeight: minutes == null && !disabled
                      ? FontWeight.w500
                      : FontWeight.w700,
                  color: minutes == null && !disabled
                      ? CkColors.soft
                      : CkColors.ink,
                  letterSpacing: -0.01,
                ).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const PoolIcon(PoolIcons.clockMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueField extends StatelessWidget {
  const _VenueField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        children: [
          const PoolIcon(PoolIcons.pinInk, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: CkColors.red,
              cursorWidth: 1.5,
              style: CkType.body(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CkColors.ink,
              ),
              decoration: bareInput(
                hintText: 'Ground name',
                hintStyle: CkType.body(fontSize: 14, color: CkColors.soft),
              ).copyWith(
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
