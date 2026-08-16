import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../matches/presentation/providers/my_matches_providers.dart';
import '../../../teams/presentation/providers/teams_providers.dart';

/// The sliding Management Console Side Sheet.
/// Acts as a central command gateway for Captains, Scorers, and Tournament Organizers.
class ManagementSheet extends ConsumerWidget {
  const ManagementSheet({super.key});

  static void show(BuildContext context) {
    HapticFeedback.mediumImpact();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ManagementSheet',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const Align(
        alignment: Alignment.centerRight,
        child: ManagementSheet(),
      ),
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTeamsAsync = ref.watch(myTeamsProvider);
    final teamCount = myTeamsAsync.value?.length ?? 0;

    final myMatchesAsync = ref.watch(myMatchesViewProvider);
    final (matchBadge, matchBadgeColor) = myMatchesAsync.maybeWhen(
      data: (view) {
        final hasLive = view.confirmed.any((m) => m.live);
        if (hasLive) {
          return ('LIVE NOW', CkColors.red);
        }
        final count = view.confirmed.length;
        if (count > 0) {
          return ('$count Upcoming', CkColors.ink);
        }
        if (view.pendingRequestsCount > 0) {
          return ('${view.pendingRequestsCount} Pending', CkColors.amber);
        }
        return (null, null);
      },
      orElse: () => (null, null),
    );

    final width = MediaQuery.of(context).size.width * 0.86;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width.clamp(320.0, 420.0),
        height: double.infinity,
        decoration: BoxDecoration(
          color: CkColors.paper,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: CkColors.ink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const V2Svg(
                        V2Icons.management,
                        size: 18,
                        color: CkColors.paper,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Management Hub',
                            style: CkType.display(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.01,
                            ),
                          ),
                          Text(
                            'Captains & Officials Console',
                            style: CkType.body(
                              fontSize: 11,
                              color: CkColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: CkColors.paper2,
                          shape: BoxShape.circle,
                          border: Border.all(color: CkColors.hairline),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: CkColors.hairline, height: 1),

              // Scrollable Management Gateways
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // Section: Matches & Fixtures
                    const _SectionHeader(
                      title: 'Matches & Fixtures',
                      icon: Icons.sports_cricket_rounded,
                    ),
                    const SizedBox(height: 8),
                    _ActionCard(
                      title: 'My Matches',
                      subtitle: 'Upcoming fixtures, live scoreboards, match challenges & history',
                      icon: Icons.event_available_rounded,
                      badge: matchBadge,
                      badgeColor: matchBadgeColor,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/pavilion/my-matches');
                      },
                    ),
                    const SizedBox(height: 8),
                    _ActionCard(
                      title: 'Send Match Challenge',
                      subtitle: 'Challenge another team, set format, overs & pick playing XI',
                      icon: Icons.add_circle_outline_rounded,
                      badge: 'New Match',
                      badgeColor: CkColors.red,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/challenge');
                      },
                    ),

                    const SizedBox(height: 24),

                    // Section: Teams & Rosters
                    const _SectionHeader(
                      title: 'Teams & Rosters',
                      icon: Icons.shield_outlined,
                    ),
                    const SizedBox(height: 8),
                    _ActionCard(
                      title: 'My Teams & Squads',
                      subtitle: 'Manage rosters, player roles, join requests & create new teams',
                      icon: Icons.groups_outlined,
                      badge: teamCount > 0 ? '$teamCount Teams' : null,
                      badgeColor: CkColors.ink,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/teams');
                      },
                    ),

                    const SizedBox(height: 24),

                    // Section: Matchmaking & Challenges
                    const _SectionHeader(
                      title: 'Matchmaking & Open Pool',
                      icon: Icons.travel_explore_rounded,
                    ),
                    const SizedBox(height: 8),
                    _ActionCard(
                      title: 'Find Opponent / Open Pool',
                      subtitle: 'Browse local open requests or broadcast an open fixture',
                      icon: Icons.explore_outlined,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/matches');
                      },
                    ),

                    const SizedBox(height: 24),

                    // Section: Tournaments & Leagues
                    const _SectionHeader(
                      title: 'Tournaments & Leagues',
                      icon: Icons.emoji_events_outlined,
                    ),
                    const SizedBox(height: 8),
                    _ActionCard(
                      title: 'Tournament Organizers Hub',
                      subtitle: 'Manage tournament registrations, draws, and points tables',
                      icon: Icons.account_tree_outlined,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/pavilion');
                      },
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


class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: CkColors.ink),
        const SizedBox(width: 6),
        Text(
          title,
          style: CkType.display(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.01,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CkColors.paper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: Icon(icon, size: 20, color: CkColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CkType.display(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (badgeColor ?? CkColors.ink).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor ?? CkColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(fontSize: 11, color: CkColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: CkColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
