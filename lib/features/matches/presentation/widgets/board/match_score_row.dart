import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../domain/entities/innings_summary.dart';
import '../../../domain/entities/match.dart';
import '../../providers/matches_board_providers.dart';
import '../pool/pool_challenge_card.dart';

/// One match on the board — `Matches.dc.html` artboards 01 and 08.
///
/// One geometry, seven states. Only **live**, **super over** and **abandoned**
/// carry a marker; toss and innings break say it in the state line, in words,
/// because they are moments and not badges. The state line is the row's one
/// job: it always says what is happening now.
class MatchScoreRow extends StatelessWidget {
  const MatchScoreRow({super.key, required this.item, this.onTap});

  final BoardMatch item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final m = item.match;
    final finished = m.status == MatchStatus.completed;
    final abandoned = m.status == MatchStatus.abandoned;
    final terminal = finished || abandoned;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (terminal) _terminalHead(abandoned: abandoned) else _metaHead(),
            _TeamLine(
              team: item.teamA,
              teamId: m.teamAId,
              item: item,
              dimmed: terminal && !_won(m.teamAId),
              first: true,
              terminal: terminal,
            ),
            _TeamLine(
              team: item.teamB,
              teamId: m.teamBId,
              item: item,
              dimmed: terminal && !_won(m.teamBId),
              first: false,
              terminal: terminal,
            ),
            if (!terminal)
              if (_stateLine() case final spans?) _StateStrip(spans),
          ],
        ),
      ),
    );
  }

  /// There is no winner column on `matches`, so the winner is derived from
  /// the innings totals — in limited-overs cricket the side that wins finishes
  /// with more runs, chasing or not. A tie dims neither side.
  bool _won(TeamId id) {
    if (item.innings.length < 2) return true;
    final mine = item.inningsFor(id)?.totalRuns;
    if (mine == null) return true;
    final best = item.innings
        .map((i) => i.totalRuns)
        .reduce((a, b) => a > b ? a : b);
    final tied = item.innings.where((i) => i.totalRuns == best).length > 1;
    return tied || mine == best;
  }

  /// The meta line, plus the LIVE marker when the match is on. Red is earned
  /// once on this screen and this is where it is spent.
  Widget _metaHead() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 6),
      child: Row(
        children: [
          Expanded(child: _meta(_contextLine())),
          if (item.isLive) ...[
            const SizedBox(width: 8),
            const LivePip(),
          ],
        ],
      ),
    );
  }

  /// Artboards 04 and 08: for a finished match the result is the hero, on its
  /// own strip above the scores rather than buried under them.
  Widget _terminalHead({required bool abandoned}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.match.resultDescription ??
                      (abandoned ? 'No result' : 'Match completed'),
                  style: CkType.display(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                    letterSpacing: -0.01,
                  ),
                ),
              ),
              if (abandoned) ...[
                const SizedBox(width: 8),
                const _CardPill('Abandoned'),
              ],
            ],
          ),
          const SizedBox(height: 3),
          _meta(_contextLine()),
        ],
      ),
    );
  }

  static Widget _meta(String text) => Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CkType.mono(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.07,
          color: CkColors.muted,
        ),
      );

  /// "Group A · Gaddafi B · 16 ov" — round, ground, format, whatever is set.
  String _contextLine() {
    final m = item.match;
    final overs = m.format.oversPerInnings;
    return [
      if (m.round case final r? when r.isNotEmpty) r,
      if (m.venue?.ground case final g? when g.trim().isNotEmpty) g.trim(),
      if (overs > 0) '$overs ov',
      if (m.format.playersPerTeam != 11) '${m.format.playersPerTeam}-a-side',
      if (m.status == MatchStatus.superOver) 'Super over',
    ].join(' · ');
  }

  /// The row's one job: it always says what is happening now, in words.
  ///
  /// Toss, live, innings break and super over are moments, not badges — the
  /// design gives them a sentence rather than a pill, so this is where the
  /// state of the match actually gets communicated.
  ///
  /// Returns spans, not a string, because the figures inside the sentence
  /// ("38 off 21") are set in ink against an ink-2 line.
  List<InlineSpan>? _stateLine() {
    final m = item.match;
    return switch (m.status) {
      MatchStatus.scheduled => [
          TextSpan(text: 'Starts ${_startLabel(m.scheduledStartTime)}'),
        ],
      MatchStatus.toss => [TextSpan(text: _tossLine())],
      MatchStatus.live => _liveLine(),
      MatchStatus.inningsBreak => _breakLine(),
      MatchStatus.superOver => _superOverLine(),
      _ => null,
    };
  }

  String _nameOf(TeamId? id) {
    if (id == item.match.teamAId) return item.teamA?.name ?? 'They';
    if (id == item.match.teamBId) return item.teamB?.name ?? 'They';
    return 'They';
  }

  TeamId _otherSide(TeamId id) =>
      id == item.match.teamAId ? item.match.teamBId : item.match.teamAId;

  /// Balls left in the innings, from the format rather than an assumed six.
  /// The Hundred preset bowls five to an over, so a hardcoded 6 would be
  /// wrong for a real format this app already ships.
  int _ballsLeft(InningsSummary current) {
    final f = item.match.format;
    return (f.oversPerInnings * f.ballsPerOver) - current.legalBallsFaced;
  }

  int _wicketsLeft(InningsSummary current) {
    final f = item.match.format;
    return (f.wicketsToAllOut ?? f.playersPerTeam - 1) - current.totalWickets;
  }

  /// First innings — "Riders opted to bat · Strikers yet to bat".
  /// Second — "Lions need 38 off 21 · 6 wickets left".
  List<InlineSpan> _liveLine() {
    if (item.innings.isEmpty) {
      // On, but no ball bowled yet: the toss is the only thing that has
      // happened, so say that rather than inventing a score situation.
      final toss = _tossLine();
      return [TextSpan(text: toss == 'Toss under way' ? 'Match under way' : toss)];
    }

    final current = item.innings.last;
    if (item.innings.length == 1) {
      final batting = _nameOf(current.battingTeamId);
      final waiting = _nameOf(_otherSide(current.battingTeamId));
      return [TextSpan(text: '$batting opted to bat · $waiting yet to bat')];
    }

    final first = item.innings[item.innings.length - 2];
    final need = (first.totalRuns + 1) - current.totalRuns;
    final balls = _ballsLeft(current);
    final wickets = _wicketsLeft(current);

    if (need <= 0 || balls <= 0) {
      return [TextSpan(text: '${_nameOf(current.battingTeamId)} batting')];
    }

    return [
      TextSpan(text: '${_nameOf(current.battingTeamId)} need '),
      TextSpan(text: '$need off $balls', style: _figure),
      TextSpan(text: ' · $wickets wicket${wickets == 1 ? '' : 's'} left'),
    ];
  }

  /// "Innings break · Lions chase 142 to win".
  List<InlineSpan> _breakLine() {
    if (item.innings.isEmpty) return [const TextSpan(text: 'Innings break')];
    final done = item.innings.last;
    final chasing = _nameOf(_otherSide(done.battingTeamId));
    return [
      const TextSpan(text: 'Innings break · '),
      TextSpan(text: '$chasing chase ${done.totalRuns + 1} to win'),
    ];
  }

  /// "Tied at 141 · Riders need 6 off 2". The super over's own innings sit
  /// after the two that tied, so the tie total comes from the pair before.
  List<InlineSpan>? _superOverLine() {
    if (item.innings.length < 3) return [const TextSpan(text: 'Super over')];
    final tiedAt = item.innings[item.innings.length - 3].totalRuns;
    final current = item.innings.last;

    if (item.innings.length == 3) {
      return [TextSpan(text: 'Tied at $tiedAt · super over under way')];
    }

    final first = item.innings[item.innings.length - 2];
    final need = (first.totalRuns + 1) - current.totalRuns;
    final balls = item.match.format.ballsPerOver - current.legalBallsFaced;
    if (need <= 0 || balls <= 0) {
      return [TextSpan(text: 'Tied at $tiedAt · super over')];
    }
    return [
      TextSpan(text: 'Tied at $tiedAt · ${_nameOf(current.battingTeamId)} need '),
      TextSpan(text: '$need off $balls', style: _figure),
    ];
  }

  /// The figures inside a state sentence step up to ink.
  static TextStyle get _figure => CkType.body(
        fontSize: 11.5,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: CkColors.ink,
      );

  /// "Lions won the toss and will bat".
  String _tossLine() {
    final m = item.match;
    if (m.tossWonBy == null || m.tossDecision == null) return 'Toss under way';
    final verb = m.tossDecision == TossDecision.bat ? 'bat' : 'bowl';
    return '${_nameOf(m.tossWonBy)} won the toss and will $verb';
  }

  static String _startLabel(DateTime? at) {
    if (at == null) return 'soon';
    // "Today · 4:30 PM" → "today at 4:30 PM". Only the day word lowercases;
    // lowercasing the whole label would turn the meridiem into "pm".
    final parts = poolStartLabel(at).split(' · ');
    if (parts.length != 2) return poolStartLabel(at);
    return '${parts.first.toLowerCase()} at ${parts.last}';
  }
}

