import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/draw/draw_builder.dart';
import '../../domain/draw/draw_plan.dart';
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
    this.onGoToLiveOps,
  });

  final Tournament tournament;
  final List<TournamentRegistration> approved;

  /// G1/G2 labels come from the tournament's ground list, in order.
  final List<String> groundNames;

  /// Receives the ordered registrations *and the exact plan this tab
  /// previewed* when the organiser locks the draw. Handing the plan over
  /// rather than letting the console rebuild it is what makes "what you see
  /// is what publishes" structural instead of conventional — the two used to
  /// be separate pairing routines and had already drifted.
  final void Function(
    List<TournamentRegistration> ordered,
    DrawPlan plan,
  )? onLock;

  /// Triggered when the organiser taps "Go to Live Ops Dashboard" on the
  /// permanently locked draw screen (artboard 25d).
  final VoidCallback? onGoToLiveOps;

  @override
  State<TournamentSeedingTab> createState() => _TournamentSeedingTabState();
}

class _TournamentSeedingTabState extends State<TournamentSeedingTab> {
  late List<TournamentRegistration> _ordered = _initialOrder();
  SeedingMethod _method = SeedingMethod.manual;

  bool get _isKnockout =>
      widget.tournament.type == TournamentType.knockout ||
      widget.tournament.type == TournamentType.doubleElimination;

  bool get _isLocked =>
      widget.tournament.status != TournamentStatus.draft &&
      widget.tournament.status != TournamentStatus.registration;

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

  /// The draw exactly as it will be published. One call, one implementation;
  /// the console publishes this very object.
  DrawPlan _buildPlan() => buildDraw(
        type: widget.tournament.type,
        orderedTeamIds: _ordered.map((r) => r.teamId).toList(),
        grounds: widget.groundNames,
        startDate: widget.tournament.startDate ??
            DateTime.now().add(const Duration(days: 2)),
      );

  String _nameOf(String? teamId) {
    if (teamId == null) return 'TBD';
    return _ordered
            .where((r) => r.teamId == teamId)
            .firstOrNull
            ?.teamName ??
        'Team';
  }

