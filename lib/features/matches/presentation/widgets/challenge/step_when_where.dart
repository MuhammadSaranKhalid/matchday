import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import 'ch_chip.dart';
import 'ch_icons.dart';
import 'ch_section_label.dart';

/// A previously-used venue surfaced as a quick-pick row on Step 4.
class RecentVenue {
  const RecentVenue({
    required this.id,
    required this.name,
    required this.sub,
  });

  final String id;
  final String name;

  /// Free-form line like "5 km · 2 pitches · last Mar 14".
  final String sub;
}

/// "When & where" — date + time + venue picker.
///
/// Reproduces `StepWhen` from `challenge-send.jsx` lines 354–458:
/// horizontal day strip (today + 7 + Pick) → time chips grouped by
/// Morning / Afternoon / Evening → recent-venue cards + free-text input
/// + a decorative map-preview tile once a venue is resolved.
///
/// State is owned by the caller; this widget is a controlled component.
class StepWhenWhere extends StatelessWidget {
  const StepWhenWhere({
    super.key,
    required this.selectedDay,
    required this.selectedTime,
    required this.venue,
    required this.onDayPicked,
    required this.onTimePicked,
    required this.onVenueChanged,
    this.recentVenues = const [],
    this.times = _defaultTimes,
  });

  /// The day the user picked. Date-only — time-of-day is irrelevant here.
  final DateTime? selectedDay;

  /// "HH:mm" 24h, e.g. "17:30".
  final String? selectedTime;

  /// Currently-typed or picked venue name.
  final String venue;

  final ValueChanged<DateTime> onDayPicked;
  final ValueChanged<String> onTimePicked;
  final ValueChanged<String> onVenueChanged;

  /// Quick-pick venue rows. Empty by default — caller wires this up to a
  /// server query when one exists.
  final List<RecentVenue> recentVenues;

  /// Time slots to show. Defaults to the design's 17-slot catalogue from
  /// `challenge-data.jsx`. Override to pin a different set.
  final List<String> times;

  /// The design's sparse 30-min catalogue: 08:00–10:00 + 14:00–16:30 +
  /// 17:00–19:30. Source: `challenge-data.jsx` line 49.
  static const _defaultTimes = [
    '08:00', '08:30', '09:00', '09:30', '10:00',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
  ];

  static const _dow = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _mon = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = List.generate(8, (i) => today.add(Duration(days: i)));
    final selectedIsCustom = selectedDay != null &&
        !days.any((d) => _sameDay(d, selectedDay!));

