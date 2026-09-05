import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../utils/team_share.dart';
import 'tabs/tp_about_tab.dart';
import 'tabs/tp_matches_tab.dart';
import 'tabs/tp_posts_tab.dart';
import 'tabs/tp_squad_tab.dart';
import 'tabs/tp_stats_tab.dart';
import 'tp_banners.dart';
import 'tp_hero.dart';
import 'tp_options_sheet.dart';
import 'tp_tabs_bar.dart';
import 'tp_view.dart';

/// Presentation body — manages active tab state and renders the hero,
/// banners, sticky tab bar, and the current active tab.
class TeamPageBody extends StatefulWidget {
  const TeamPageBody({
    super.key,
    required this.teamId,
    required this.view,
    this.onBack,
  });

  final String teamId;
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
    if (!widget.view.tabs.contains(_active)) {
      _active = widget.view.initialTab;
    }
  }

  Widget _bodyTab() {
    switch (_active) {
      case TeamPageTab.posts:
        return TeamPostsTab(
          teamId: widget.teamId,
          team: widget.view.team,
          viewer: widget.view.viewer,
        );
      case TeamPageTab.squad:
        return TeamSquadTab(
          teamId: widget.teamId,
          team: widget.view.team,
          viewer: widget.view.viewer,
          viewerPlayerId: widget.view.viewerPlayerId,
        );
      case TeamPageTab.matches:
        return TeamMatchesTab(team: widget.view.team);
      case TeamPageTab.stats:
        return TeamStatsTab(team: widget.view.team);
      case TeamPageTab.about:
        return TeamAboutTab(team: widget.view.team);
      case TeamPageTab.recent:
        return TeamMatchesTab(team: _withoutUpcoming(widget.view.team));
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
        TpTabItem(id: t, label: tpTabLabel(t), badge: _tabBadge(t)),
    ];
    return ColoredBox(
      color: CkColors.paper,
      child: Column(
        children: [
          TpHero(
            teamId: widget.teamId,
            team: v.team,
            viewer: v.viewer,
            badges: v.badges,
            onBack: widget.onBack,
            onShare: () => shareTeam(
              context,
              teamId: widget.teamId,
              teamName: v.team.name,
            ),
            onOptions: () => showTeamOptionsSheet(
              context,
              teamId: widget.teamId,
              team: v.team,
              viewer: v.viewer,
              viewerMembershipId: v.viewerPlayerId,
            ),
          ),
          if (v.team.live != null) TpLiveBanner(data: v.team.live!),
          if (v.banner != null)
            TpInfoBannerWidget(banner: v.banner!, teamId: widget.teamId),
          TpTabsBar(
            items: items,
            active: _active,
            onSelect: (t) => setState(() => _active = t),
          ),
          Expanded(child: _bodyTab()),
        ],
      ),
    );
  }
}
