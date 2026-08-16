import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../providers/teams_providers.dart';
import '../widgets/team_avatar.dart';
import '../widgets/team_manage/announcements_manage_tab.dart';
import '../widgets/team_manage/requests_tab.dart';
import '../widgets/team_manage/roster_tab.dart';
import '../widgets/team_manage/settings_tab.dart';

/// Complete Manager console: Roster, Posts, Requests, and Settings.
class TeamManageScreen extends ConsumerStatefulWidget {
  const TeamManageScreen({
    super.key,
    required this.teamId,
    this.justCreated = false,
  });

  final String teamId;
  final bool justCreated;

  @override
  ConsumerState<TeamManageScreen> createState() => _TeamManageScreenState();
}

class _TeamManageScreenState extends ConsumerState<TeamManageScreen> {
  int _activeTab = 0; // 0: Roster, 1: Posts, 2: Requests, 3: Settings

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamProvider(widget.teamId));

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (teamAsync) {
          AsyncData(:final value?) => Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/teams');
                          }
                        },
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: CkColors.ink,
                        ),
                      ),
                      TeamAvatar(
                        name: value.name,
                        primaryColor: value.primaryColor,
                        logoUrl: value.logoUrl,
                        monogram: value.logoMonogram,
                        size: 36,
                        radius: 10,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value.name,
                              style: CkType.display(
                                fontSize: 17,
                                letterSpacing: -0.01,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/teams/${value.id.value}'),
                              child: Text(
                                'Public team page →',
                                style: CkType.body(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: CkColors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                _TabHeader(
                  activeIndex: _activeTab,
                  onTabSelected: (i) => setState(() => _activeTab = i),
                ),

                if (widget.justCreated && _activeTab == 0)
                  const _JustCreatedBanner(),

                // Tab Content
                Expanded(
                  child: switch (_activeTab) {
                    0 => RosterTab(team: value),
                    1 => TeamAnnouncementsManageTab(team: value),
                    2 => RequestsTab(team: value),
                    _ => SettingsTab(team: value),
                  },
                ),
              ],
            ),
          AsyncData() => const Center(child: Text('Team not found')),
          AsyncError() => const Center(child: Text('Could not load team')),
          _ => const Center(
              child: CircularProgressIndicator(color: CkColors.ink),
            ),
        },
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({required this.activeIndex, required this.onTabSelected});
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Roster',
            active: activeIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          _TabItem(
            label: 'Posts',
            active: activeIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          _TabItem(
            label: 'Requests',
            active: activeIndex == 2,
            onTap: () => onTabSelected(2),
          ),
          _TabItem(
            label: 'Settings',
            active: activeIndex == 3,
            onTap: () => onTabSelected(3),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? CkColors.ink : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: CkType.body(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? CkColors.ink : CkColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _JustCreatedBanner extends StatelessWidget {
  const _JustCreatedBanner();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CkColors.greenSoft,
          borderRadius: BorderRadius.circular(CkRadii.sm),
        ),
        child: Text(
          'Team created. Add your first player below.',
          style: CkType.body(
            fontSize: 13,
            color: const Color(0xFF1E5A2C),
          ),
        ),
      );
}
