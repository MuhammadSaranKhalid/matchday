import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';

/// How the order is decided.
enum SeedingMethod {
  manual('Manual'),
  random('Random'),
  pastForm('Past form');

  const SeedingMethod(this.label);
  final String label;
}

/// Console tab 2 — artboards 25 (knockout) and 25b (round robin / league).
///
/// The two differ in more than a label. In knockout, order **is** the draw:
/// seed 1 meets seed 8. In round robin and league the pairings are fixed by
/// the format — everyone plays everyone — so order only decides which fixture
/// lands in which round. The section is titled "Match order" there, not
/// "Seeding".
class TournamentSeedingTab extends StatefulWidget {
  const TournamentSeedingTab({
    super.key,
    required this.tournament,
    required this.approved,
    required this.groundNames,
    required this.onLock,
  });

  final Tournament tournament;
  final List<TournamentRegistration> approved;

  /// G1/G2 labels come from the tournament's ground list, in order.
  final List<String> groundNames;

  /// Receives the ordered registrations when the organiser locks the draw.
  /// Null while a write is already in flight.
  final void Function(List<TournamentRegistration> ordered)? onLock;

  @override
  State<TournamentSeedingTab> createState() => _TournamentSeedingTabState();
}

class _TournamentSeedingTabState extends State<TournamentSeedingTab> {
  late List<TournamentRegistration> _ordered = _initialOrder();
  SeedingMethod _method = SeedingMethod.manual;

  /// The daily slots the generated preview spreads fixtures across.
  static const _slots = ['09:00', '13:30', '18:00'];

  bool get _isKnockout =>
      widget.tournament.type == TournamentType.knockout ||
      widget.tournament.type == TournamentType.doubleElimination;

  /// Past form needs completed tournaments to rank on. With too few, a
  /// form-based order would be mostly guesswork — so it is withheld with the
  /// reason stated rather than silently disabled.
  int get _teamsWithForm => 0;

  bool get _formAvailable => _teamsWithForm * 2 >= _ordered.length;

  List<TournamentRegistration> _initialOrder() {
    final list = [...widget.approved];
    list.sort((a, b) {
      final sa = a.seedNumber;
      final sb = b.seedNumber;
      if (sa != null && sb != null) return sa.compareTo(sb);
      if (sa != null) return -1;
      if (sb != null) return 1;
      return a.registeredAt.compareTo(b.registeredAt);
    });
    return list;
  }

  @override
  void didUpdateWidget(TournamentSeedingTab old) {
    super.didUpdateWidget(old);
    if (old.approved.length != widget.approved.length) {
      _ordered = _initialOrder();
    }
  }

  /// One line, as the canvas has it: what to do, how much is off screen, and
  /// what the order means.
  String _seedHelper() {
    // Rows past this are reachable by scrolling; naming the count stops the
    // list reading as if it were complete.
    const visible = 4;
    final hidden = _ordered.length - visible;
    final overflow = hidden > 0 ? ' · +$hidden more below' : '';

    return _isKnockout
        ? 'Drag to set seeds$overflow. Seed 1 meets seed '
            '${_ordered.length} in the first round.'
        : 'Drag to reorder$overflow. Order cannot change who plays whom — '
            'only when.';
  }

