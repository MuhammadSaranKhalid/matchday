import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../matches/domain/entities/match.dart';
import '../../../domain/entities/team_member.dart';
import '../../../domain/entities/team_relationship.dart';
import '../../state/team_page_state.dart';
import '../../utils/team_share.dart';
import 'tabs/team_about_tab.dart';
import 'tabs/team_matches_tab.dart';
import 'tabs/team_posts_tab.dart';
import 'tabs/team_squad_tab.dart';
import 'tabs/team_stats_tab.dart';
import 'team_page_header.dart';
import 'team_page_invite_banner.dart';
import 'team_page_options_sheet.dart';
import 'team_page_tabs.dart';
import 'team_page_visuals.dart';

class TeamPageBody extends StatefulWidget {
  const TeamPageBody({
    super.key,
    required this.teamId,
    required this.page,
    this.onBack,
  });

  final String teamId;
  final TeamPageState page;
  final VoidCallback? onBack;

  @override
  State<TeamPageBody> createState() => _TeamPageBodyState();
}

class _TeamPageBodyState extends State<TeamPageBody> {
  late TeamPageTab _active;

  List<TeamPageTab> get _tabs => widget.page.team.isArchived
      ? const [
          TeamPageTab.posts,
          TeamPageTab.stats,
          TeamPageTab.recent,
          TeamPageTab.about,
        ]
      : const [
          TeamPageTab.posts,
          TeamPageTab.squad,
          TeamPageTab.matches,
          TeamPageTab.stats,
          TeamPageTab.about,
        ];

  @override
  void initState() {
    super.initState();
    _active = _tabs.first;
  }

  @override
  void didUpdateWidget(covariant TeamPageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_tabs.contains(_active)) _active = _tabs.first;
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final recentCount = page.matches.where((match) => match.status.isPast).length;
    final liveMatches = page.matches.where((match) => match.status.isLive);
    final Match? live = liveMatches.isEmpty ? null : liveMatches.first;
    final firstTeam = page.relationship == TeamRelationship.owner &&
        page.roster.where((r) => r.member.playerType == PlayerType.claimed).length <= 1 &&
        page.matches.isEmpty;

    return ColoredBox(
      color: CkColors.paper,
      child: Column(
        children: [
          TeamPageHeader(
            teamId: widget.teamId,
            page: page,
            onBack: widget.onBack,
            onShare: () => shareTeam(
              context,
              teamId: widget.teamId,
              teamName: page.team.name,
            ),
            onOptions: () => showTeamPageOptionsSheet(
              context,
              teamId: widget.teamId,
              page: page,
            ),
          ),
          if (page.pendingInvite != null)
            TeamPageInviteBanner(
              invite: page.pendingInvite!,
              teamId: widget.teamId,
              teamName: page.team.name,
            ),
          if (live != null)
            _LiveBanner(
              match: live,
              teamName: page.team.name,
              opponentName: _opponentName(live),
            ),
          if (firstTeam)
            _InfoBanner(
              title: '${page.team.name} is live.',
              body: "You're the owner. Next: build your squad in Team Management.",
              onTap: () => context.push('/teams/${widget.teamId}/manage'),
            ),
          TeamPageTabs(
            items: _tabs,
            active: _active,
            recentCount: recentCount,
            onSelect: (tab) => setState(() => _active = tab),
          ),
          Expanded(child: _tabBody()),
        ],
      ),
    );
  }

  Widget _tabBody() {
    final page = widget.page;
    switch (_active) {
      case TeamPageTab.posts:
        return TeamPostsTab(teamId: widget.teamId);
      case TeamPageTab.squad:
        return TeamSquadTab(
          teamId: widget.teamId,
          team: page.team,
          roster: page.roster,
          relationship: page.relationship,
          viewerMembershipId: page.membership?.member.id.value,
        );
      case TeamPageTab.matches:
        return TeamMatchesTab(
          team: page.team,
          matches: page.matches,
          opponentNames: page.opponentNames,
        );
      case TeamPageTab.stats:
        return TeamStatsTab(matches: page.matches);
      case TeamPageTab.about:
        return TeamAboutTab(team: page.team, roster: page.roster);
      case TeamPageTab.recent:
        return TeamMatchesTab(
          team: page.team,
          matches: page.matches,
          opponentNames: page.opponentNames,
          onlyRecent: true,
        );
    }
  }

  String _opponentName(Match match) {
    final opponentId = match.teamAId == widget.page.team.id
        ? match.teamBId.value
        : match.teamAId.value;
    return widget.page.opponentNames[opponentId] ?? 'Opponent';
  }
}

class _LiveBanner extends StatelessWidget {
  const _LiveBanner({
    required this.match,
    required this.teamName,
    required this.opponentName,
  });

  final Match match;
  final String teamName;
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    final contextLabel = match.round?.trim().isNotEmpty == true
        ? match.round!.trim()
        : match.format.oversPerInnings > 0
            ? '${match.format.oversPerInnings} ov'
            : match.matchType.label;
    final venue = match.venue?.ground.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: InkWell(
        onTap: () => context.push('/matches/${match.id.value}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 2, 6, 2),
                    decoration: BoxDecoration(
                      color: CkColors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TeamPageLivePulse(),
                        const SizedBox(width: 5),
                        Text(
                          'LIVE NOW',
                          style: teamPageMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      contextLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: teamPageMono(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _LiveSide(name: teamName, alignEnd: false)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'VS',
                      style: teamPageMono(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  Expanded(child: _LiveSide(name: opponentName, alignEnd: true)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        venue.isEmpty ? 'Tap to watch the live match.' : venue,
                        style: CkType.body(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        'WATCH LIVE',
                        style: teamPageMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveSide extends StatelessWidget {
  const _LiveSide({required this.name, required this.alignEnd});
  final String name;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.display(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Live now',
            style: teamPageMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.body, required this.onTap});
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CkColors.greenSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.green.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: CkColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: CkType.display(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: CkColors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: CkType.body(fontSize: 12, color: CkColors.ink2),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: CkColors.green,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'Manage team',
                    style: CkType.body(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
