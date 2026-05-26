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
  });

  final MyTeamsView view;

  /// Optional back chevron in the header (used when the screen is pushed
  /// full-screen over the shell).
  final VoidCallback? onBack;
  final ValueChanged<MyTeamsFilter>? onSelectFilter;
  final VoidCallback? onCreate;

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
              Expanded(child: _Scroll(view: view, onCreate: onCreate)),
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
  const _Scroll({required this.view, required this.onCreate});
  final MyTeamsView view;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final t = view.teams;
    final children = <Widget>[];

    if (view.isEmpty) {
      children.add(MyTeamsEmptyState(onCreate: onCreate));
    }

    if (view.needsYou.isNotEmpty) {
      children.add(NeedsYouSection(items: view.needsYou));
    }

    if (view.today != null) {
      children.add(TodayCard(data: view.today!));
    }

    if (view.invites.isNotEmpty) {
      children.add(
        Subhead('Invites', accent: CkColors.red, count: view.invites.length),
      );
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (var i = 0; i < view.invites.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                InviteCard(invite: view.invites[i]),
              ],
            ],
          ),
        ),
      );
    }

    // ── You lead (captain + vc) ────────────────────────────────────────
    final leadCount = t.captain.length + t.vc.length;
    if (leadCount > 0) {
      children.add(Subhead('You lead', count: leadCount));
      var first = true;
      for (final row in t.captain) {
        children.add(TeamRow(vm: row, isFirst: first));
        first = false;
      }
      for (final row in t.vc) {
        children.add(TeamRow(vm: row, isFirst: first));
        first = false;
      }
    }

    // ── You play ──────────────────────────────────────────────────────
    if (t.playing.isNotEmpty) {
      children.add(Subhead('You play', count: t.playing.length));
      for (var i = 0; i < t.playing.length; i++) {
        children.add(TeamRow(vm: t.playing[i], isFirst: i == 0));
      }
    }

    // ── You manage (manage + draft + scorer) ───────────────────────────
    final manageCount =
        t.manage.length + t.draft.length + t.scorer.length;
    if (manageCount > 0) {
      children.add(Subhead('You manage', count: manageCount));
      var first = true;
      for (final row in t.manage) {
        children.add(TeamRow(vm: row, isFirst: first));
        first = false;
      }
      for (final row in t.draft) {
        children.add(TeamRow(vm: row, isFirst: first));
        first = false;
      }
      for (final row in t.scorer) {
        children.add(TeamRow(vm: row, isFirst: first));
        first = false;
      }
    }

    // ── Awaiting approval ─────────────────────────────────────────────
    if (t.pending.isNotEmpty) {
      children.add(
        Subhead(
          'Awaiting approval',
          accent: CkColors.amber,
          count: t.pending.length,
        ),
      );
      for (var i = 0; i < t.pending.length; i++) {
        children.add(TeamRow(vm: t.pending[i], isFirst: i == 0));
      }
    }

    // ── Following ─────────────────────────────────────────────────────
    if (view.following.isNotEmpty) {
      children.add(Subhead('Following', count: view.following.length));
      for (var i = 0; i < view.following.length; i++) {
        children.add(TeamRow(vm: view.following[i], isFirst: i == 0));
      }
    }

    // ── Archived ──────────────────────────────────────────────────────
    if (t.archived.isNotEmpty) {
      children.add(Subhead('Archived', count: t.archived.length));
      for (var i = 0; i < t.archived.length; i++) {
        children.add(
          TeamRow(vm: t.archived[i], isFirst: i == 0, withChevron: false),
        );
      }
    }

    // ── Suggested ─────────────────────────────────────────────────────
    if (view.suggested.isNotEmpty) {
      children.add(Subhead(view.suggestedTitle ?? 'Near you · Karachi'));
      children.add(SuggestedStrip(items: view.suggested));
    }

    // ── "Play, don't just watch." nudge ───────────────────────────────
    if (view.showCreateNudge) {
      children.add(CreateNudgeCard(onStart: onCreate));
    }

    children.add(const SizedBox(height: 24));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      children: children,
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
