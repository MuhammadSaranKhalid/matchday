import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import 'ch_icons.dart';
import 'ch_role_pill.dart';
import 'ch_section_label.dart';

/// One row in the Pick XI roster list. Lightweight view shape so the
/// widget stays independent of the domain's `RosterMember` (callers map
/// their roster to this at the boundary).
class XiCandidate {
  const XiCandidate({
    required this.id,
    required this.name,
    required this.role,
    this.subStyle,
    this.captain = false,
    this.guest = false,
    this.unclaimed = false,
  });

  /// Stable id used for XI / keeper lookups (typically `playerId`).
  final String id;
  final String name;
  final ChPlayingRole role;

  /// Optional second line, e.g. "RHB · RM".
  final String? subStyle;

  /// Renders the "C" badge when true.
  final bool captain;

  /// Renders the amber "GUEST" tag (borrowed from another team).
  final bool guest;

  /// Renders the muted "NEW" tag (unclaimed placeholder).
  final bool unclaimed;
}

/// "Pick for this match" — the Pick-XI step.
///
/// Reproduces `StepXI` from `challenge-send.jsx` lines 463–534:
/// counter strip + AUTO/CLEAR mini buttons + progress bar; horizontal
/// keeper picker chip strip (currently-picked players only, glove glyph);
/// roster list with checkbox + Avatar + name + role pill + captain / WK /
/// guest / new badges.
///
/// State is owned by the caller (callbacks below). The widget itself only
/// renders + dims rows that would over-select the XI.
class StepPickXi extends StatelessWidget {
  const StepPickXi({
    super.key,
    required this.roster,
    required this.playersNeeded,
    required this.xi,
    required this.keeperId,
    required this.onToggle,
    required this.onKeeper,
    required this.onAutoFill,
    required this.onClear,
  });

  /// Full effective roster (active members + any guests/unclaimed extras).
  final List<XiCandidate> roster;

  /// XI target — usually the format's `playersPerTeam`.
  final int playersNeeded;

  /// Currently-picked player ids.
  final Set<String> xi;

  /// Currently-picked keeper id (must be in [xi]).
  final String? keeperId;

  /// Toggles [playerId] in/out of the XI. The widget refuses taps that
  /// would push the count past [playersNeeded] (the row is dimmed).
  final ValueChanged<String> onToggle;

  /// Sets the keeper. Pass null to clear (e.g. when a chip is tapped while
  /// already active).
  final ValueChanged<String?> onKeeper;

  /// Fired by the AUTO button. Caller decides the policy (first N + first
  /// WK as keeper, per the JSX default).
  final VoidCallback onAutoFill;

  /// Fired by the CLEAR button.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final picked = roster.where((p) => xi.contains(p.id)).toList();
    final full = xi.length >= playersNeeded;
    return Column(
      children: [
        _CounterStrip(
          count: xi.length,
          total: playersNeeded,
          onAuto: onAutoFill,
          onClear: onClear,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: ChSectionLabel(
                  'Wicket-keeper',
                  hint: keeperId == null ? 'Required' : '',
                ),
              ),
              if (picked.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 6),
                  child: Text(
                    'Pick players first, then choose your keeper.',
                    style: TextStyle(fontSize: 12, color: CkColors.muted),
                  ),
                )
              else
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                    itemCount: picked.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final p = picked[i];
                      final on = keeperId == p.id;
                      return _KeeperChip(
                        firstName: p.name.split(' ').first,
                        selected: on,
                        onTap: () => onKeeper(on ? null : p.id),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                child: Text(
                  'SQUAD · ${roster.length}',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10,
                    color: CkColors.muted,
                  ),
                ),
              ),
              for (var i = 0; i < roster.length; i++)
                _PlayerRow(
                  index: i,
                  player: roster[i],
                  selected: xi.contains(roster[i].id),
                  isKeeper: keeperId == roster[i].id,
                  disabled: !xi.contains(roster[i].id) && full,
                  onTap: () => onToggle(roster[i].id),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterStrip extends StatelessWidget {
  const _CounterStrip({
    required this.count,
    required this.total,
    required this.onAuto,
    required this.onClear,
  });

  final int count;
  final int total;
  final VoidCallback onAuto;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final full = count >= total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Text(
            'XI · $count/$total',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: full ? CkColors.green : CkColors.ink2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    Container(color: CkColors.paper2),
                    FractionallySizedBox(
                      widthFactor: total == 0
                          ? 0
                          : (count / total).clamp(0.0, 1.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        color: full ? CkColors.green : CkColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _MiniButton(label: 'AUTO', onTap: onAuto),
          const SizedBox(width: 6),
          _MiniButton(label: 'CLEAR', onTap: onClear),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: CkColors.ink2,
          ),
        ),
      ),
    );
  }
}

