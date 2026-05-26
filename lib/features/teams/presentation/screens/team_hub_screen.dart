import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/roster_member.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../providers/teams_providers.dart';
import '../widgets/team_avatar.dart';

/// Public team page: hero + Squad (roster) + About. Matches/Stats tabs from the
/// design need match + scoring data (F4+/F8) and are out of Phase 1 scope.
class TeamHubScreen extends ConsumerWidget {
  const TeamHubScreen({super.key, required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: switch (teamAsync) {
        AsyncData(:final value?) => _Hub(team: value),
        AsyncData() => const _NotFound(),
        AsyncError() => const Center(child: Text('Could not load team')),
        _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      },
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();
  @override
  Widget build(BuildContext context) => const SafeArea(
        child: Column(
          children: [
            _BackBar(overlay: false),
            Expanded(child: Center(child: Text('Team not found'))),
          ],
        ),
      );
}

class _Hub extends ConsumerWidget {
  const _Hub({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserStreamProvider).value?.id.value;
    final canManage = userId != null && team.isManagedBy(userId);
    final roster = ref.watch(rosterProvider(team.id.value));

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: _Hero(team: team, canManage: canManage),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarHeader(
              const TabBar(
                labelColor: CkColors.ink,
                unselectedLabelColor: CkColors.muted,
                indicatorColor: CkColors.ink,
                tabs: [Tab(text: 'Squad'), Tab(text: 'About')],
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            switch (roster) {
              AsyncData(:final value) => _Squad(rosterMembers: value, team: team),
              _ => const Center(
                  child: CircularProgressIndicator(color: CkColors.ink)),
            },
            _About(team: team),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.team, required this.canManage});
  final Team team;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final primary = parseHexColor(team.primaryColor, fallback: CkColors.ink);
    return Container(
      color: primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white),
                  ),
                  const Spacer(),
                  if (canManage) ...[
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/matches/setup/${team.id.value}'),
                      icon: const Icon(Icons.add_rounded,
                          size: 16, color: Colors.white),
                      label: Text('Match',
                          style: CkType.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/teams/${team.id.value}/manage'),
                      icon: const Icon(Icons.tune_rounded,
                          size: 16, color: Colors.white),
                      label: Text('Manage',
                          style: CkType.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _HeroCrest(team: team, primary: primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            team.type.name.toUpperCase(),
                            if (team.city != null && team.city!.isNotEmpty)
                              team.city!.toUpperCase(),
                          ].join(' · '),
                          style: CkType.mono(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(height: 4),
                        Text(team.name,
                            style:
                                CkType.display(fontSize: 28, color: Colors.white)),
                        if (team.tagline != null && team.tagline!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '“${team.tagline!.trim()}”',
                            style: CkType.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                              color: Colors.white.withValues(alpha: 0.9),
                            ).copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 64×64 white-on-primary crest for the hub hero. Renders the uploaded logo
/// when [Team.logoUrl] is set; otherwise the monogram (override if present,
/// else auto-derived) in [primary] on white.
class _HeroCrest extends StatelessWidget {
  const _HeroCrest({required this.team, required this.primary});
  final Team team;
  final Color primary;

  String get _mono {
    final override = team.logoMonogram?.trim();
    if (override != null && override.isNotEmpty) return override.toUpperCase();
    return teamMonogram(team.name);
  }

  Widget _monoTile() => Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(_mono, style: CkType.display(fontSize: 26, color: primary)),
      );

  @override
  Widget build(BuildContext context) {
    final url = team.logoUrl;
    if (url == null || url.isEmpty) return _monoTile();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 64,
        height: 64,
        color: Colors.white,
        padding: const EdgeInsets.all(6),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _monoTile(),
          loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : _monoTile(),
        ),
      ),
    );
  }
}

class _Squad extends StatelessWidget {
  const _Squad({required this.rosterMembers, required this.team});
  final List<RosterMember> rosterMembers;
  final Team team;

  @override
  Widget build(BuildContext context) {
    if (rosterMembers.isEmpty) {
      return Center(
        child: Text('No players yet',
            style: CkType.body(fontSize: 14, color: CkColors.muted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rosterMembers.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: CkColors.hairline),
      itemBuilder: (_, i) =>
          _RosterRow(entry: rosterMembers[i], team: team),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.entry, required this.team});
  final RosterMember entry;
  final Team team;

  @override
  Widget build(BuildContext context) {
    final m = entry.member;
    final primary = parseHexColor(team.primaryColor, fallback: CkColors.ink);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: m.jerseyNumber == null ? CkColors.paper2 : primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              m.jerseyNumber == null ? '—' : '#${m.jerseyNumber}',
              style: CkType.display(
                fontSize: 12,
                color: m.jerseyNumber == null ? CkColors.muted : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(entry.displayName,
                style: CkType.display(fontSize: 15, letterSpacing: -0.01)),
          ),
          if (m.role != MemberRole.player) _RoleChip(role: m.role),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final MemberRole role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      MemberRole.captain => 'C',
      MemberRole.viceCaptain => 'VC',
      MemberRole.wicketKeeper => 'WK',
      MemberRole.player => '',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: CkType.mono(fontSize: 9, color: CkColors.ink2)),
    );
  }
}

class _About extends StatelessWidget {
  const _About({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Type', team.type.name[0].toUpperCase() + team.type.name.substring(1)),
      if (team.foundedYear != null) ('Founded', '${team.foundedYear}'),
      if (team.city != null && team.city!.isNotEmpty) ('City', team.city!),
      if (team.homeGround != null && team.homeGround!.isNotEmpty)
        ('Home ground', team.homeGround!),
      ('Privacy', team.privacy.name[0].toUpperCase() + team.privacy.name.substring(1)),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.hairline),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            top: BorderSide(color: CkColors.hairline)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(rows[i].$1.toUpperCase(),
                          style:
                              CkType.mono(fontSize: 11, color: CkColors.muted)),
                      Text(rows[i].$2,
                          style: CkType.body(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.overlay});
  final bool overlay;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.chevron_left_rounded,
              color: overlay ? Colors.white : CkColors.ink),
        ),
      );
}

/// Pins the TabBar below the hero while scrolling.
class _TabBarHeader extends SliverPersistentHeaderDelegate {
  _TabBarHeader(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: CkColors.paper,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarHeader oldDelegate) => false;
}
