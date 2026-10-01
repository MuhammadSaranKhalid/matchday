import 'package:flutter/material.dart';

import '../../../../../core/design_system/design_system.dart';
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
    final layout = context.layout;
    final scheme = context.colorScheme;
    final status = context.statusColors;

    final toss = v.tossReady;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(layout.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.cardRadius),
            border: Border.all(
              color: toss ? status.liveBorder : scheme.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (toss) Container(height: 2, color: status.live),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _gutter(context),
                    Expanded(child: _body(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Time gutter ──────────────────────────────────────────────────────────

  Widget _gutter(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final status = context.statusColors;

    final toss = v.tossReady;
    final live = v.liveState != null;
    return Container(
      width: 84,
      padding: EdgeInsets.symmetric(vertical: layout.inlineGap),
      decoration: BoxDecoration(
        color: toss ? status.liveSurface : scheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: toss ? status.liveBorder : scheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: live ? _liveGutter(context) : _clockGutter(context),
      ),
    );
  }

  /// In play the clock is meaningless — what matters is that it is happening.
  List<Widget> _liveGutter(BuildContext context) {
    final textTokens = context.textTokens;
    final scheme = context.colorScheme;
    final status = context.statusColors;

    return [
      const _PulsingDot(size: 7),
      const SizedBox(height: 3),
      Text(
        v.liveState!,
        textAlign: TextAlign.center,
        style: textTokens.mono.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10,
          color: status.live,
        ),
      ),
      if ((v.liveSince ?? '').isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(
          v.liveSince!,
          style: textTokens.mono.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.07,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    ];
  }

  List<Widget> _clockGutter(BuildContext context) {
    final textTokens = context.textTokens;
    final textTheme = context.textTheme;
    final scheme = context.colorScheme;
    final status = context.statusColors;

    final t = v.startTime;
    final toss = v.tossReady;
    return [
      if (toss) ...[
        const _PulsingDot(size: 6),
        const SizedBox(height: 3),
        Text(
          'TOSS',
          style: textTokens.mono.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.09,
            color: status.live,
          ),
        ),
        const SizedBox(height: 2),
      ],
      Text(
        t == null ? '—' : _hhmm(t),
        style: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
          fontSize: toss ? 17 : 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      if (t != null)
        Text(
          _meridiem(t),
          style: textTokens.mono.copyWith(
            fontSize: toss ? 9 : 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: scheme.onSurfaceVariant,
          ),
        ),
      if (!toss && v.countdown.isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(
          v.countdown.toUpperCase(),
          textAlign: TextAlign.center,
          style: textTokens.mono.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.07,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    ];
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _body(BuildContext context) {
    final layout = context.layout;
    final textTokens = context.textTokens;
    final textTheme = context.textTheme;
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            layout.inlineGap,
            layout.inlineGap - 1,
            layout.inlineGap,
            layout.inlineGap - 1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _teamRow(
                context,
                short: v.homeShort,
                color: v.homeColor,
                name: v.homeName,
                isYou: v.youIsHome,
              ),
              const SizedBox(height: 7),
              _teamRow(
                context,
                short: v.awayShort,
                color: v.awayColor,
                name: v.awayName,
                isYou: !v.youIsHome,
                placeholder: v.opponentTbc,
              ),
              const SizedBox(height: 7),
              Text(
                v.metaLine.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTokens.mono.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.07,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if ((v.tbcNote ?? '').isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  v.tbcNote!,
                  style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (v.tossReady && (v.helper ?? '').isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  v.helper!,
                  style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                    fontSize: 12,
                    height: 1.45,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (v.tossReady) _tossAction(context) else _roleStrip(context),
      ],
    );
  }

  Widget _teamRow(
    BuildContext context, {
    required String short,
    required Color color,
    required String name,
    required bool isYou,
    bool placeholder = false,
  }) {
    final textTokens = context.textTokens;
    final textTheme = context.textTheme;
    final scheme = context.colorScheme;

    return Row(
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
              style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
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
                if (isYou)
                  TextSpan(
                    text: '  YOU',
                    style: textTokens.mono.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
              fontSize: 14.5,
              fontWeight: placeholder ? FontWeight.w500 : FontWeight.w600,
              letterSpacing: -0.01,
              color: placeholder ? scheme.onSurfaceVariant : scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _roleStrip(BuildContext context) {
    if (v.role.trim().isEmpty) return const SizedBox.shrink();

    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTokens = context.textTokens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.inlineGap,
        vertical: layout.inlineGap - 3,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              v.role.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTokens.mono.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.09,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (v.roleIsDuty) ...[
            const SizedBox(width: 8),
            Text(
              '→',
              style: textTokens.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tossAction(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTokens = context.textTokens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        layout.inlineGap,
        0,
        layout.inlineGap,
        layout.inlineGap,
      ),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(layout.controlRadius - 4),
        ),
        child: Text(
          'START MATCH · TOSS →',
          style: textTokens.mono.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08,
            color: scheme.onPrimary,
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final status = context.statusColors;

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.25).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: status.live,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

String _hhmm(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')}';
}

String _meridiem(DateTime t) => t.hour < 12 ? 'AM' : 'PM';
