import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../state/my_teams_view.dart';
import 'create_nudge.dart';
import 'empty_state.dart';
import 'filter_chips.dart';
import 'invite_card.dart';
import 'my_teams_header.dart';
import 'needs_you_card.dart';
import 'subhead.dart';
import 'suggested_strip.dart';
import 'team_row.dart';
import 'today_card.dart';

/// The faithful Flutter port of the JSX `CkMyTeams` body. Renders a
/// [MyTeamsView] — sections only appear when their list/value is non-empty,
/// so each case yields a focused screen with no dead space.
///
/// Both the real-data screen and the case fixtures feed the same widget the
/// same shape. Affordances (filter, create, back) are passed in as optional
/// callbacks; the screen wires them to real handlers.
class MyTeamsBody extends StatelessWidget {
  const MyTeamsBody({
    super.key,
    required this.view,
    this.onBack,
    this.onSelectFilter,
    this.onCreate,
    this.onTeamTap,
  });

  final MyTeamsView view;

  /// Optional back chevron in the header (used when the screen is pushed
  /// full-screen over the shell).
  final VoidCallback? onBack;
  final ValueChanged<MyTeamsFilter>? onSelectFilter;
  final VoidCallback? onCreate;

  /// Tapping any [TeamRow] with a non-null `teamId` invokes this with the
  /// id. Screen wires it to navigate to `/teams/$id`.
  final ValueChanged<String>? onTeamTap;

  int get _totalActive {
    final t = view.teams;
    return t.captain.length +
        t.vc.length +
        t.playing.length +
        t.manage.length +
        t.scorer.length +
        t.draft.length +
        t.pending.length;
  }

  Map<MyTeamsFilter, int> get _filterCounts {
    final t = view.teams;
    return {
      MyTeamsFilter.all:
          _totalActive + view.following.length + t.archived.length,
      MyTeamsFilter.playing:
          t.vc.length + t.playing.length + t.captain.length,
      MyTeamsFilter.managing:
          t.manage.length + t.draft.length + t.scorer.length,
      MyTeamsFilter.following: view.following.length,
      MyTeamsFilter.archived: t.archived.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final counts = _filterCounts;
    final showChips =
        !view.isEmpty && (counts[MyTeamsFilter.all] ?? 0) > 1;

    return ColoredBox(
      color: CkColors.paper,
      child: Stack(
        children: [
          Column(
            children: [
              MyTeamsHeader(
                count: _totalActive,
                subtitle: view.subtitle,
                onBack: onBack,
              ),
              if (showChips)
                MyTeamsFilterChips(
                  active: view.activeFilter,
                  counts: counts,
                  onSelect: onSelectFilter,
                ),
              Expanded(
                child: _Scroll(
                  view: view,
                  onCreate: onCreate,
                  onTeamTap: onTeamTap,
                ),
              ),
            ],
          ),
          if (!view.isEmpty)
            Positioned(
              right: 14,
              bottom: 22,
              child: _CreateFab(onTap: onCreate),
            ),
        ],
      ),
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll({
    required this.view,
    required this.onCreate,
    required this.onTeamTap,
  });
  final MyTeamsView view;
  final VoidCallback? onCreate;
  final ValueChanged<String>? onTeamTap;

  VoidCallback? _tapFor(TeamRowVm vm) {
    final id = vm.teamId;
    if (id == null || onTeamTap == null) return null;
    return () => onTeamTap!(id);
  }

  @override
  Widget build(BuildContext context) {
    final t = view.teams;
    // List of factories — each only materialises its widget when the row is
    // scrolled into view. Captures the row data in a closure so we don't
    // build every TeamRow up-front.
    final builders = <WidgetBuilder>[];

    if (view.isEmpty) {
      builders.add((_) => MyTeamsEmptyState(onCreate: onCreate));
    }
    if (view.needsYou.isNotEmpty) {
      builders.add((_) => NeedsYouSection(items: view.needsYou));
    }
    if (view.today != null) {
      builders.add((_) => TodayCard(data: view.today!));
    }

    if (view.invites.isNotEmpty) {
      builders.add((_) => Subhead(
            'Invites',
            accent: CkColors.red,
            count: view.invites.length,
          ));
      builders.add((_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (var i = 0; i < view.invites.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  InviteCard(invite: view.invites[i]),
                ],
              ],
            ),
          ));
    }

    void addRows(List<TeamRowVm> rows,
        {bool withChevron = true, bool resetFirst = true}) {
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final isFirst = resetFirst && i == 0;
        builders.add((_) => TeamRow(
              vm: row,
              isFirst: isFirst,
              withChevron: withChevron,
              onTap: _tapFor(row),
            ));
      }
    }

    // ── You lead (captain + vc) ───────────────────────────────────────
    final leadCount = t.captain.length + t.vc.length;
    if (leadCount > 0) {
      builders.add((_) => Subhead('You lead', count: leadCount));
      addRows(t.captain);
      addRows(t.vc, resetFirst: t.captain.isEmpty);
    }

    // ── You play ──────────────────────────────────────────────────────
    if (t.playing.isNotEmpty) {
      builders.add((_) => Subhead('You play', count: t.playing.length));
      addRows(t.playing);
    }

    // ── You manage (manage + draft + scorer) ──────────────────────────
    final manageCount =
        t.manage.length + t.draft.length + t.scorer.length;
    if (manageCount > 0) {
      builders.add((_) => Subhead('You manage', count: manageCount));
      addRows(t.manage);
      addRows(t.draft, resetFirst: t.manage.isEmpty);
      addRows(t.scorer,
          resetFirst: t.manage.isEmpty && t.draft.isEmpty);
    }

    // ── Awaiting approval ─────────────────────────────────────────────
    if (t.pending.isNotEmpty) {
      builders.add((_) => Subhead(
            'Awaiting approval',
            accent: CkColors.amber,
            count: t.pending.length,
          ));
      addRows(t.pending);
    }

    // ── Following ─────────────────────────────────────────────────────
    if (view.following.isNotEmpty) {
      builders.add((_) => Subhead('Following', count: view.following.length));
      addRows(view.following);
    }

    // ── Archived ──────────────────────────────────────────────────────
    if (t.archived.isNotEmpty) {
      builders.add((_) => Subhead('Archived', count: t.archived.length));
      addRows(t.archived, withChevron: false);
    }

    // ── Suggested ─────────────────────────────────────────────────────
    if (view.suggested.isNotEmpty) {
      builders.add(
          (_) => Subhead(view.suggestedTitle ?? 'Near you · Karachi'));
      builders.add((_) => SuggestedStrip(items: view.suggested));
    }

    // ── "Play, don't just watch." nudge ───────────────────────────────
    if (view.showCreateNudge) {
      builders.add((_) => CreateNudgeCard(onStart: onCreate));
    }

    builders.add((_) => const SizedBox(height: 24));

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: builders.length,
      itemBuilder: (ctx, i) => builders[i](ctx),
    );
  }
}

class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: CkColors.ink,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF281E0F).withValues(alpha: 0.18),
              offset: const Offset(0, 10),
              blurRadius: 28,
            ),
            BoxShadow(
              color: const Color(0xFF281E0F).withValues(alpha: 0.10),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add, size: 22, color: CkColors.paper),
      ),
    );
  }
}