  void _shuffle() {
    setState(() {
      _ordered = [..._ordered]..shuffle(math.Random());
      _method = SeedingMethod.random;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minTeams = widget.tournament.minTeams ?? 4;

    if (_ordered.length < minTeams) {
      return _NotEnoughTeams(have: _ordered.length, need: minTeams);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        if (!_isKnockout) ...[
          _RoundRobinExplainer(teamCount: _ordered.length),
          const SizedBox(height: 16),
        ],
        Text(
          _isKnockout ? 'Seeding method' : 'Match order',
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CkColors.ink2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < SeedingMethod.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 9),
              Expanded(
                child: _MethodCard(
                  method: SeedingMethod.values[i],
                  selected: _method == SeedingMethod.values[i],
                  enabled: SeedingMethod.values[i] != SeedingMethod.pastForm ||
                      _formAvailable,
                  onTap: () {
                    if (SeedingMethod.values[i] == SeedingMethod.random) {
                      _shuffle();
                    } else {
                      setState(() => _method = SeedingMethod.values[i]);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        if (!_formAvailable) ...[
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: CkType.body(
                fontSize: 11.5,
                height: 1.5,
                color: CkColors.muted,
              ),
              children: [
                TextSpan(
                  text: 'Past form is unavailable. ',
                  style: CkType.body(
                    fontSize: 11.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink2,
                  ),
                ),
                TextSpan(
                  text: 'Only $_teamsWithForm of ${_ordered.length} teams have '
                      'played a completed tournament on matchday, so a '
                      'form-based order would be mostly guesswork.',
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 7),
        Text(
          _seedHelper(),
          style: CkType.body(fontSize: 11.5, height: 1.5, color: CkColors.muted),
        ),
        if (!_isKnockout) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: _shuffle,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Shuffle',
                  style: CkType.body(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _SeedList(
          ordered: _ordered,
          // onReorderItem hands back a newIndex already adjusted for the
          // removed row, so no off-by-one fix-up is needed here.
          onReorder: (from, to) => setState(() {
            final next = [..._ordered];
            next.insert(to, next.removeAt(from));
            _ordered = next;
            _method = SeedingMethod.manual;
          }),
        ),
        const SizedBox(height: 18),
        Text(
          _isKnockout
              ? 'GENERATED FIXTURES · PREVIEW'
              : 'ROUND 1 · GENERATED',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 8),
        _FixturePreview(
          pairings: _pairings(),
          groundNames: widget.groundNames,
          slots: _slots,
          byeTeam: _byeTeam(),
        ),
        if (!_isKnockout) ...[
          const SizedBox(height: 8),
          Text(
            'Later rounds follow the same rotation. Playoff seeds come from '
            'the final points table, not this screen.',
            style: CkType.body(
              fontSize: 11.5,
              height: 1.45,
              color: CkColors.muted,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'BULK ASSIGN · GROUND × SLOT',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 8),
        _GroundSlotMatrix(
          groundNames: widget.groundNames.isEmpty
              ? const ['G1']
              : widget.groundNames,
          slots: _slots,
          pairings: _pairings(),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: widget.onLock == null
              ? null
              : () => widget.onLock!(_ordered),
          style: ElevatedButton.styleFrom(
            backgroundColor: CkColors.ink,
            disabledBackgroundColor: CkColors.paper2,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CkRadii.md),
            ),
          ),
          child: Text(
            'Lock & Publish Fixtures',
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CkColors.paper,
            ),
          ),
        ),
      ],
    );
  }

  /// With an odd field one team cannot be paired. In knockout the top seed
  /// takes the bye and goes straight through; the flat formats sit the last
  /// team out of round one. Returning it lets the preview say so rather than
  /// quietly dropping a team.
  String? _byeTeam() {
    if (_ordered.length.isEven) return null;
    final names = _ordered.map((r) => r.teamName ?? 'Team').toList();
    return _isKnockout ? names.first : names.last;
  }

  /// Round-one pairings. Knockout pairs strongest against weakest (1 v N);
  /// round robin and league pair off the rotation's first round.
  List<(String, String, String)> _pairings() {
    final names = _ordered.map((r) => r.teamName ?? 'Team').toList();
    final out = <(String, String, String)>[];

    if (_isKnockout) {
      final label = switch (names.length) {
        <= 2 => 'F',
        <= 4 => 'SF',
        <= 8 => 'QF',
        _ => 'R1',
      };
      // The bye seed is removed before pairing, so the remaining field is even
      // and nobody is silently left out.
      final field = names.length.isOdd ? names.sublist(1) : names;
      for (var i = 0; i < field.length ~/ 2; i++) {
        out.add((
          '$label${i + 1}',
          field[i],
          field[field.length - 1 - i],
        ));
      }
    } else {
      for (var i = 0; i + 1 < names.length; i += 2) {
        out.add(('M${(i ~/ 2) + 1}', names[i], names[i + 1]));
      }
    }
    return out;
  }
}

class _RoundRobinExplainer extends StatelessWidget {
  const _RoundRobinExplainer({required this.teamCount});

  final int teamCount;

  @override
  Widget build(BuildContext context) {
    // n(n-1)/2 fixtures, played across n-1 rounds for an even field.
    final matches = teamCount * (teamCount - 1) ~/ 2;
    final rounds = teamCount.isEven ? teamCount - 1 : teamCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Every team plays every team once',
            style: CkType.display(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: CkType.body(
                fontSize: 12,
                height: 1.5,
                color: CkColors.muted,
              ),
              children: [
                TextSpan(text: '$teamCount teams · '),
                TextSpan(
                  text: '$matches matches',
                  style: CkType.body(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: CkColors.ink,
                  ),
                ),
                TextSpan(text: ' across $rounds rounds.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An icon over a label, in an equal-width card — not a pill chip.
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final SeedingMethod method;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  IconData get _icon => switch (method) {
        SeedingMethod.manual => Icons.drag_indicator,
        SeedingMethod.random => Icons.casino_outlined,
        SeedingMethod.pastForm => Icons.show_chart,
      };

  @override
  Widget build(BuildContext context) {
    final fg = !enabled
        ? CkColors.soft
        : (selected ? CkColors.ink : CkColors.ink2);

    return Material(
      color: CkColors.paper,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? CkColors.ink : CkColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 20, color: !enabled ? CkColors.soft : fg),
              const SizedBox(height: 6),
              Text(
                method.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CkType.display(
                  fontSize: 11.5,
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

class _SeedList extends StatelessWidget {
  const _SeedList({required this.ordered, required this.onReorder});

  final List<TournamentRegistration> ordered;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: ordered.length,
        onReorderItem: onReorder,
        // The lifted row sits on surface white with a shadow and a slight
        // tilt, so the row being carried reads as separate from the list.
        proxyDecorator: (child, index, animation) => AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = Curves.easeOut.transform(animation.value);
            return Transform.rotate(
              angle: 1.6 * math.pi / 180 * t,
              child: Material(
                color: CkColors.surface,
                elevation: 6 * t,
                borderRadius: BorderRadius.circular(CkRadii.sm),
                shadowColor: CkColors.ink.withValues(alpha: 0.28),
                child: child,
              ),
            );
          },
        ),
        itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
          key: ValueKey(ordered[i].registrationId),
          index: i,
          child: _SeedRow(position: i + 1, reg: ordered[i], isLast: i == ordered.length - 1),
        ),
      ),
    );
  }
}

class _SeedRow extends StatelessWidget {
  const _SeedRow({
    required this.position,
    required this.reg,
    required this.isLast,
  });

  final int position;
  final TournamentRegistration reg;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final name = reg.teamName ?? 'Team';
    final monogram = reg.teamMonogram ??
        name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.characters.first)
            .join()
            .toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, size: 15, color: CkColors.soft),
          const SizedBox(width: 10),
          SizedBox(
            width: 16,
            child: Text(
              '$position',
              style: CkType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: CkColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(color: CkColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              monogram,
              style: CkType.display(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // The canvas trails each row with a past-form record ("6W–1L").
          // Nothing computes cross-tournament form yet, so the column is left
          // out rather than filled with a placeholder — the same reason the
          // Past form seeding option is unavailable.
        ],
      ),
    );
  }
}

class _FixturePreview extends StatelessWidget {
  const _FixturePreview({
    required this.pairings,
    required this.groundNames,
    required this.slots,
    this.byeTeam,
  });

  final List<(String, String, String)> pairings;
  final List<String> groundNames;
  final List<String> slots;

  /// Named when the field is odd, so the unpaired team is visible.
  final String? byeTeam;

  @override
  Widget build(BuildContext context) {
    final grounds = groundNames.isEmpty ? const ['G1'] : groundNames;

    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (byeTeam != null) ...[
            Container(
              color: CkColors.cream,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      'BYE',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                        color: CkColors.amberDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$byeTeam goes through — odd number of teams',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: CkColors.amberDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: CkColors.hairline),
          ],
          for (var i = 0; i < pairings.length; i++) ...[
            if (i > 0) Container(height: 1, color: CkColors.hairline),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      pairings[i].$1,
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${pairings[i].$2} v ${pairings[i].$3}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: CkColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    // Spread across grounds first, then slots.
                    'G${(i % grounds.length) + 1} · '
                    '${slots[(i ~/ grounds.length) % slots.length]}',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.06,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bulk assignment is a grounds × slots matrix, not per-match pickers.
class _GroundSlotMatrix extends StatelessWidget {
  const _GroundSlotMatrix({
    required this.groundNames,
    required this.slots,
    required this.pairings,
  });

  final List<String> groundNames;
  final List<String> slots;
  final List<(String, String, String)> pairings;

  @override
  Widget build(BuildContext context) {
    // Same spread the preview uses, inverted into cells.
    String? codeAt(int groundIndex, int slotIndex) {
      final i = slotIndex * groundNames.length + groundIndex;
      return i < pairings.length ? pairings[i].$1 : null;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(CkRadii.md),
          border: Border.all(color: CkColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 46),
                for (final slot in slots)
                  Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    child: Text(
                      slot,
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.06,
                      ),
                    ),
                  ),
              ],
            ),
            Container(height: 1, color: CkColors.hairline),
            for (var g = 0; g < groundNames.length; g++) ...[
              if (g > 0) Container(height: 1, color: CkColors.hairline),
              Row(
                children: [
                  Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      'G${g + 1}',
                      style: CkType.mono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                        color: CkColors.ink,
                      ),
                    ),
                  ),
                  for (var s = 0; s < slots.length; s++)
                    Container(
                      width: 78,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: CkColors.hairline),
                        ),
                      ),
                      child: Text(
                        codeAt(g, s) ?? '—',
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: codeAt(g, s) == null
                              ? CkColors.soft
                              : CkColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotEnoughTeams extends StatelessWidget {
  const _NotEnoughTeams({required this.have, required this.need});

  final int have;
  final int need;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fixtures unlock at $need teams',
              style: CkType.display(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '$have approved so far. Approve more teams on the Registrations '
              'tab and the draw becomes available here.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 12.5,
                height: 1.5,
                color: CkColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