  @override
  Widget build(BuildContext context) {
    final minTeams = widget.tournament.minTeams ?? 4;

    if (_ordered.length < minTeams) {
      return _NotEnoughTeams(have: _ordered.length, need: minTeams);
    }

    final plan = _buildPlan();
    if (plan.unsupported != null) {
      return _UnsupportedType(label: plan.unsupported!);
    }

    // Knockout shows the whole tree, because every one of those rows is
    // created at lock time. The flat formats show round one and state the
    // full total underneath — 15 rows of round robin is a scroll, not a
    // preview.
    final previewed =
        _isKnockout ? plan.fixtures : plan.fixturesInRound(1);

    if (_isLocked) {
      return _buildLockedDraw(plan, previewed);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        if (!_isKnockout) ...[
          _RoundRobinExplainer(
            teamCount: _ordered.length,
            matchCount: plan.fixtures.length,
            roundCount: plan.roundCount,
          ),
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
              ? 'GENERATED FIXTURES · ALL ${plan.roundCount} ROUNDS'
              : 'ROUND 1 OF ${plan.roundCount} · GENERATED',
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 8),
        _FixturePreview(
          fixtures: previewed,
          nameOf: _nameOf,
          byeTeams: plan.byes.map((b) => _nameOf(b.teamId)).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _isKnockout
              ? 'Later rounds are created now and fill in as results land.'
              : 'All ${plan.fixtures.length} fixtures across '
                  '${plan.roundCount} rounds are created at lock. Playoff '
                  'seeds come from the final points table, not this screen.',
          style: CkType.body(
            fontSize: 11.5,
            height: 1.45,
            color: CkColors.muted,
          ),
        ),
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
        _GroundSlotMatrix(fixtures: plan.fixtures),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: widget.onLock == null
              ? null
              : () => widget.onLock!(_ordered, plan),
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

  /// Artboard 25d — the draw permanently locked.
  ///
  /// After locking, seeding is no longer a thing the organiser does. Drag
  /// handles disappear rather than grey out, each seed gets a cream shield,
  /// and the primary action hands over to Live Ops.
  Widget _buildLockedDraw(DrawPlan plan, List<DrawFixture> previewed) {
    final dateFormat = DateFormat('dd MMM · HH:mm');
    final lockedAt = widget.tournament.updatedAt;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // Artboard 25d: Draw locked banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CkColors.cream,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.creamBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, size: 16, color: CkColors.amberDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DRAW LOCKED · ${_ordered.length} TEAMS SEEDED',
                      style: CkType.mono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.10,
                        color: CkColors.amberDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Seeds and bracket pairings are permanent. Match times, venues, and match officials can be managed in Live Ops.',
                      style: CkType.body(
                        fontSize: 12,
                        height: 1.55,
                        color: CkColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Section: Final seeds
        Row(
          children: [
            Expanded(
              child: Text(
                'FINAL SEEDS',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                  color: CkColors.muted,
                ),
              ),
            ),
            Text(
              'Locked ${dateFormat.format(lockedAt)}',
              style: CkType.mono(
                fontSize: 10,
                color: CkColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2-column grid of final seeds with cream shields and NO drag handles
        _FinalSeedsGrid(ordered: _ordered),
        const SizedBox(height: 18),

        // Published fixtures preview
        Row(
          children: [
            Expanded(
              child: Text(
                _isKnockout
                    ? 'QUARTER-FINALS · PUBLISHED'
                    : 'MATCHES · PUBLISHED',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                  color: CkColors.muted,
                ),
              ),
            ),
            Text(
              'Published',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06,
                color: CkColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _FixturePreview(
          fixtures: previewed,
          nameOf: _nameOf,
          byeTeams: plan.byes.map((b) => _nameOf(b.teamId)).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _isKnockout
              ? 'Semi-finals and the final populate as results come in. All managers were notified when the draw was published.'
              : 'All fixtures are published. Playoff seeds come from the final points table.',
          style: CkType.body(
            fontSize: 11,
            height: 1.45,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 24),

        // Primary Bottom Action: Go to Live Ops Dashboard
        OutlinedButton(
          onPressed: widget.onGoToLiveOps,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: CkColors.ink, width: 1.5),
            backgroundColor: CkColors.paper,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CkRadii.md),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, size: 18, color: CkColors.ink),
              const SizedBox(width: 8),
              Text(
                'Go to Live Ops Dashboard',
                style: CkType.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinalSeedsGrid extends StatelessWidget {
  const _FinalSeedsGrid({required this.ordered});

  final List<TournamentRegistration> ordered;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 6) / 2;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < ordered.length; i++)
              SizedBox(
                width: itemWidth,
                child: _FinalSeedCard(
                  position: i + 1,
                  reg: ordered[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FinalSeedCard extends StatelessWidget {
  const _FinalSeedCard({required this.position, required this.reg});

  final int position;
  final TournamentRegistration reg;

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CkColors.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          // Cream shield badge with checkmark (Artboard 25d)
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: CkColors.creamBorder),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check, size: 10, color: CkColors.amberDark),
          ),
          const SizedBox(width: 5),
          Text(
            '#$position',
            style: CkType.mono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(color: CkColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              monogram,
              style: CkType.mono(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: CkColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.display(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: CkColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundRobinExplainer extends StatelessWidget {
  const _RoundRobinExplainer({
    required this.teamCount,
    required this.matchCount,
    required this.roundCount,
  });

  final int teamCount;

  /// Straight from the plan. This block used to compute n(n-1)/2 itself and
  /// promise a number the lock never published — the console generated n/2.
  final int matchCount;
  final int roundCount;

  @override
  Widget build(BuildContext context) {
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
                  text: '$matchCount matches',
                  style: CkType.body(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: CkColors.ink,
                  ),
                ),
                TextSpan(text: ' across $roundCount rounds.'),
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
    required this.fixtures,
    required this.nameOf,
    this.byeTeams = const [],
  });

  final List<DrawFixture> fixtures;

  /// Resolves a team id to its name; unresolved sides render as "TBD".
  final String Function(String?) nameOf;

  /// Named when the field is not a power of two, so the teams that walk
  /// through are visible rather than silently absent from round one.
  final List<String> byeTeams;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm');
    final day = DateFormat('d MMM');
    var lastRound = -1;

    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final bye in byeTeams) ...[
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
                      '$bye goes straight through',
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
          for (var i = 0; i < fixtures.length; i++) ...[
            // A round header, not a divider, wherever the round changes —
            // the preview now spans the whole tree, so "which round is this"
            // has to be answerable without counting.
            if (fixtures[i].roundNumber != lastRound) ...[
              if (i > 0) Container(height: 1, color: CkColors.hairline),
              Builder(builder: (_) {
                lastRound = fixtures[i].roundNumber;
                return Container(
                  width: double.infinity,
                  color: CkColors.paper2,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  child: Text(
                    '${fixtures[i].roundLabel.toUpperCase()} · '
                    '${day.format(fixtures[i].scheduledStartTime)}',
                    style: CkType.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.muted,
                    ),
                  ),
                );
              }),
            ] else
              Container(height: 1, color: CkColors.hairline),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      fixtures[i].shortCode,
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${nameOf(fixtures[i].teamAId)} v '
                      '${nameOf(fixtures[i].teamBId)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: fixtures[i].isResolved
                            ? CkColors.ink
                            : CkColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    // The plan's own venue and time, not a re-derivation of
                    // the spread. Recomputing it here is how the preview and
                    // the published fixtures came apart before.
                    '${fixtures[i].venue} · '
                    '${time.format(fixtures[i].scheduledStartTime)}',
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
///
/// Both axes and every cell come from the plan itself. It used to re-derive
/// the spread from a fixture's index, which is a third copy of the scheduling
/// rule and drifted from the other two the moment a round overflowed a day.
class _GroundSlotMatrix extends StatelessWidget {
  const _GroundSlotMatrix({required this.fixtures});

  final List<DrawFixture> fixtures;

  @override
  Widget build(BuildContext context) {
    if (fixtures.isEmpty) return const SizedBox.shrink();

    final time = DateFormat('HH:mm');
    // The first day only — the matrix answers "what is on where today", and
    // a draw can span weeks.
    final firstDay = fixtures
        .map((f) => DateTime(f.scheduledStartTime.year,
            f.scheduledStartTime.month, f.scheduledStartTime.day))
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final onDay = fixtures.where((f) {
      final d = f.scheduledStartTime;
      return DateTime(d.year, d.month, d.day) == firstDay;
    }).toList();

    final grounds = onDay.map((f) => f.venue).toSet().toList();
    final slots = (onDay.map((f) => time.format(f.scheduledStartTime)).toSet()
          ..toList())
        .toList()
      ..sort();

    DrawFixture? at(String ground, String slot) => onDay
        .where((f) =>
            f.venue == ground && time.format(f.scheduledStartTime) == slot)
        .firstOrNull;

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
            for (var g = 0; g < grounds.length; g++) ...[
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
                  for (final slot in slots)
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
                        at(grounds[g], slot)?.shortCode ?? '—',
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: at(grounds[g], slot) == null
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

/// A tournament type the draw builder has no generator for. Saying so beats
/// publishing a bracket of the wrong shape.
class _UnsupportedType extends StatelessWidget {
  const _UnsupportedType({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label draws are not supported yet',
                style:
                    CkType.display(fontSize: 15.5, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Knockout, round robin and league can be drawn and locked '
                'today. Change the format in Edit settings to continue.',
                style: CkType.body(
                  fontSize: 12.5,
                  height: 1.5,
                  color: CkColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
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
