import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../domain/entities/match.dart';
import 'ch_icons.dart';
import 'ch_section_label.dart';
import 'step_pick_xi.dart' show XiCandidate;

/// "Review & send" — the final step of the Match Challenge Flow.
///
/// Reproduces `StepReview` in `challenge-send.jsx` lines 693–764: an ink
/// summary card (kicker · crest-vs-crest · big date+time · venue) followed
/// by a paper RevRows section (Format / Overs / Ball·bowler / Innings /
/// optional Keeper / Claim window), then the 280-char message field with a
/// counter that appears at 240 chars and turns red at exactly 280, and
/// finally an optional "Your XI" chip strip when an XI was picked.
///
/// State is owned by the caller; this widget is a controlled component.
class StepReview extends StatelessWidget {
  const StepReview({
    super.key,
    required this.fromTeam,
    required this.opponent,
    required this.format,
    required this.presetLabel,
    required this.startTime,
    required this.venue,
    required this.pickedXi,
    required this.keeperId,
    required this.messageController,
    required this.onMessageChanged,
    this.isOpen = false,
  });

  /// The team issuing the challenge.
  final Team fromTeam;

  /// Receiving team. Null is allowed only when [isOpen] is true.
  final Team? opponent;

  /// True for the "open challenge" path — replaces the opponent crest with
  /// a dashed share placeholder and swaps the claim-window row in.
  final bool isOpen;

  /// Snapshot of the format that will ship with the request.
  final MatchFormat format;

  /// Display label of the chosen preset (T20, ODI, etc.). Caller looks it
  /// up from `formatPresetsProvider`.
  final String presetLabel;

  final DateTime startTime;
  final String venue;

  /// The XI that was picked in step 5. Empty list means "no XI shipped" —
  /// the chip strip below the message is hidden.
  final List<XiCandidate> pickedXi;

  /// The keeper player-id. Used to look up the keeper's name for the
  /// "Your keeper" RevRow and to render a `WK` badge on the matching chip.
  final String? keeperId;

  final TextEditingController messageController;

  /// Fired on every keystroke. The caller uses this to drive the counter
  /// (no controller listener is attached internally).
  final VoidCallback onMessageChanged;

