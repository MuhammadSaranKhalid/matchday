import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../matches/domain/entities/match.dart';
import '../../domain/entities/team.dart';
import '../controllers/teams_list_controller.dart';
import '../state/teams_list_view.dart';
import '../widgets/team_avatar.dart';

/// "My teams" — the user's teams + active match requests + a create entry.
/// Pushed full-screen over the v2 shell (Pavilion → My teams). Faithful to the
/// matchday v2 design language (mono section labels, accent crest cards, mono
/// chevrons) using only real data — no fabricated records/roles/jerseys.
///
/// All cross-feature composition + filtering lives in [TeamsListController];
/// this screen is a pure renderer of [TeamsListView].
class TeamsListScreen extends ConsumerWidget {
  const TeamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(teamsListControllerProvider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(title: 'My teams'),
            Expanded(
              child: switch (view) {
                AsyncData(:final value) => RefreshIndicator(
                    color: CkColors.ink,
                    onRefresh: () => ref
                        .read(teamsListControllerProvider.notifier)
                        .refresh(),
                    child:
                        value.teams.isEmpty ? const _Empty() : _List(view: value),
                  ),
                AsyncError() =>
                  const Center(child: Text('Could not load teams')),
                _ => const Center(
                    child: CircularProgressIndicator(color: CkColors.ink)),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Paper header with a back chevron + display title (matches the v2 PvHeader).
class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.pop(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: V2Svg(V2Icons.chevronLeft,
                  size: 18, color: CkColors.ink, strokeWidth: 2),
            ),
          ),
          const SizedBox(width: 2),
          Text(title,
              style: CkType.display(fontSize: 22, letterSpacing: -0.025)),
        ],
      ),
    );
  }
}

/// Mono uppercase section label (+ optional count badge) — the PvSectionH look.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.count});
  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(label.toUpperCase(),
              style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: CkColors.muted)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
              decoration: BoxDecoration(
                color: CkColors.ink,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('$count',
                  style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: CkColors.paper)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pure renderer of the composed [TeamsListView] — no derivation, no `ref`.
class _List extends StatelessWidget {
  const _List({required this.view});
  final TeamsListView view;

  @override
  Widget build(BuildContext context) {
    final active = view.activeMatches;
    final teams = view.teams;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        if (active.isNotEmpty) ...[
          _SectionLabel('Active matches', count: active.length),
          for (var i = 0; i < active.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _RequestCard(entry: active[i]),
          ],
        ],
        _SectionLabel('Your teams', count: teams.length),
        for (var i = 0; i < teams.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _TeamCard(team: teams[i]),
        ],
        const _SectionLabel('Want another team?'),
        const _CreateTeamRow(),
      ],
    );
  }
}

/// Active match request/result card in the v2 look. Shows the resolved opponent
/// crest + name; the route/title/accent are pure single-entity UI mapping.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.entry});
  final TeamMatchEntry entry;

  @override
  Widget build(BuildContext context) {
    final match = entry.match;
    final opponent = entry.opponent;
    final live = match.status == MatchStatus.live;
    final accepted = match.status == MatchStatus.accepted;
    final completed = match.status == MatchStatus.completed;
    final route = (live || completed)
        ? '/matches/${match.id.value}/live'
        : accepted
            ? '/matches/${match.id.value}/start'
            : '/matches/${match.id.value}/request';
    final phrase = completed
        ? 'Result · scorecard'
        : live
            ? 'Watch live'
            : accepted
                ? 'Ready to start'
                : (entry.incoming ? 'Incoming request' : 'Awaiting reply');
    final accent = live
        ? CkColors.red
        : (accepted || entry.incoming)
            ? CkColors.amber
            : null;

    // Opponent name as the primary title when known; otherwise the status
    // phrase. The mono sub always carries the phrase + format.
    final title = opponent?.name ?? phrase;
    final format =
        'T${match.format.oversPerInnings} · ${match.format.playersPerTeam}-a-side'
        '${match.venue != null ? ' · ${match.venue!.ground}' : ''}';
    final sub = opponent != null ? '$phrase · $format' : format;
    final crestColor = opponent != null
        ? parseHexColor(opponent.primaryColor, fallback: CkColors.ink)
        : (accent ?? CkColors.ink);
    final crestShort = opponent != null ? teamMonogram(opponent.name) : 'VS';

    return _CardShell(
      accent: accent,
      onTap: () => context.push(route),
      child: Row(
        children: [
          Crest(short: crestShort, color: crestColor, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.01)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(sub,
                      style: CkType.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.04,
                          color: CkColors.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const V2Svg(V2Icons.chevronRight,
              size: 14, color: CkColors.muted, strokeWidth: 2),
        ],
      ),
    );
  }
}

/// A team in the v2 look — coloured crest tile, name, type · city, mono chevron.
class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(team.primaryColor, fallback: CkColors.ink);
    final type = team.type.name[0].toUpperCase() + team.type.name.substring(1);
    final sub = [
      type,
      if (team.city != null && team.city!.isNotEmpty) team.city!,
    ].join(' · ');

    return _CardShell(
      accent: color,
      onTap: () => context.push('/teams/${team.id.value}'),
      child: Row(
        children: [
          Crest(short: teamMonogram(team.name), color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(team.name,
                    style: CkType.display(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.01)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(sub,
                      style: CkType.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.04,
                          color: CkColors.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const V2Svg(V2Icons.chevronRight,
              size: 14, color: CkColors.muted, strokeWidth: 2),
        ],
      ),
    );
  }
}

/// Solid "Start a new team" entry → the 5-step create wizard.
class _CreateTeamRow extends StatelessWidget {
  const _CreateTeamRow();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: () => context.push('/teams/create'),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.ink,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const V2Svg(V2Icons.plus,
                size: 16, color: CkColors.paper, strokeWidth: 2.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Start a new team',
                    style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.01)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('5 steps · name, crest, home, roster, invite',
                      style: CkType.body(
                          fontSize: 11, height: 1.4, color: CkColors.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const V2Svg(V2Icons.chevronRight,
              size: 14, color: CkColors.muted, strokeWidth: 2),
        ],
      ),
    );
  }
}

/// Paper card with a hairline border + optional 3px coloured left accent — the
/// shared PvCard shape, tappable.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.accent, this.onTap});
  final Widget child;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // Rounded corners come from the ClipRRect, not the BoxDecoration: a
      // non-uniform Border (the 3px coloured left accent) is not allowed
      // together with a borderRadius on the decoration itself.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CkColors.paper,
            border: Border(
              top: const BorderSide(color: CkColors.hairline),
              right: const BorderSide(color: CkColors.hairline),
              bottom: const BorderSide(color: CkColors.hairline),
              left: BorderSide(
                color: accent ?? CkColors.hairline,
                width: accent != null ? 3 : 1,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 28, 2, 8),
          child: Text('No teams yet',
              style: CkType.display(fontSize: 22, letterSpacing: -0.025)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 20),
          child: Text(
            'Create a team to build a roster and line up matches.',
            style: CkType.body(fontSize: 14, color: CkColors.muted),
          ),
        ),
        const _CreateTeamRow(),
      ],
    );
  }
}
