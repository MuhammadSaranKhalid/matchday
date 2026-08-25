import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/match_pool_providers.dart';
import '../providers/matches_feed_providers.dart';

/// The Pool tab (`/pool`) — Matchmaking & Open Match Pool.
///
/// This is a bottom-nav destination (slot 3, taken over from Pavilion on
/// 2026-08-21), so it renders as a bare tab body: [AppShell] already supplies
/// the Scaffold, the [V2Header] titled "Pool" and the nav bar. Hence no
/// Scaffold / AppBar / back button here — the "My broadcasts" drill-down that
/// used to be an AppBar action is now a row beneath the broadcast banner.
class OpenMatchPoolScreen extends ConsumerWidget {
  const OpenMatchPoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poolAsync = ref.watch(filteredOpenMatchPoolProvider);
    final currentFilter = ref.watch(openMatchPoolFilterProvider);

    return ColoredBox(
      color: CkColors.paper,
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: CkColors.ink,
          backgroundColor: CkColors.paper,
          onRefresh: () async {
            ref.invalidate(openMatchPoolProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Contextual "Post a pool request" Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: CkColors.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Post a pool request',
                            style: CkType.display(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: CkColors.paper,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Broadcast to find local challengers',
                            style: CkType.body(
                              fontSize: 11.5,
                              color: CkColors.paper.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CkColors.paper,
                        foregroundColor: CkColors.ink,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        context.push('/matches/send-challenge');
                      },
                      child: Text(
                        '+ Post',
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in const ['All', 'Tape Ball', 'Leather', '20 Overs', '10 Overs'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => ref.read(openMatchPoolFilterProvider.notifier).setFilter(filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: currentFilter == filter ? CkColors.ink : CkColors.paper,
                              borderRadius: BorderRadius.circular(999),
                              border: currentFilter == filter
                                  ? null
                                  : Border.all(color: CkColors.hairline),
                            ),
                            child: Text(
                              filter.toUpperCase(),
                              style: CkType.mono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.10,
                                color: currentFilter == filter ? CkColors.paper : CkColors.ink2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              poolAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: CkColors.ink),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Failed to load pool: $e', style: CkType.body(fontSize: 12)),
                  ),
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.explore_off_outlined, size: 36, color: CkColors.muted),
                            const SizedBox(height: 10),
                            Text(
                              'NO OPEN CHALLENGES FOUND',
                              style: CkType.mono(fontSize: 10.5, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to broadcast an open match challenge to nearby teams.',
                              textAlign: TextAlign.center,
                              style: CkType.body(fontSize: 12, color: CkColors.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in posts)
                        _PoolCard(
                          item: item,
                          onTap: () {
                            context.push('/challenges/${item.request.id.value}');
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoolCard extends StatelessWidget {
  const _PoolCard({required this.item, required this.onTap});

  final OpenMatchPoolItem item;
  final VoidCallback onTap;

  String _teamShort(Team? team) {
    if (team == null) return 'TM';
    if (team.logoMonogram != null && team.logoMonogram!.isNotEmpty) {
      return team.logoMonogram!;
    }
    final name = team.name;
    if (name.length >= 2) {
      final parts = name.split(' ');
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.substring(0, 2).toUpperCase();
    }
    return name.toUpperCase();
  }

  Color _teamColor(Team? team) {
    if (team == null || team.primaryColor == null) return CkColors.red;
    final hex = team.primaryColor!.replaceAll('#', '');
    final val = int.tryParse(hex, radix: 16);
    if (val == null) return CkColors.red;
    return Color(0xFF000000 | val);
  }

  @override
  Widget build(BuildContext context) {
    final from = item.fromTeam;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Crest(
                  short: _teamShort(from),
                  color: _teamColor(from),
                  size: 40,
                  radius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        from?.name ?? 'Open Challenger',
                        style: CkType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.formatLabel} · ${item.venue}',
                        style: CkType.body(fontSize: 12, color: CkColors.ink2),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: CkColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: CkColors.hairline, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: CkColors.muted),
                const SizedBox(width: 6),
                Text(
                  item.timeLabel,
                  style: CkType.body(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  'View & Apply',
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: CkColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
