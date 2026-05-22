import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/ball.dart';
import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';
import '../providers/matches_providers.dart';
import '../widgets/ball_pill.dart';

/// Read-only spectator view of a match (LiveMatch.jsx): Live tab + Scorecard
/// tab. Stats/Squads tabs need fuller data and are deferred.
class LiveMatchScreen extends ConsumerStatefulWidget {
  const LiveMatchScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

enum _Tab { live, scorecard }

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  _Tab? _picked;

  @override
  Widget build(BuildContext context) {
    final matchId = widget.matchId;
    final matchAsync = ref.watch(matchProvider(matchId));
    final inningsSeed = ref.watch(currentInningsProvider(matchId));

    final match = matchAsync.value;
    final seed = inningsSeed.value;
    if (match == null || seed == null) {
      final Widget body;
      if (matchAsync.hasError || inningsSeed.hasError) {
        body = const Text('Could not load match');
      } else if (!matchAsync.isLoading && !inningsSeed.isLoading) {
        body = const Text('This match has not started yet');
      } else {
        body = const CircularProgressIndicator(color: CkColors.ink);
      }
      return Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: body),
      );
    }

    // Stream the seed innings live.
    final innings =
        ref.watch(liveInningsProvider(seed.id.value)).value ?? seed;
    final balls = ref.watch(ballsProvider(seed.id.value)).value ?? const <Ball>[];

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

    final battingName =
        ref.watch(teamProvider(innings.battingTeamId.value)).value?.name ??
            'Batting';
    final bowlingName =
        ref.watch(teamProvider(innings.bowlingTeamId.value)).value?.name ??
            'Bowling';

    final completed = match.status == MatchStatus.completed;
    final tab = _picked ?? (completed ? _Tab.scorecard : _Tab.live);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _topBar(context, match),
            _hero(match, innings, battingName, bowlingName),
            if (completed && match.resultDescription != null)
              _resultBanner(match.resultDescription!),
            _tabBar(tab),
            if (tab == _Tab.live) ...[
              _atTheCrease(innings, balls, nameOf),
              _thisOver(innings, balls, nameOf),
              _recentWickets(balls, nameOf),
            ] else
              _scorecard(innings, balls, nameOf, battingName),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _resultBanner(String text) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CkColors.greenSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 18, color: CkColors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: CkType.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink2)),
            ),
          ],
        ),
      );

  Widget _tabBar(_Tab tab) {
    Widget t(String label, _Tab id) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _picked = id),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: tab == id ? CkColors.ink : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: CkType.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tab == id ? CkColors.ink : CkColors.muted)),
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(children: [t('Live', _Tab.live), t('Scorecard', _Tab.scorecard)]),
    );
  }

  // ─── Scorecard ────────────────────────────────────────────────────────────

  Widget _scorecard(Innings inn, List<Ball> balls, String Function(String?) nameOf,
      String battingName) {
    // Batting order = first appearance as striker.
    final order = <String>[];
    for (final b in balls) {
      if (!order.contains(b.strikerId)) order.add(b.strikerId);
    }
    for (final id in [inn.currentStrikerId, inn.currentNonStrikerId]) {
      if (id != null && !order.contains(id)) order.add(id);
    }

    final wides = balls
        .where((b) => b.extraType == ExtraType.wide)
        .fold<int>(0, (a, b) => a + b.totalRuns);
    final noballs = balls
        .where((b) => b.extraType == ExtraType.noBall)
        .fold<int>(0, (a, b) => a + b.extraRuns);

    final bowlers = <String>[];
    for (final b in balls) {
      if (!bowlers.contains(b.bowlerId)) bowlers.add(b.bowlerId);
    }
    final legal = inn.totalBallsFaced;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(battingName.toUpperCase(),
                      style: CkType.mono(fontSize: 11, color: CkColors.muted)),
                  Text('${legal ~/ 6}.${legal % 6} ov',
                      style: CkType.mono(fontSize: 11, color: CkColors.muted)),
                ],
              ),
              Text('${inn.totalRuns}/${inn.totalWickets}',
                  style: CkType.display(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 10),
          _battingTable(order, balls, inn, nameOf),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('EXTRAS   wd $wides · nb $noballs',
                style: CkType.mono(fontSize: 10, color: CkColors.muted)),
          ),
          Text('BOWLING', style: CkType.mono(fontSize: 11, color: CkColors.muted)),
          const SizedBox(height: 8),
          _bowlingTable(bowlers, balls, nameOf),
        ],
      ),
    );
  }

  Widget _battingTable(List<String> order, List<Ball> balls, Innings inn,
      String Function(String?) nameOf) {
    Widget header() => Container(
          color: CkColors.paper2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Expanded(child: Text('BATTER', style: _hStyle())),
            _num('R'), _num('B'), _num('4s'), _num('6s'),
          ]),
        );
    return Container(
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          header(),
          for (var i = 0; i < order.length; i++)
            _batRow(order[i], balls, inn, nameOf, top: i == 0),
        ],
      ),
    );
  }

  Widget _batRow(String id, List<Ball> balls, Innings inn,
      String Function(String?) nameOf,
      {required bool top}) {
    final faced =
        balls.where((b) => b.strikerId == id && b.extraType != ExtraType.wide);
    final runs = faced.fold<int>(0, (a, b) => a + b.runsScored);
    final bf = faced.length;
    final fours = faced.where((b) => b.isFour).length;
    final sixes = faced.where((b) => b.isSix).length;
    final wicket = balls.where((b) => b.isWicket && b.dismissedPlayerId == id);
    final atCrease =
        id == inn.currentStrikerId || id == inn.currentNonStrikerId;
    final out = wicket.isNotEmpty
        ? _dismissal(wicket.first, nameOf)
        : (atCrease ? 'batting' : 'not out');

    return Container(
      decoration: BoxDecoration(
        border: top ? null : const Border(top: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(nameOf(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  if (out == 'batting')
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('•BAT',
                          style: CkType.mono(fontSize: 9, color: CkColors.red)),
                    ),
                ]),
                Text(out,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(
                        fontSize: 11,
                        color: (out == 'batting' || out == 'not out')
                            ? CkColors.muted
                            : CkColors.green)),
              ],
            ),
          ),
          _numVal('$runs', strong: true),
          _numVal('$bf'),
          _numVal('$fours'),
          _numVal('$sixes'),
        ],
      ),
    );
  }

  Widget _bowlingTable(
      List<String> bowlers, List<Ball> balls, String Function(String?) nameOf) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: CkColors.paper2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Expanded(child: Text('BOWLER', style: _hStyle())),
              _num('O'), _num('R'), _num('W'), _num('ER'),
            ]),
          ),
          for (var i = 0; i < bowlers.length; i++)
            _bowlRow(bowlers[i], balls, nameOf, top: i == 0),
        ],
      ),
    );
  }

  Widget _bowlRow(String id, List<Ball> balls, String Function(String?) nameOf,
      {required bool top}) {
    final bowled = balls.where((b) => b.bowlerId == id);
    final conceded = bowled.fold<int>(0, (a, b) => a + b.totalRuns);
    final wkts = bowled
        .where((b) => b.isWicket && b.wicketType != WicketType.runOut)
        .length;
    final legal = bowled.where((b) => b.isLegal).length;
    final er =
        legal > 0 ? (conceded / (legal / 6)).toStringAsFixed(1) : '—';
    return Container(
      decoration: BoxDecoration(
        border: top ? null : const Border(top: BorderSide(color: CkColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Expanded(
          child: Text(nameOf(id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        _numVal('${legal ~/ 6}.${legal % 6}'),
        _numVal('$conceded'),
        _numVal('$wkts', strong: true),
        _numVal(er),
      ]),
    );
  }

  String _dismissal(Ball w, String Function(String?) nameOf) {
    final bowler = nameOf(w.bowlerId);
    return switch (w.wicketType) {
      WicketType.bowled => 'b $bowler',
      WicketType.lbw => 'lbw b $bowler',
      WicketType.caught => 'c & b $bowler',
      WicketType.stumped => 'st b $bowler',
      WicketType.hitWicket => 'hit wkt b $bowler',
      WicketType.runOut => 'run out',
      null => 'out',
    };
  }

  TextStyle _hStyle() => CkType.mono(fontSize: 9, color: CkColors.muted);
  Widget _num(String s) =>
      SizedBox(width: 30, child: Text(s, textAlign: TextAlign.right, style: _hStyle()));
  Widget _numVal(String s, {bool strong = false}) => SizedBox(
        width: 30,
        child: Text(s,
            textAlign: TextAlign.right,
            style: strong
                ? CkType.display(fontSize: 15)
                : CkType.mono(fontSize: 12, color: CkColors.muted)),
      );

  Widget _topBar(BuildContext context, Match match) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: CkColors.redSoft,
                borderRadius: BorderRadius.circular(999)),
            child: Text('LIVE',
                style: CkType.mono(fontSize: 9, color: CkColors.red)),
          ),
          const SizedBox(width: 8),
          Text('Friendly · T${match.format.oversPerInnings}',
              style: CkType.body(fontSize: 12, color: CkColors.muted)),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _hero(Match match, Innings inn, String battingName, String bowlingName) {
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('T$maxOvers · INNINGS ${inn.inningsNumber}',
                  style: CkType.mono(
                      fontSize: 10,
                      color: CkColors.paper.withValues(alpha: 0.55))),
              if (match.venue != null)
                Flexible(
                  child: Text(match.venue!.ground,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.body(
                          fontSize: 11,
                          color: CkColors.paper.withValues(alpha: 0.55))),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(battingName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.body(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: CkColors.paper)),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: CkColors.paper.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('BAT',
                            style: CkType.mono(
                                fontSize: 9, color: CkColors.paper)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text('$overs ov · CRR $crr',
                        style: CkType.body(
                            fontSize: 12,
                            color: CkColors.paper.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: '${inn.totalRuns}',
                    style: CkType.display(fontSize: 38, color: CkColors.paper)),
                TextSpan(
                    text: '/${inn.totalWickets}',
                    style: CkType.display(
                        fontSize: 22,
                        color: CkColors.paper.withValues(alpha: 0.6))),
              ])),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: CkColors.paper.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _need('NEED', '$need', CkColors.paper)),
                  Expanded(child: _need('FROM', '${ballsLeft}b', CkColors.paper)),
                  Expanded(child: _need('RRR', rrr, CkColors.amber)),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('$bowlingName to bowl second',
                  style: CkType.body(
                      fontSize: 11,
                      color: CkColors.paper.withValues(alpha: 0.5))),
            ),
        ],
      ),
    );
  }

  Widget _need(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: CkType.mono(
                  fontSize: 9, color: CkColors.paper.withValues(alpha: 0.5))),
          const SizedBox(height: 2),
          Text(value, style: CkType.display(fontSize: 20, color: color)),
        ],
      );

  Widget _atTheCrease(Innings inn, List<Ball> balls, String Function(String?) nameOf) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('AT THE CREASE',
                style: CkType.mono(fontSize: 11, color: CkColors.muted)),
          ),
          Container(
            decoration: BoxDecoration(
              color: CkColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              children: [
                _batterRow(inn.currentStrikerId, balls, nameOf, onStrike: true),
                const Divider(height: 1, color: CkColors.hairline),
                _batterRow(inn.currentNonStrikerId, balls, nameOf,
                    onStrike: false),
                const Divider(height: 1, color: CkColors.hairline),
                _bowlerRow(inn.currentBowlerId, balls, nameOf),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _batterRow(String? id, List<Ball> balls, String Function(String?) nameOf,
      {required bool onStrike}) {
    final faced =
        balls.where((b) => b.strikerId == id && b.extraType != ExtraType.wide);
    final runs = faced.fold<int>(0, (a, b) => a + b.runsScored);
    final bf = faced.length;
    final fours = faced.where((b) => b.isFour).length;
    final sixes = faced.where((b) => b.isSix).length;
    final sr = bf > 0 ? (runs / bf * 100).toStringAsFixed(1) : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _avatar(nameOf(id), CkColors.cream, CkColors.ink2),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(nameOf(id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  if (onStrike)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: CkColors.red, shape: BoxShape.circle),
                    ),
                ]),
                Text('$fours fours · $sixes sixes',
                    style: CkType.body(fontSize: 11, color: CkColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: '$runs', style: CkType.display(fontSize: 20)),
                TextSpan(
                    text: '($bf)',
                    style: CkType.mono(fontSize: 12, color: CkColors.muted)),
              ])),
              Text('SR $sr',
                  style: CkType.mono(fontSize: 10, color: CkColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bowlerRow(String? id, List<Ball> balls, String Function(String?) nameOf) {
    final bowled = balls.where((b) => b.bowlerId == id);
    final conceded = bowled.fold<int>(0, (a, b) => a + b.totalRuns);
    final wkts = bowled
        .where((b) => b.isWicket && b.wicketType != WicketType.runOut)
        .length;
    final legalByBowler = bowled.where((b) => b.isLegal).length;
    final er = legalByBowler > 0
        ? (conceded / (legalByBowler / 6)).toStringAsFixed(1)
        : '—';

    return Container(
      color: CkColors.paper2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _avatar(nameOf(id), CkColors.green, Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: nameOf(id),
                  style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600)),
              TextSpan(
                  text: '  · Bowling',
                  style: CkType.body(fontSize: 11, color: CkColors.muted)),
            ])),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: '$wkts', style: CkType.display(fontSize: 16)),
                TextSpan(
                    text: '/$conceded',
                    style: CkType.mono(fontSize: 12, color: CkColors.muted)),
              ])),
              Text('${legalByBowler ~/ 6}.${legalByBowler % 6} ov · ER $er',
                  style: CkType.mono(fontSize: 10, color: CkColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thisOver(Innings inn, List<Ball> balls, String Function(String?) nameOf) {
    final over = inn.totalBallsFaced ~/ 6;
    final thisOver = balls.where((b) => b.overNumber == over).toList();
    final runs = thisOver.fold<int>(0, (a, b) => a + b.totalRuns);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('OVER ${over + 1} · ${nameOf(inn.currentBowlerId)}',
                    style: CkType.mono(fontSize: 11, color: CkColors.muted)),
                Text('${thisOver.length} balls · $runs runs',
                    style: CkType.mono(fontSize: 11, color: CkColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CkColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CkColors.hairline),
            ),
            child: thisOver.isEmpty
                ? Text('New over',
                    style: CkType.body(fontSize: 13, color: CkColors.muted))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final b in thisOver) BallPill.fromBall(b, size: 26),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _recentWickets(List<Ball> balls, String Function(String?) nameOf) {
    final wickets = balls.where((b) => b.isWicket).toList().reversed.take(3);
    if (wickets.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('RECENT WICKETS',
                style: CkType.mono(fontSize: 11, color: CkColors.muted)),
          ),
          for (final w in wickets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  BallPill.fromBall(w, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${nameOf(w.dismissedPlayerId)} · ${w.wicketType?.name ?? 'out'}',
                      style: CkType.body(fontSize: 13, color: CkColors.ink2),
                    ),
                  ),
                  Text('${w.overNumber}.${w.ballNumber}',
                      style: CkType.mono(fontSize: 10, color: CkColors.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatar(String name, Color bg, Color fg) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0])
            .join()
            .toUpperCase();
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
      child: Text(initials, style: CkType.mono(fontSize: 11, color: fg)),
    );
  }
}
