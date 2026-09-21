import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/my_matches_view.dart';

/// A Confirmed-tab fixture — `My Matches.dc.html` artboards 01 / 04 / 05 / 07.
///
/// One card, one ladder. The calm form is the whole vocabulary: time gutter,
/// two team rows, meta line, role strip. Escalation adds rungs in a fixed order
/// and never changes the card's shape:
///
///   live       → the gutter's clock becomes a pulsing dot + LIVE in red ink.
///                Border, fill and layout are untouched, because a live match
///                is information, not a task.
///   tossReady  → a 2px red top rule (the same device the Challenges queue uses
///                for a row inside 6h) and the role strip grows into a
///                full-width action. The action is INK, not red: red marks the
///                window, ink does the work.
///
/// With nothing on today the list carries no red at all.
class FixtureCard extends StatelessWidget {
  const FixtureCard({super.key, required this.v, required this.onTap});

  final MyMatchConfirmed v;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final toss = v.tossReady;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.circular(14),
          // Uniform border: Flutter forbids a borderRadius on a mixed-colour
          // Border, so the 2px red top rule is drawn as a child below.
          border: Border.all(color: toss ? CkColors.redBorder : CkColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (toss) Container(height: 2, color: CkColors.red),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_gutter(), Expanded(child: _body())],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Time gutter ──────────────────────────────────────────────────────────

  Widget _gutter() {
    final toss = v.tossReady;
    final live = v.liveState != null;
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: toss ? CkColors.redSurface : CkColors.paper,
        border: Border(
          right: BorderSide(
            color: toss ? CkColors.redBorder : CkColors.hairline,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: live ? _liveGutter() : _clockGutter(),
      ),
    );
  }

  /// In play the clock is meaningless — what matters is that it is happening.
  List<Widget> _liveGutter() => [
    const _PulsingDot(size: 7),
    const SizedBox(height: 3),
    Text(
      v.liveState!,
      textAlign: TextAlign.center,
      style: CkType.mono(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.10,
        color: CkColors.redInk,
      ),
    ),
    if ((v.liveSince ?? '').isNotEmpty) ...[
      const SizedBox(height: 2),
      Text(
        v.liveSince!,
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.07,
          color: CkColors.muted,
        ),
      ),
    ],
  ];

  List<Widget> _clockGutter() {
    final t = v.startTime;
    final toss = v.tossReady;
    return [
      if (toss) ...[
        const _PulsingDot(size: 6),
        const SizedBox(height: 3),
        Text(
          'SETUP',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.09,
            color: CkColors.redInk,
          ),
        ),
        const SizedBox(height: 2),
      ],
      Text(
        t == null ? '—' : _hhmm(t),
        style: CkType.display(
          // The toss card gives two lines back to the label above it.
          fontSize: toss ? 17 : 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: CkColors.ink,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
      if (t != null)
        Text(
          _meridiem(t),
          style: CkType.mono(
            fontSize: toss ? 9 : 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: CkColors.muted,
          ),
        ),
      // The countdown carries the fine grain so the date header never has to.
      if (!toss && v.countdown.isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(
          v.countdown.toUpperCase(),
          textAlign: TextAlign.center,
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.07,
            color: CkColors.muted,
          ),
        ),
      ],
    ];
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _body() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _teamRow(
              short: v.homeShort,
              color: v.homeColor,
              name: v.homeName,
              isYou: v.youIsHome,
            ),
            const SizedBox(height: 7),
            _teamRow(
              short: v.awayShort,
              color: v.awayColor,
              name: v.awayName,
              isYou: !v.youIsHome,
              // A bracket fixture with no opponent yet prints the feeder
              // text where a team name would go, and drops the crest.
              placeholder: v.opponentTbc,
            ),
            const SizedBox(height: 7),
            Text(
              v.metaLine.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.07,
                color: CkColors.muted,
              ),
            ),
            if ((v.tbcNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                v.tbcNote!,
                style: CkType.body(fontSize: 11.5, color: CkColors.muted),
              ),
            ],
            if (v.tossReady && (v.helper ?? '').isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                v.helper!,
                style: CkType.body(
                  fontSize: 12,
                  height: 1.45,
                  color: CkColors.ink2,
                ),
              ),
            ],
          ],
        ),
      ),
      if (v.tossReady) _tossAction() else _roleStrip(),
    ],
  );

  Widget _teamRow({
    required String short,
    required Color color,
    required String name,
    required bool isYou,
    bool placeholder = false,
  }) => Row(
    children: [
      if (placeholder)
        const SizedBox(width: 20, height: 20)
      else
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            short.toUpperCase(),
            style: CkType.display(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      const SizedBox(width: 8),
      Expanded(
        child: Text.rich(
          TextSpan(
            text: name,
            children: [
              // YOU rides the team name in soft mono. It says which row is
              // ours; it never says what we owe — that is the strip's job.
              if (isYou)
                TextSpan(
                  text: '  YOU',
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.soft,
                  ),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CkType.display(
            fontSize: 14.5,
            fontWeight: placeholder ? FontWeight.w500 : FontWeight.w600,
            letterSpacing: -0.01,
            color: placeholder ? CkColors.muted : CkColors.ink,
          ),
        ),
      ),
    ],
  );

  /// Printed only when the viewer owes something, or when their participation
  /// is itself the news. A spectator gets no band and the card is shorter.
  Widget _roleStrip() {
    if (v.role.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              v.role.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.09,
                color: CkColors.ink2,
              ),
            ),
          ),
          // Duties route somewhere and take the arrow; states do not, so the
          // arrow keeps meaning "there is something on the other side".
          if (v.roleIsDuty) ...[
            const SizedBox(width: 8),
            Text(
              '→',
              style: CkType.mono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CkColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The toss window's action replaces the role strip. Ink, not red — the red
  /// rule above already marks the window.
  Widget _tossAction() => Padding(
    padding: const EdgeInsets.fromLTRB(13, 0, 13, 12),
    child: Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'START MATCH →',
        style: CkType.mono(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: CkColors.paper,
        ),
      ),
    ),
  );
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.size});

  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 1, end: 0.25).animate(_c),
    child: Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        color: CkColors.red,
        shape: BoxShape.circle,
      ),
    ),
  );
}

String _hhmm(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')}';
}

String _meridiem(DateTime t) => t.hour < 12 ? 'AM' : 'PM';