/// One side of the fixture: batting dot, crest, name, score, overs.
class _TeamLine extends StatelessWidget {
  const _TeamLine({
    required this.team,
    required this.teamId,
    required this.item,
    required this.dimmed,
    required this.first,
    required this.terminal,
  });

  final Team? team;
  final TeamId teamId;
  final BoardMatch item;
  final bool dimmed;
  final bool first;

  /// A finished card has no state strip under it, so its rows carry the
  /// breathing room the strip would otherwise have provided.
  final bool terminal;

  @override
  Widget build(BuildContext context) {
    final innings = item.inningsFor(teamId);
    final batting = item.isLive && item.battingTeamId == teamId;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        13,
        first && terminal ? 8 : 4,
        13,
        first ? 4 : (terminal ? 11 : 9),
      ),
      child: Row(
        children: [
          // The batting side is marked with a small ink dot, not a colour.
          SizedBox(
            width: 5,
            height: 5,
            child: batting
                ? const DecoratedBox(
                    decoration: BoxDecoration(
                      color: CkColors.ink,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 9),
          Crest(
            short: teamMonogram(team),
            color: teamCrestColor(team),
            logoUrl: team?.logoUrl,
            size: 22,
            radius: 6,
          ),
          const SizedBox(width: 9),
          Expanded(child: _name()),
          const SizedBox(width: 8),
          Text(
            innings == null ? '—' : '${innings.totalRuns}-${innings.totalWickets}',
            style: CkType.mono(
              fontSize: 15,
              fontWeight: dimmed ? FontWeight.w600 : FontWeight.w700,
              letterSpacing: 0,
              color: innings == null
                  ? CkColors.muted
                  : (dimmed ? CkColors.ink2 : CkColors.ink),
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          SizedBox(
            width: 34,
            child: Text(
              innings == null ? '' : _oversLabel(innings),
              textAlign: TextAlign.right,
              style: CkType.mono(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                color: CkColors.muted,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }

  /// The viewer's own team wears a soft mono YOU and nothing else — no ground,
  /// no border, no card chrome. It marks the team, not the match.
  Widget _name() {
    final mine = item.viewerTeamId == teamId;
    final style = CkType.display(
      fontSize: 14.5,
      fontWeight: dimmed ? FontWeight.w500 : FontWeight.w600,
      color: dimmed ? CkColors.muted : CkColors.ink,
      letterSpacing: -0.01,
    );

    if (!mine) {
      return Text(
        team?.name ?? 'Team',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: team?.name ?? 'Team'),
          const TextSpan(text: '  '),
          TextSpan(
            text: 'YOU',
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
    );
  }
}

/// "16.4" — completed overs and the balls into the current one.
String _oversLabel(InningsSummary innings) {
  final balls = innings.legalBallsFaced;
  return '${balls ~/ 6}.${balls % 6}';
}

class _StateStrip extends StatelessWidget {
  const _StateStrip(this.spans);

  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Text.rich(
        TextSpan(
          style: CkType.body(
            fontSize: 11.5,
            height: 1.4,
            color: CkColors.ink2,
          ),
          children: spans,
        ),
      ),
    );
  }
}

/// The pulsing red dot plus LIVE in red-ink — the board's only red.
class LivePip extends StatefulWidget {
  const LivePip({super.key, this.label = 'Live', this.fontSize = 9.5});

  final String label;
  final double fontSize;

  @override
  State<LivePip> createState() => _LivePipState();
}

class _LivePipState extends State<LivePip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.25).animate(
            CurvedAnimation(parent: _c, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: CkColors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          widget.label.toUpperCase(),
          style: CkType.mono(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.09,
            color: CkColors.redInk,
          ),
        ),
      ],
    );
  }
}

class _CardPill extends StatelessWidget {
  const _CardPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.07,
          color: CkColors.amberInk,
        ),
      ),
    );
  }
}