class _KeeperChip extends StatelessWidget {
  const _KeeperChip({
    required this.firstName,
    required this.selected,
    required this.onTap,
  });

  final String firstName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? CkColors.red : CkColors.paper;
    final fg = selected ? CkColors.paper : CkColors.ink2;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? CkColors.red : CkColors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            V2Svg(
              ChIcons.glove,
              size: 13,
              color: selected ? CkColors.paper : CkColors.muted,
              strokeWidth: 1.8,
            ),
            const SizedBox(width: 6),
            Text(
              firstName,
              style: CkType.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.index,
    required this.player,
    required this.selected,
    required this.isKeeper,
    required this.disabled,
    required this.onTap,
  });

  final int index;
  final XiCandidate player;
  final bool selected;
  final bool isKeeper;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? CkColors.paper : Colors.transparent,
            border: Border(
              top: index == 0
                  ? BorderSide.none
                  : const BorderSide(color: CkColors.hairline),
            ),
          ),
          child: Row(
            children: [
              _Checkbox(on: selected),
              const SizedBox(width: 12),
              Avatar(mono: _initials(player.name), size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          player.name,
                          style: CkType.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.02,
                          ),
                        ),
                        ChRolePill(role: player.role),
                        if (player.guest) _MiniBadge.guest(),
                        if (player.unclaimed) _MiniBadge.unclaimed(),
                        if (player.captain) _MiniBadge.captain(),
                        if (isKeeper) _MiniBadge.keeper(),
                      ],
                    ),
                    if (player.subStyle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          player.subStyle!,
                          style: CkType.mono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.10,
                            color: CkColors.muted,
                          ),
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

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '–';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (parts.first[0] + parts.elementAt(1)[0]).toUpperCase();
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? CkColors.ink : CkColors.paper,
        borderRadius: BorderRadius.circular(7),
        border: on
            ? null
            : Border.all(color: CkColors.soft, width: 1.5),
      ),
      child: on
          ? const V2Svg(
              ChIcons.check,
              size: 13,
              color: CkColors.paper,
              strokeWidth: 3,
            )
          : null,
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge._({
    required this.text,
    required this.bg,
    required this.fg,
    this.border,
  });

  factory _MiniBadge.captain() =>
      const _MiniBadge._(text: 'C', bg: CkColors.ink, fg: CkColors.paper);

  factory _MiniBadge.keeper() =>
      const _MiniBadge._(text: 'WK', bg: CkColors.red, fg: CkColors.paper);

  factory _MiniBadge.guest() =>
      const _MiniBadge._(text: 'GUEST', bg: CkColors.cream, fg: CkInk.amber);

  factory _MiniBadge.unclaimed() => const _MiniBadge._(
        text: 'NEW',
        bg: CkColors.paper2,
        fg: CkColors.muted,
        border: CkColors.hairline,
      );

  final String text;
  final Color bg;
  final Color fg;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Text(
        text,
        style: CkType.mono(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: fg,
        ),
      ),
    );
  }
}
