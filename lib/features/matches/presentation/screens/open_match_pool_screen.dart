import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match_request.dart';
import '../providers/match_pool_providers.dart';
import '../providers/matches_feed_providers.dart';

/// Dedicated Matchmaking & Open Pool Screen (`/matches/pool`).
class OpenMatchPoolScreen extends ConsumerWidget {
  const OpenMatchPoolScreen({super.key});

  void _showCodeDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CkColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ENTER CHALLENGE CODE',
          style: CkType.mono(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.1),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit match code shared by the hosting captain to find and accept their open challenge.',
              style: CkType.body(fontSize: 12.5, color: CkColors.ink2),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: CkType.mono(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.2),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'e.g. 849201',
                counterText: '',
                filled: true,
                fillColor: CkColors.paper2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: CkColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: CkColors.ink, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: CkType.mono(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CkColors.ink,
              foregroundColor: CkColors.paper,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final code = controller.text.trim();
              if (code.length < 6) return;
              Navigator.pop(ctx);
              _lookupAndNavigateByCode(context, ref, code);
            },
            child: Text('FIND MATCH', style: CkType.mono(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _lookupAndNavigateByCode(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final repo = ref.read(matchPoolRepositoryProvider);
    final result = await repo.findChallengeByCode(code);
    result.fold(
      (Failure failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${failure.message}'),
            backgroundColor: CkColors.red,
          ),
        );
      },
      (MatchRequest? challenge) {
        if (challenge == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No active challenge found for code "$code"'),
              backgroundColor: CkColors.ink,
            ),
          );
          return;
        }
        context.push('/challenges/${challenge.id.value}');
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poolAsync = ref.watch(filteredOpenMatchPoolProvider);
    final broadcastsAsync = ref.watch(myPoolBroadcastsProvider);
    final currentFilter = ref.watch(openMatchPoolFilterProvider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      appBar: AppBar(
        backgroundColor: CkColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: CkColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Open Match Pool',
          style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pin_outlined, color: CkColors.ink),
            tooltip: 'Enter 6-digit Code',
            onPressed: () => _showCodeDialog(context, ref),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: CkColors.hairline, height: 1),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: CkColors.ink,
          backgroundColor: CkColors.paper,
          onRefresh: () async {
            ref.invalidate(openMatchPoolProvider);
            ref.invalidate(myPoolBroadcastsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Hero Banner: Broadcast or Claim
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Pill(label: 'LIVE MATCHMAKING', tone: PillTone.green),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showCodeDialog(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: CkColors.paper,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: CkColors.hairline),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.dialpad_rounded, size: 13, color: CkColors.ink),
                                const SizedBox(width: 4),
                                Text(
                                  'Enter Code',
                                  style: CkType.mono(fontSize: 9.5, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Broadcast an open challenge to find local opponents, or browse and apply to match posts from other teams.',
                      style: CkType.body(fontSize: 13, color: CkColors.ink2, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CkButton(
                            label: '+ Broadcast Open Challenge',
                            onPressed: () {
                              context.push('/matches/send-challenge');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Dedicated My Broadcasts banner if user has active pool requests
              broadcastsAsync.when(
                data: (myBroadcasts) {
                  if (myBroadcasts.isEmpty) return const SizedBox.shrink();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/matches/my-broadcasts'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE68A),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.podcasts_rounded,
                                  size: 18,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'MY BROADCASTS',
                                          style: CkType.mono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                            color: const Color(0xFF92400E),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF92400E),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${myBroadcasts.length}',
                                            style: CkType.mono(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'View and review proposals for your hosted challenges',
                                      style: CkType.body(
                                        fontSize: 12,
                                        color: const Color(0xFF78350F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Color(0xFF92400E),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Main Explore Header & Filter Chips Row
              Row(
                children: [
                  Text(
                    'EXPLORE OPEN POOL',
                    style: CkType.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: CkColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Active Opponents',
                    style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),

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

              const SizedBox(height: 16),

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
                              'NO OPEN CHALLENGES FROM OTHER TEAMS',
                              style: CkType.mono(fontSize: 10.5, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Check back soon or share your invite code with opposing captains.',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: CkColors.paper2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CkColors.hairline),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CODE',
                        style: CkType.mono(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: CkColors.muted,
                        ),
                      ),
                      Text(
                        item.shareCode,
                        style: CkType.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.14,
                          color: CkColors.ink,
                        ),
                      ),
                    ],
                  ),
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
                  'Proposed: ${item.timeLabel}',
                  style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                ),
                const Spacer(),
                Text(
                  'View & Apply →',
                  style: CkType.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
