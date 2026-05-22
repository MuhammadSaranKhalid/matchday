import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';
import '../../domain/usecases/complete_match.dart';
import '../../domain/usecases/record_ball.dart';
import '../providers/matches_providers.dart';
import '../widgets/ball_pill.dart';

/// Live ball-by-ball scorer (Scoring.jsx). One-handed, fast taps; every tap
/// records a delivery through the engine. Undo is deferred (the additive DB
/// trigger can't be rolled back cleanly yet) — flagged for a follow-up.
class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({super.key, required this.matchId, required this.inningsId});
  final String matchId;
  final String inningsId;

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

enum _Drawer { none, wide, noBall, wicket, bowler }

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  _Drawer _drawer = _Drawer.none;
  bool _busy = false;

  // Pending delivery awaiting an over-end bowler choice.
  BallInput? _pending;
  int _pendingDeliveries = 0;

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchProvider(widget.matchId));
    final inningsAsync = ref.watch(liveInningsProvider(widget.inningsId));
    final ballsAsync = ref.watch(ballsProvider(widget.inningsId));

    final match = matchAsync.value;
    final innings = inningsAsync.value;
    if (match == null || innings == null) {
      return const Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: CircularProgressIndicator(color: CkColors.ink)),
      );
    }
    final balls = ballsAsync.value ?? const <Ball>[];

    final names = <String, String>{
      for (final RosterMember m
          in ref.watch(rosterProvider(innings.battingTeamId.value)).value ??
              const [])
        m.member.playerId: m.displayName,
      for (final RosterMember m
          in ref.watch(rosterProvider(innings.bowlingTeamId.value)).value ??
              const [])
        m.member.playerId: m.displayName,
    };
    String nameOf(String? id) => id == null ? '—' : (names[id] ?? 'Player');

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(match),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _scoreboard(match, innings),
                  const SizedBox(height: 10),
                  _players(innings, balls, nameOf),
                  const SizedBox(height: 10),
                  _lastBall(balls),
                  if (_drawer == _Drawer.wide || _drawer == _Drawer.noBall)
                    _extraDrawer(),
                  if (_drawer == _Drawer.wicket) _wicketDrawer(),
                  if (_drawer == _Drawer.bowler)
                    _bowlerDrawer(match, innings, names),
                  _runPad(),
                  _extrasRow(),
                  _ballLog(balls, nameOf),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top bar + scoreboard ────────────────────────────────────────────────

  Widget _topBar(Match match) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/match'),
            icon: const Icon(Icons.close_rounded, color: CkColors.ink),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: CkColors.redSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('SCORING',
                style: CkType.mono(fontSize: 9, color: CkColors.red)),
          ),
          const SizedBox(width: 8),
          Text('T${match.format.oversPerInnings}',
              style: CkType.mono(fontSize: 11, color: CkColors.muted)),
          const Spacer(),
          TextButton(
            onPressed: () => _finish(match),
            child: Text('Finish',
                style: CkType.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CkColors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _finish(Match match) async {
    final inn = ref.read(liveInningsProvider(widget.inningsId)).value;
    if (inn == null) return;
    final battingName =
        ref.read(teamProvider(inn.battingTeamId.value)).value?.name ?? 'Team';
    final overs = '${inn.totalBallsFaced ~/ 6}.${inn.totalBallsFaced % 6}';
    final desc =
        '$battingName ${inn.totalRuns}/${inn.totalWickets} ($overs ov)';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CkColors.paper,
        title: Text('Finish match?', style: CkType.display(fontSize: 18)),
        content: Text('Result: $desc',
            style: CkType.body(fontSize: 14, color: CkColors.ink2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Finish')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final result = await ref.read(completeMatchUseCaseProvider).call(
          CompleteMatchParams(id: match.id, description: desc),
        );
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) => context.go('/matches/${match.id.value}/live'),
    );
  }

  Widget _scoreboard(Match match, Innings inn) {
    final legal = inn.totalBallsFaced;
    final overs = '${legal ~/ 6}.${legal % 6}';
    final maxOvers = match.format.oversPerInnings;
    final crr = legal > 0 ? (inn.totalRuns / (legal / 6)).toStringAsFixed(2) : '—';
    final hasTarget = inn.target != null;
    final need = hasTarget ? (inn.target! - inn.totalRuns).clamp(0, 99999) : 0;
    final ballsLeft = maxOvers * 6 - legal;
    final rrr = hasTarget && ballsLeft > 0
        ? (need / (ballsLeft / 6)).toStringAsFixed(2)
        : '—';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: '${inn.totalRuns}',
                      style: CkType.display(fontSize: 38, color: CkColors.paper)),
                  TextSpan(
                      text: '/${inn.totalWickets}',
                      style: CkType.display(
                          fontSize: 38,
                          color: CkColors.paper.withValues(alpha: 0.55))),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(child: _miniStat('OVERS', overs, '/$maxOvers')),
              if (hasTarget)
                _miniStat('NEED', '$need', ' off $ballsLeft', right: true),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Divider(
                height: 1, color: CkColors.paper.withValues(alpha: 0.1)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _rate('CRR', crr, CkColors.paper),
              if (hasTarget) _rate('RRR', rrr, CkColors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, String suffix,
      {bool right = false}) {
    return Column(
      crossAxisAlignment:
          right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: CkType.mono(
                fontSize: 9, color: CkColors.paper.withValues(alpha: 0.55))),
        Text.rich(TextSpan(children: [
          TextSpan(
              text: value,
              style: CkType.display(fontSize: 18, color: CkColors.paper)),
          TextSpan(
              text: suffix,
              style: CkType.body(
                  fontSize: 11,
                  color: CkColors.paper.withValues(alpha: 0.5))),
        ])),
      ],
    );
  }

  Widget _rate(String label, String value, Color valueColor) {
    return Text.rich(TextSpan(children: [
      TextSpan(
          text: '$label ',
          style: CkType.mono(
              fontSize: 11, color: CkColors.paper.withValues(alpha: 0.55))),
      TextSpan(
          text: value,
          style: CkType.mono(
              fontSize: 11, fontWeight: FontWeight.w700, color: valueColor)),
    ]));
  }

  // ─── Players ─────────────────────────────────────────────────────────────

  Widget _players(Innings inn, List<Ball> balls, String Function(String?) nameOf) {
    final over = inn.totalBallsFaced ~/ 6;
    final thisOver = balls.where((b) => b.overNumber == over).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _batter(inn.currentStrikerId, balls, nameOf,
                      onStrike: true)),
              const SizedBox(width: 6),
              Expanded(
                  child: _batter(inn.currentNonStrikerId, balls, nameOf,
                      onStrike: false)),
            ],
          ),
          const SizedBox(height: 6),
          _bowlerCard(inn.currentBowlerId, balls, thisOver, nameOf),
        ],
      ),
    );
  }

  Widget _batter(String? id, List<Ball> balls, String Function(String?) nameOf,
      {required bool onStrike}) {
    final faced =
        balls.where((b) => b.strikerId == id && b.extraType != ExtraType.wide);
    final runs = faced.fold<int>(0, (a, b) => a + b.runsScored);
    final ballsFaced = faced.length;
    final fours = faced.where((b) => b.isFour).length;
    final sixes = faced.where((b) => b.isSix).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: onStrike ? CkColors.surface : CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onStrike ? CkColors.ink : CkColors.hairline,
          width: onStrike ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(nameOf(id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onStrike ? CkColors.ink : CkColors.ink2)),
              ),
              if (onStrike)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: CkColors.red, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$runs', style: CkType.display(fontSize: 22)),
              const SizedBox(width: 4),
              Text('($ballsFaced)',
                  style: CkType.mono(fontSize: 11, color: CkColors.muted)),
              const Spacer(),
              Text('$fours×4 $sixes×6',
                  style: CkType.mono(fontSize: 10, color: CkColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bowlerCard(String? id, List<Ball> balls, List<Ball> thisOver,
      String Function(String?) nameOf) {
    final bowled = balls.where((b) => b.bowlerId == id);
    final conceded = bowled.fold<int>(0, (a, b) => a + b.totalRuns);
    final wkts = bowled
        .where((b) => b.isWicket && b.wicketType != WicketType.runOut)
        .length;
    final legalByBowler = bowled.where((b) => b.isLegal).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: CkColors.green, borderRadius: BorderRadius.circular(8)),
            child: Text('BWL',
                style: CkType.mono(fontSize: 8, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nameOf(id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  '${legalByBowler ~/ 6}.${legalByBowler % 6} ov · ${conceded}r · ${wkts}w',
                  style: CkType.mono(fontSize: 10, color: CkColors.muted),
                ),
              ],
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                i < thisOver.length
                    ? BallPill.fromBall(thisOver[i], size: 22)
                    : Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: CkColors.line,
                              width: 1.5,
                              style: BorderStyle.solid),
                        ),
                      ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _lastBall(List<Ball> balls) {
    final last = balls.isNotEmpty ? balls.last : null;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Row(
        children: [
          if (last != null)
            BallPill.fromBall(last, size: 28)
          else
            const SizedBox(width: 28, height: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    last == null
                        ? 'NO BALLS YET'
                        : 'LAST · ${last.overNumber}.${last.ballNumber}',
                    style: CkType.mono(fontSize: 9, color: CkColors.muted)),
                Text(last == null ? 'Tap to score the first ball' : _describe(last),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 12, color: CkColors.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Drawers ───────────────────────────────────────────────────────────────

  Widget _extraDrawer() {
    final isWide = _drawer == _Drawer.wide;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration:
          BoxDecoration(color: CkColors.ink, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(isWide ? 'WIDE +' : 'NO-BALL +',
                style: CkType.mono(fontSize: 10, color: CkColors.paper)),
          ),
          for (var r = 1; r <= 5; r++) ...[
            if (r > 1) const SizedBox(width: 6),
            Expanded(
              child: _drawerBtn('$r', () {
                if (isWide) {
                  _submit(extraType: ExtraType.wide, extraRuns: r - 1);
                } else {
                  _submit(extraType: ExtraType.noBall, runsOffBat: r - 1);
                }
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _wicketDrawer() {
    const kinds = {
      'Bowled': WicketType.bowled,
      'Caught': WicketType.caught,
      'LBW': WicketType.lbw,
      'Run out': WicketType.runOut,
      'Stumped': WicketType.stumped,
      'Hit wkt': WicketType.hitWicket,
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: CkColors.red, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('WICKET — HOW OUT?',
                style: CkType.mono(fontSize: 10, color: Colors.white)),
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            children: [
              for (final e in kinds.entries)
                _drawerBtn(e.key, () => _submit(isWicket: true, wicketType: e.value),
                    translucent: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bowlerDrawer(Match match, Innings inn, Map<String, String> names) {
    final bowlingSquad =
        inn.bowlingTeamId == match.teamAId ? match.teamASquad : match.teamBSquad;
    final candidates =
        bowlingSquad.where((id) => id != inn.currentBowlerId).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: CkColors.ink, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('OVER COMPLETE — NEXT BOWLER',
                style: CkType.mono(fontSize: 10, color: CkColors.paper)),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in candidates)
                _drawerBtn(names[id] ?? 'Player', () => _confirmBowler(id),
                    translucent: true, expand: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerBtn(String label, VoidCallback onTap,
      {bool translucent = false, bool expand = true}) {
    final btn = GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: translucent
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.body(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
    return expand ? btn : IntrinsicWidth(child: btn);
  }

  // ─── Run pad + extras ────────────────────────────────────────────────────

  Widget _runPad() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        children: [
          Row(children: [
            for (final r in [0, 1, 2, 3]) ...[
              if (r > 0) const SizedBox(width: 6),
              Expanded(child: _RunButton(r: r, onTap: () => _submit(runsOffBat: r))),
            ],
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _RunButton(r: 4, big: true, onTap: () => _submit(runsOffBat: 4))),
            const SizedBox(width: 6),
            Expanded(child: _RunButton(r: 6, big: true, onTap: () => _submit(runsOffBat: 6))),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _drawer =
                    _drawer == _Drawer.wicket ? _Drawer.none : _Drawer.wicket),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _drawer == _Drawer.wicket
                        ? CkColors.red
                        : CkColors.redSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('W',
                      style: CkType.display(
                          fontSize: 22,
                          color: _drawer == _Drawer.wicket
                              ? Colors.white
                              : CkColors.red)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _extrasRow() {
    Widget btn(String label, _Drawer d, {bool enabled = true}) => Expanded(
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: GestureDetector(
              onTap: enabled
                  ? () => setState(
                      () => _drawer = _drawer == d ? _Drawer.none : d)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _drawer == d ? CkColors.ink : CkColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(label,
                    style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _drawer == d ? CkColors.paper : CkColors.ink2)),
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(children: [
        btn('Wide', _Drawer.wide),
        const SizedBox(width: 6),
        btn('No-ball', _Drawer.noBall),
        const SizedBox(width: 6),
        btn('Bye', _Drawer.none, enabled: false),
        const SizedBox(width: 6),
        btn('Leg-bye', _Drawer.none, enabled: false),
      ]),
    );
  }

  Widget _ballLog(List<Ball> balls, String Function(String?) nameOf) {
    final recent = balls.reversed.take(8).toList();
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('BALL LOG',
                style: CkType.mono(fontSize: 11, color: CkColors.muted)),
          ),
          for (final b in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('${b.overNumber}.${b.ballNumber}',
                        style:
                            CkType.mono(fontSize: 10, color: CkColors.muted)),
                  ),
                  BallPill.fromBall(b, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_describe(b),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(fontSize: 12, color: CkColors.ink2)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Recording ─────────────────────────────────────────────────────────────

  Future<void> _submit({
    int runsOffBat = 0,
    ExtraType? extraType,
    int extraRuns = 0,
    bool isWicket = false,
    WicketType? wicketType,
  }) async {
    final inn = ref.read(liveInningsProvider(widget.inningsId)).value;
    final match = ref.read(matchProvider(widget.matchId)).value;
    final balls = ref.read(ballsProvider(widget.inningsId)).value ?? const [];
    if (inn == null || match == null) return;

    final over = inn.totalBallsFaced ~/ 6;
    final deliveriesThisOver = balls.where((b) => b.overNumber == over).length;

    String? newStriker;
    if (isWicket) {
      final battingSquad = inn.battingTeamId == match.teamAId
          ? match.teamASquad
          : match.teamBSquad;
      newStriker = _nextBatter(inn, battingSquad, balls);
    }

    final input = BallInput(
      runsOffBat: runsOffBat,
      extraType: extraType,
      extraRuns: extraRuns,
      isWicket: isWicket,
      wicketType: wicketType,
      newStrikerId: newStriker,
    );

    // Will this legal delivery complete the over? If so, prompt for the bowler.
    final legal = extraType == null;
    if (legal && inn.totalBallsFaced % 6 == 5) {
      setState(() {
        _pending = input;
        _pendingDeliveries = deliveriesThisOver;
        _drawer = _Drawer.bowler;
      });
      return;
    }

    await _record(input, inn, deliveriesThisOver);
  }

  Future<void> _confirmBowler(String bowlerId) async {
    final inn = ref.read(liveInningsProvider(widget.inningsId)).value;
    final pending = _pending;
    if (inn == null || pending == null) return;
    final input = BallInput(
      runsOffBat: pending.runsOffBat,
      extraType: pending.extraType,
      extraRuns: pending.extraRuns,
      isWicket: pending.isWicket,
      wicketType: pending.wicketType,
      newStrikerId: pending.newStrikerId,
      newBowlerId: bowlerId,
    );
    final deliveries = _pendingDeliveries;
    setState(() {
      _pending = null;
      _drawer = _Drawer.none;
    });
    await _record(input, inn, deliveries);
  }

  Future<void> _record(BallInput input, Innings inn, int deliveriesThisOver) async {
    setState(() {
      _busy = true;
      if (_drawer != _Drawer.bowler) _drawer = _Drawer.none;
    });
    final result = await ref.read(recordBallUseCaseProvider).call(
          RecordBallParams(
            innings: inn,
            input: input,
            deliveriesThisOver: deliveriesThisOver,
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {},
    );
  }

  /// Next batter in: first squad member who hasn't yet appeared at the crease.
  String? _nextBatter(Innings inn, List<String> squad, List<Ball> balls) {
    final seen = <String>{inn.currentStrikerId ?? '', inn.currentNonStrikerId ?? ''};
    for (final b in balls) {
      seen
        ..add(b.strikerId)
        ..add(b.nonStrikerId);
    }
    for (final id in squad) {
      if (!seen.contains(id)) return id;
    }
    return null;
  }

  String _describe(Ball b) {
    if (b.isWicket) return 'WICKET · ${b.wicketType?.name ?? ''}';
    if (b.extraType == ExtraType.wide) return 'Wide${b.totalRuns > 1 ? ' · ${b.totalRuns}' : ''}';
    if (b.extraType == ExtraType.noBall) {
      return 'No-ball${b.runsScored > 0 ? ' · ${b.runsScored} off bat' : ''}';
    }
    if (b.isSix) return 'SIX!';
    if (b.isFour) return 'Four!';
    if (b.runsScored == 0) return 'Dot ball';
    return '${b.runsScored} run${b.runsScored > 1 ? 's' : ''}';
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({required this.r, required this.onTap, this.big = false});
  final int r;
  final bool big;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (r) {
      4 => (CkColors.greenSoft, CkColors.green),
      6 => (CkColors.ink, CkColors.paper),
      _ => (CkColors.surface, CkColors.ink),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: big ? 56 : 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: r == 6 ? null : Border.all(color: CkColors.hairline),
        ),
        child: Text(r == 0 ? '•' : '$r',
            style: CkType.display(fontSize: big ? 24 : 22, color: fg)),
      ),
    );
  }
}