  String? get _keeperName {
    if (keeperId == null) return null;
    for (final p in pickedXi) {
      if (p.id == keeperId) return p.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      children: [
        _SummaryCard(
          fromTeam: fromTeam,
          opponent: opponent,
          isOpen: isOpen,
          startTime: startTime,
          venue: venue,
        ),
        const SizedBox(height: 16),
        _RevRows(
          presetLabel: presetLabel,
          format: format,
          isOpen: isOpen,
          keeperName: _keeperName,
        ),
        const SizedBox(height: 16),
        _MessageField(
          controller: messageController,
          onChanged: onMessageChanged,
          isOpen: isOpen,
          opponentName: opponent?.name ?? '',
        ),
        if (!isOpen && pickedXi.isNotEmpty) ...[
          const SizedBox(height: 16),
          _YourXi(picked: pickedXi, keeperId: keeperId),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

// ─── Hero summary card ────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.fromTeam,
    required this.opponent,
    required this.isOpen,
    required this.startTime,
    required this.venue,
  });

  final Team fromTeam;
  final Team? opponent;
  final bool isOpen;
  final DateTime startTime;
  final String venue;

  static const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _mon = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _hhmm(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dateLine(DateTime t) =>
      '${_dow[t.weekday - 1]} ${t.day} ${_mon[t.month - 1]} · ${_hhmm(t)}';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: CkColors.hairline),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          color: CkColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isOpen ? 'OPEN CHALLENGE' : 'FRIENDLY MATCH',
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: CkColors.paper.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _CrestLabel(team: fromTeam)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: V2Svg(
                      ChIcons.swords,
                      size: 18,
                      color: CkColors.paper.withValues(alpha: 0.55),
                      strokeWidth: 2,
                    ),
                  ),
                  Expanded(
                    child: isOpen
                        ? const _OpenSlot()
                        : _CrestLabel(team: opponent),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: CkColors.paper.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _dateLine(startTime),
                      textAlign: TextAlign.center,
                      style: CkType.display(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02,
                        color: CkColors.paper,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      venue.trim().isEmpty ? 'Venue TBD' : venue.trim(),
                      textAlign: TextAlign.center,
                      style: CkType.body(
                        fontSize: 12,
                        color: CkColors.paper.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrestLabel extends StatelessWidget {
  const _CrestLabel({required this.team});
  final Team? team;

  static String _mono(Team t) {
    final override = t.logoMonogram?.trim();
    if (override != null && override.isNotEmpty) return override.toUpperCase();
    final parts =
        t.name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '–';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (parts.first[0] + parts.elementAt(1)[0]).toUpperCase();
  }

  static Color _color(Team t) {
    final hex = t.primaryColor;
    if (hex == null || hex.isEmpty) return CkCrest.ll;
    final norm = hex.startsWith('#') ? hex.substring(1) : hex;
    final v = int.tryParse(norm, radix: 16);
    if (v == null) return CkCrest.ll;
    return Color(norm.length == 6 ? (0xFF000000 | v) : v);
  }

  @override
  Widget build(BuildContext context) {
    final t = team;
    if (t == null) {
      return Center(
        child: Text(
          '—',
          style: CkType.display(
            fontSize: 12.5,
            color: CkColors.paper.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Crest(
          short: _mono(t),
          color: _color(t),
          logoUrl: t.logoUrl,
          size: 44,
          radius: 11,
        ),
        const SizedBox(height: 6),
        Text(
          t.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: CkType.display(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: CkColors.paper,
          ),
        ),
      ],
    );
  }
}

/// Dashed share-icon placeholder used in place of the opponent crest on the
/// open-challenge variant. Matches the JSX
/// `border: '1.5px dashed rgba(255,255,255,0.4)'` square.
class _OpenSlot extends StatelessWidget {
  const _OpenSlot();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: _DashedRoundedSquarePainter(
            color: CkColors.paper.withValues(alpha: 0.4),
            radius: 11,
            dashWidth: 4,
            dashGap: 3,
            strokeWidth: 1.5,
          ),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: V2Svg(
                ChIcons.share,
                size: 18,
                color: CkColors.paper.withValues(alpha: 0.7),
                strokeWidth: 1.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Open',
          style: CkType.display(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: CkColors.paper,
          ),
        ),
      ],
    );
  }
}

class _DashedRoundedSquarePainter extends CustomPainter {
  const _DashedRoundedSquarePainter({
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
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        final n = (d + dashWidth).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(d, n), paint);
        d = n + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedSquarePainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap ||
      old.strokeWidth != strokeWidth;
}

// ─── RevRows ──────────────────────────────────────────────────────────────

class _RevRows extends StatelessWidget {
  const _RevRows({
    required this.presetLabel,
    required this.format,
    required this.isOpen,
    required this.keeperName,
  });

  final String presetLabel;
  final MatchFormat format;
  final bool isOpen;
  final String? keeperName;

  String get _ballLabel {
    switch (format.ballType) {
      case MatchBallType.leather:
        return 'Hardball';
      case MatchBallType.tape:
        return 'Tape';
      case MatchBallType.tennis:
        return 'Tennis';
    }
  }

  String get _oversValue {
    final overs = (format.oversPerInnings >= 50 && format.inningsPerSide == 2)
        ? 'Unlimited'
        : '${format.oversPerInnings}';
    return '$overs · ${format.ballsPerOver}-ball';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <_Rev>[
      _Rev('Format', '$presetLabel · ${format.playersPerTeam} a side'),
      _Rev('Overs', _oversValue),
      _Rev('Ball · bowler', '$_ballLabel · ${format.maxOversPerBowler} max'),
      _Rev('Innings', '${format.inningsPerSide} per side'),
      if (!isOpen && keeperName != null && keeperName!.isNotEmpty)
        _Rev('Your keeper', keeperName!),
      if (isOpen) const _Rev('Claim window', '24h · 6-digit code'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _RevRow(row: rows[i], last: i == rows.length - 1),
          ],
        ],
      ),
    );
  }
}

class _Rev {
  const _Rev(this.label, this.value);
  final String label;
  final String value;
}

class _RevRow extends StatelessWidget {
  const _RevRow({required this.row, required this.last});

  final _Rev row;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border(
          bottom: last
              ? BorderSide.none
              : const BorderSide(color: CkColors.hairline),
        ),
      ),
      child: Row(
        children: [
          Text(
            row.label,
            style: CkType.body(fontSize: 12, color: CkColors.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              style: CkType.body(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message field ────────────────────────────────────────────────────────

class _MessageField extends StatelessWidget {
  const _MessageField({
    required this.controller,
    required this.onChanged,
    required this.isOpen,
    required this.opponentName,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool isOpen;
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    final len = controller.text.length;
    final near = len >= 240;
    final atCap = len >= 280;
    final label =
        isOpen ? 'Message (shown on claim)' : 'Message to $opponentName';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChSectionLabel(label, hint: near ? '$len/280' : ''),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          maxLength: 280,
          maxLines: 3,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) =>
              null,
          style: CkType.body(
            fontSize: 13,
            color: CkColors.ink,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: isOpen
                ? 'e.g. Friendly this Saturday — hardball, bring 11.'
                : 'e.g. Rematch from May? Same ground, same time.',
            hintStyle: CkType.body(fontSize: 13, color: CkColors.soft),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CkColors.hairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CkColors.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CkColors.ink, width: 1.5),
            ),
          ),
        ),
        if (near)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${280 - len} LEFT',
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: atCap ? CkColors.red : CkColors.muted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Your XI chip strip ───────────────────────────────────────────────────

class _YourXi extends StatelessWidget {
  const _YourXi({required this.picked, required this.keeperId});

  final List<XiCandidate> picked;
  final String? keeperId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChSectionLabel('Your XI', hint: '${picked.length} players'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in picked)
              _XiChip(
                name: p.name,
                captain: p.captain,
                keeper: keeperId == p.id,
              ),
          ],
        ),
      ],
    );
  }
}

class _XiChip extends StatelessWidget {
  const _XiChip({
    required this.name,
    required this.captain,
    required this.keeper,
  });

  final String name;
  final bool captain;
  final bool keeper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: CkType.body(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (captain) ...[
            const SizedBox(width: 4),
            const _TinyBadge(text: 'C', bg: CkColors.ink, fg: CkColors.paper),
          ],
          if (keeper) ...[
            const SizedBox(width: 4),
            const _TinyBadge(text: 'WK', bg: CkColors.red, fg: CkColors.paper),
          ],
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: CkType.mono(
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10,
          color: fg,
        ),
      ),
    );
  }
}