    final periods = <_Period>[
      _Period('Morning',
          times.where((t) => int.parse(t.split(':')[0]) < 12).toList()),
      _Period(
        'Afternoon',
        times.where((t) {
          final h = int.parse(t.split(':')[0]);
          return h >= 12 && h < 17;
        }).toList(),
      ),
      _Period('Evening',
          times.where((t) => int.parse(t.split(':')[0]) >= 17).toList()),
    ].where((p) => p.items.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: ChSectionLabel('Date', hint: 'Tap a day'),
        ),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
            itemCount: days.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == days.length) {
                return _PickDayTile(
                  selected: selectedIsCustom,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDay ?? today,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 365)),
                    );
                    if (picked != null) onDayPicked(picked);
                  },
                );
              }
              return _DayPill(
                day: days[i],
                isToday: i == 0,
                selected: selectedDay != null && _sameDay(days[i], selectedDay!),
                onTap: () => onDayPicked(days[i]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ChSectionLabel('Start time', hint: '30-min slots'),
              for (final period in periods) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    period.label.toUpperCase(),
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.10,
                      color: CkColors.muted,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in period.items)
                      ChChip(
                        label: t,
                        active: selectedTime == t,
                        onTap: () => onTimePicked(t),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: _VenueSection(
            venue: venue,
            recentVenues: recentVenues,
            onVenueChanged: onVenueChanged,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Expose to inner widgets via a static helper.
  static String dowOf(DateTime d, {required bool isToday}) =>
      isToday ? 'TODAY' : _dow[d.weekday - 1];
  static String monOf(DateTime d) => _mon[d.month - 1];
}

class _Period {
  const _Period(this.label, this.items);
  final String label;
  final List<String> items;
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.isToday,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? CkColors.paper : CkColors.ink;
    final bg = selected ? CkColors.ink : CkColors.paper;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              StepWhenWhere.dowOf(day, isToday: isToday),
              style: CkType.mono(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: fg.withValues(alpha: selected ? 0.85 : 0.55),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: CkType.display(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.03,
                color: fg,
              ),
            ),
            Text(
              StepWhenWhere.monOf(day),
              style: CkType.body(
                fontSize: 8.5,
                color: fg.withValues(alpha: 0.6),
                letterSpacing: 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickDayTile extends StatelessWidget {
  const _PickDayTile({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? CkColors.paper : CkColors.muted;
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        // JSX: `1px dashed` border (`var(--line)` when off, `ink` when on).
        // Flutter's BoxDecoration only paints solid borders, so the dashed
        // outline is hand-painted here.
        painter: _DashedBorderPainter(
          color: selected ? CkColors.ink : CkColors.line,
          radius: 14,
          dashWidth: 4,
          dashGap: 3,
          strokeWidth: 1,
        ),
        child: Container(
          width: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? CkColors.ink : CkColors.paper,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              V2Svg(ChIcons.cal, size: 16, color: fg, strokeWidth: 1.8),
              const SizedBox(height: 5),
              Text(
                'Pick',
                style: CkType.body(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rectangle stroke around a child. Used by the
/// "Pick" day tile and the open-challenge crest placeholder on Review.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap ||
      old.strokeWidth != strokeWidth;
}

class _VenueSection extends StatefulWidget {
  const _VenueSection({
    required this.venue,
    required this.recentVenues,
    required this.onVenueChanged,
  });

  final String venue;
  final List<RecentVenue> recentVenues;
  final ValueChanged<String> onVenueChanged;

  @override
  State<_VenueSection> createState() => _VenueSectionState();
}

class _VenueSectionState extends State<_VenueSection> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.venue);

  @override
  void didUpdateWidget(covariant _VenueSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync external changes (e.g. tapping a recent-venue card) into the field.
    if (widget.venue != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: widget.venue,
        selection: TextSelection.collapsed(offset: widget.venue.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.venue.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ChSectionLabel('Venue', hint: 'Recent'),
        if (widget.recentVenues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              children: [
                for (final v in widget.recentVenues) ...[
                  _VenueRow(
                    venue: v,
                    selected: widget.venue == v.name,
                    onTap: () => widget.onVenueChanged(v.name),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        TextField(
          controller: _ctrl,
          onChanged: widget.onVenueChanged,
          style: CkType.body(fontSize: 14, color: CkColors.ink),
          decoration: InputDecoration(
            hintText: 'Or type a new venue…',
            hintStyle: CkType.body(fontSize: 14, color: CkColors.soft),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CkColors.hairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CkColors.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CkColors.ink, width: 1.5),
            ),
          ),
        ),
        if (resolved) ...[
          const SizedBox(height: 12),
          _MapPreview(label: widget.venue.trim()),
        ],
      ],
    );
  }
}

class _VenueRow extends StatelessWidget {
  const _VenueRow({
    required this.venue,
    required this.selected,
    required this.onTap,
  });

  final RecentVenue venue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? CkColors.paper2 : CkColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CkColors.hairline),
              ),
              child: const V2Svg(
                ChIcons.pin,
                size: 15,
                color: CkColors.ink,
                strokeWidth: 1.8,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    venue.name,
                    style: CkType.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      venue.sub,
                      style:
                          CkType.body(fontSize: 11, color: CkColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const V2Svg(
                ChIcons.check,
                size: 16,
                color: CkColors.ink,
                strokeWidth: 2.4,
              ),
          ],
        ),
      ),
    );
  }
}

/// Decorative map placeholder — diagonal-stripe background under a stylised
/// pitch motif (horizontal popping crease, vertical line, centre circle),
/// matching `StepWhen`'s map block in `challenge-send.jsx` (lines 435–453).
/// The pin glyph overlays the centre. Replace with a real map embed when
/// the venue lookup ships.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: CkColors.hairline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _PitchPainter()),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 26,
                    child: Center(
                      child: V2Svg(
                        ChIcons.pin,
                        size: 28,
                        color: CkColors.red,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: CkColors.paper,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const V2Svg(
                    ChIcons.pin,
                    size: 13,
                    color: CkColors.muted,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          CkType.body(fontSize: 12, color: CkColors.ink2),
                    ),
                  ),
                  Text(
                    'MAP PREVIEW',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.10,
                      color: CkColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the diagonal-stripe `paper2 ↔ paper` background + a stylised
/// pitch motif at 50% opacity, per the JSX `<svg>` block.
class _PitchPainter extends CustomPainter {
  static const _stripePeriod = 28.0; // 14px of paper2 + 14px of paper

  @override
  void paint(Canvas canvas, Size size) {
    // Base fill — paper.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = CkColors.paper,
    );

    // Diagonal stripes (45°), alternating paper2 over paper.
    final stripe = Paint()..color = CkColors.paper2;
    final diag = size.width + size.height;
    for (var d = -size.height; d < diag; d += _stripePeriod) {
      final path = Path()
        ..moveTo(d, 0)
        ..lineTo(d + 14, 0)
        ..lineTo(d + 14 + size.height, size.height)
        ..lineTo(d + size.height, size.height)
        ..close();
      canvas.drawPath(path, stripe);
    }

    // Pitch motif at 50% opacity.
    final lineColor = CkColors.line.withValues(alpha: 0.5);
    final h = Paint()
      ..style = PaintingStyle.stroke
      ..color = lineColor
      ..strokeWidth = 6;
    canvas.drawLine(const Offset(0, 64), Offset(size.width, 64), h);

    final v = Paint()
      ..style = PaintingStyle.stroke
      ..color = lineColor
      ..strokeWidth = 4;
    canvas.drawLine(const Offset(130, 0), const Offset(130, 100), v);

    final c = Paint()
      ..style = PaintingStyle.stroke
      ..color = lineColor
      ..strokeWidth = 2;
    canvas.drawCircle(const Offset(130, 64), 26, c);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter old) => false;
}
