import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'tp_atoms.dart';
import 'tp_view.dart';

/// Matches tab — Last-8 form strip + tournament gradient card + upcoming list
/// + recent list with W/L/T pill. Empty state when both lists are absent.
class TpMatchesTab extends StatelessWidget {
  const TpMatchesTab({super.key, required this.team});
  final TpTeam team;

  @override
  Widget build(BuildContext context) {
    if (team.upcoming.isEmpty && team.recent.isEmpty) {
      return const TpEmptyTile(
        icon: Icons.calendar_month,
        title: 'No matches yet',
        body: 'Schedule a friendly or register for a tournament.',
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 14),
      children: [
        if (team.form.isNotEmpty) _FormStrip(form: team.form),
        if (team.tournament != null)
          _TournamentCard(
              tournament: team.tournament!, primary: team.primary),
        if (team.upcoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              'UPCOMING · ${team.upcoming.length}',
              style: tpMono(),
            ),
          ),
          for (final m in team.upcoming) _UpcomingRow(match: m),
        ],
        if (team.recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Text(
              'RECENT · ${team.recent.length}',
              style: tpMono(),
            ),
          ),
          for (final m in team.recent) _RecentRow(match: m),
        ],
      ],
    );
  }
}

class _FormStrip extends StatelessWidget {
  const _FormStrip({required this.form});
  final List<TpFormResult> form;

  Color _bg(TpFormResult r) {
    switch (r) {
      case TpFormResult.w:
        return CkColors.green;
      case TpFormResult.l:
        return CkColors.red;
      case TpFormResult.t:
        return CkColors.cream;
    }
  }

  Color _fg(TpFormResult r) =>
      r == TpFormResult.t ? CkColors.ink2 : Colors.white;

  String _label(TpFormResult r) {
    switch (r) {
      case TpFormResult.w:
        return 'W';
      case TpFormResult.l:
        return 'L';
      case TpFormResult.t:
        return 'T';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('LAST 8', style: tpMono()),
          ),
          Row(
            children: [
              for (var i = 0; i < form.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _bg(form[i]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _label(form[i]),
                    style: CkType.display(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _fg(form[i]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.tournament, required this.primary});
  final TpTournament tournament;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('IN TOURNAMENT', style: tpMono()),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, const Color(0xFF26201A)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.kind.toUpperCase(),
                  style: tpMono(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tournament.name,
                  style: CkType.display(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'STAGE · ${tournament.stage.toUpperCase()}',
                        style: tpMono(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${tournament.played}/${tournament.total} played',
                      style: CkType.body(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Text('·',
                        style: CkType.body(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        )),
                    Text(
                      tournament.next,
                      style: CkType.body(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.match});
  final TpUpcomingMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(match.dateDay.toUpperCase(), style: tpMono(fontSize: 9)),
                const SizedBox(height: 2),
                Text(
                  match.dateTime,
                  style: CkType.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${match.vs}',
                  style: CkType.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.round} · ${match.venue}',
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
          if (match.live)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CkColors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TpLivePulse(),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: tpMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.match});
  final TpRecentMatch match;

  Color get _bg {
    switch (match.result) {
      case TpFormResult.w:
        return CkColors.green;
      case TpFormResult.l:
        return CkColors.red;
      case TpFormResult.t:
        return CkColors.cream;
    }
  }

  Color get _fg =>
      match.result == TpFormResult.t ? CkColors.ink2 : Colors.white;

  String get _letter {
    switch (match.result) {
      case TpFormResult.w:
        return 'W';
      case TpFormResult.l:
        return 'L';
      case TpFormResult.t:
        return 'T';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              _letter,
              style: CkType.display(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _fg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      match.us,
                      style: tpMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CkColors.ink,
                      ).copyWith(letterSpacing: 0),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'vs',
                      style: CkType.body(
                          fontSize: 11, color: CkColors.muted),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        match.them,
                        overflow: TextOverflow.ellipsis,
                        style: tpMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink2,
                        ).copyWith(letterSpacing: 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.date} · ${match.summary}',
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
