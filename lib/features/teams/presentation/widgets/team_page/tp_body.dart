import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import 'tp_about_tab.dart';
import 'tp_banners.dart';
import 'tp_hero.dart';
import 'tp_manage_tab.dart';
import 'tp_matches_tab.dart';
import 'tp_squad_tab.dart';
import 'tp_stats_tab.dart';
import 'tp_tabs.dart';
import 'tp_view.dart';

/// The full Team Page — hero + optional live/info banner + sticky tabs +
/// active tab body. Local `_activeTab` state; everything else flows from the
/// [TeamPageView] in.
class TeamPageBody extends StatefulWidget {
  const TeamPageBody({super.key, required this.view, this.onBack});

  final TeamPageView view;
  final VoidCallback? onBack;

  @override
  State<TeamPageBody> createState() => _TeamPageBodyState();
}

class _TeamPageBodyState extends State<TeamPageBody> {
  late TeamPageTab _active;

  @override
  void initState() {
    super.initState();
    _active = widget.view.initialTab;
  }

  @override
  void didUpdateWidget(TeamPageBody old) {
    super.didUpdateWidget(old);
    // If the tab set changes underneath us (e.g. the team flips between
    // archived / active), snap back to the new initial.
    if (!widget.view.tabs.contains(_active)) {
      _active = widget.view.initialTab;
    }
  }

  Widget _body() {
    switch (_active) {
      case TeamPageTab.squad:
        return TpSquadTab(
          team: widget.view.team,
          viewer: widget.view.viewer,
          viewerPlayerId: widget.view.viewerPlayerId,
        );
      case TeamPageTab.matches:
        return TpMatchesTab(team: widget.view.team);
      case TeamPageTab.stats:
        return TpStatsTab(team: widget.view.team);
      case TeamPageTab.about:
        return TpAboutTab(team: widget.view.team);
      case TeamPageTab.manage:
        return TpManageTab(team: widget.view.team);
      case TeamPageTab.recent:
        // "Recent" archived alias — render MatchesTab against a copy of the
        // team that has no upcoming list (so only the Recent section shows).
        return TpMatchesTab(team: _withoutUpcoming(widget.view.team));
    }
  }

  TpTeam _withoutUpcoming(TpTeam t) => TpTeam(
        name: t.name,
        mono: t.mono,
        type: t.type,
        city: t.city,
        area: t.area,
        primary: t.primary,
        privacy: t.privacy,
        tagline: t.tagline,
        logoUrl: t.logoUrl,
        verified: t.verified,
        archived: t.archived,
        record: t.record,
        form: t.form,
        live: t.live,
        tournament: t.tournament,
        upcoming: const [],
        recent: t.recent,
        stats: t.stats,
        squad: t.squad,
        maxSize: t.maxSize,
        actionQueue: t.actionQueue,
        about: t.about,
        details: t.details,
        managers: t.managers,
      );

  int? _tabBadge(TeamPageTab t) {
    final v = widget.view;
    if (t == TeamPageTab.manage && v.team.actionQueue.isNotEmpty) {
      return v.team.actionQueue.length;
    }
    if (t == TeamPageTab.recent && v.team.recent.isNotEmpty) {
      return v.team.recent.length;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final items = [
      for (final t in v.tabs)
        TpTabItem(
          id: t,
          label: tpTabLabel(t),
          badge: _tabBadge(t),
        ),
    ];
    return ColoredBox(
      color: CkColors.paper,
      child: Column(
        children: [
          TpHero(
            team: v.team,
            viewer: v.viewer,
            badges: v.badges,
            onBack: widget.onBack,
          ),
          if (v.team.live != null) TpLiveBanner(data: v.team.live!),
          if (v.banner != null) TpInfoBannerWidget(banner: v.banner!),
          TpTabs(
            items: items,
            active: _active,
            onSelect: (t) => setState(() => _active = t),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }
}
