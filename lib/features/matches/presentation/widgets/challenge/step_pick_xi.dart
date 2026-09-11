import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../teams/domain/entities/roster_member.dart';
import '../../../../teams/domain/entities/team_member.dart';
import '../pool/pool_icons.dart';

/// Pick your XI — `Pool.dc.html` artboard 09.
///
/// Ruled rows rather than cards: this is a list to run down, not a set of
/// things to consider individually. Selected players lift to the top under
/// "Selected · N", everyone else falls to the bench, so the shape of the list
/// tells you how far along you are without reading the count.
///
/// C and WK are set from the row itself. A player must be in the XI to wear
/// either, which is why the toggles only appear on selected rows.
class StepPickXi extends StatelessWidget {
  const StepPickXi({
    super.key,
    required this.roster,
    required this.selected,
    required this.captainId,
    required this.keeperId,
    required this.onToggle,
    required this.onCaptain,
    required this.onKeeper,
  });

  final List<RosterMember> roster;

  /// Player ids in selection order.
  final List<String> selected;
  final String? captainId;
  final String? keeperId;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onCaptain;
  final ValueChanged<String> onKeeper;

  @override
  Widget build(BuildContext context) {
    if (roster.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'This team has no players on its roster yet.',
            textAlign: TextAlign.center,
            style: CkType.body(fontSize: 13, color: CkColors.muted),
          ),
        ),
      );
    }

    final byId = {for (final m in roster) m.member.playerId: m};
    final picked = [
      for (final id in selected)
        if (byId[id] case final m?) m,
    ];
    final bench =
        roster.where((m) => !selected.contains(m.member.playerId)).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        _Label('Selected · ${picked.length}', top: 14),
        for (final m in picked)
          _PlayerRow(
            member: m,
            selected: true,
            isCaptain: m.member.playerId == captainId,
            isKeeper: m.member.playerId == keeperId,
            onToggle: () => onToggle(m.member.playerId),
            onCaptain: () => onCaptain(m.member.playerId),
            onKeeper: () => onKeeper(m.member.playerId),
          ),
        if (bench.isNotEmpty) ...[
          const _Label('Bench · not playing', top: 16),
          for (final m in bench)
            _PlayerRow(
              member: m,
              selected: false,
              isCaptain: false,
              isKeeper: false,
              onToggle: () => onToggle(m.member.playerId),
              onCaptain: () {},
              onKeeper: () {},
            ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.top});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, top, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: CkType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.10,
            color: CkColors.muted,
          ),
        ),
      );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.member,
    required this.selected,
    required this.isCaptain,
    required this.isKeeper,
    required this.onToggle,
    required this.onCaptain,
    required this.onKeeper,
  });

  final RosterMember member;
  final bool selected;
  final bool isCaptain;
  final bool isKeeper;
  final VoidCallback onToggle;
  final VoidCallback onCaptain;
  final VoidCallback onKeeper;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(color: CkColors.hairline),
            ),
            child: Text(
              _initials(member.displayName),
              style: CkType.display(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? CkColors.ink2 : CkColors.muted,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? CkColors.ink : CkColors.ink2,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _role(member).toUpperCase(),
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color: CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (selected) ...[
            _Marks(
              isCaptain: isCaptain,
              isKeeper: isKeeper,
              onCaptain: onCaptain,
              onKeeper: onKeeper,
            ),
            const SizedBox(width: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: const PoolIcon(PoolIcons.checkFilled, size: 22),
            ),
          ] else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: CkColors.soft, width: 1.6),
                ),
              ),
            ),
        ],
      ),
    );

    // The whole row is the hit target — these are ruled list rows to run
    // down, not cards with a control in the corner. The armband toggle sits
    // on top and swallows its own taps.
    final tappable = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: row,
    );
    return selected ? tappable : Opacity(opacity: 0.7, child: tappable);
  }

  static String _initials(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '—';
    if (words.length == 1) {
      final one = words.first;
      return (one.length >= 2 ? one.substring(0, 2) : one).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  // The team-level role. Keeping is NOT one of these any more — it is a
  // per-match choice, made by the C/WK marks on this very screen.
  static String _role(RosterMember m) => switch (m.member.topRole) {
        MemberRole.owner => 'Owner',
        MemberRole.manager => 'Manager',
        MemberRole.captain => 'Captain',
        MemberRole.player => 'Player',
      };
}

/// Either the badge the player wears, or the "C · WK" affordance to give them
/// one. Tapping cycles C → WK → neither, which keeps both marks reachable
/// from a single hit target on a crowded row.
class _Marks extends StatelessWidget {
  const _Marks({
    required this.isCaptain,
    required this.isKeeper,
    required this.onCaptain,
    required this.onKeeper,
  });

  final bool isCaptain;
  final bool isKeeper;
  final VoidCallback onCaptain;
  final VoidCallback onKeeper;

  @override
  Widget build(BuildContext context) {
    if (isCaptain || isKeeper) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isCaptain ? onKeeper : onCaptain,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isCaptain ? 'C' : 'WK',
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04,
              color: CkColors.paper,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onCaptain,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CkColors.line),
        ),
        child: Text(
          'C · WK',
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.04,
            color: CkColors.muted,
          ),
        ),
      ),
    );
  }
}
