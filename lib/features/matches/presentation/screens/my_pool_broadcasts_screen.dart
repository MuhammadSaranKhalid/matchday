import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/match_pool_providers.dart';
import '../providers/matches_feed_providers.dart';

/// Dedicated screen for managing the user's active Open Match Pool broadcasts.
class MyPoolBroadcastsScreen extends ConsumerWidget {
  const MyPoolBroadcastsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcastsAsync = ref.watch(myPoolBroadcastsProvider);

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
          'My Broadcasts',
          style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: CkColors.ink),
            tooltip: 'Broadcast New Challenge',
            onPressed: () => context.push('/matches/send-challenge'),
          ),
          const SizedBox(width: 8),
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
            ref.invalidate(myPoolBroadcastsProvider);
          },
          child: broadcastsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: CkColors.ink),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load broadcasts: $e', style: CkType.body(fontSize: 12)),
              ),
            ),
            data: (myBroadcasts) {

              if (myBroadcasts.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 48),
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: CkColors.paper2,
                          shape: BoxShape.circle,
                          border: Border.all(color: CkColors.hairline),
                        ),
                        child: const Icon(
                          Icons.podcasts_rounded,
                          size: 32,
                          color: CkColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Active Broadcasts',
                      textAlign: TextAlign.center,
                      style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You do not have any open match pool requests right now. Broadcast a challenge to receive match proposals from local teams.',
                      textAlign: TextAlign.center,
                      style: CkType.body(fontSize: 13, color: CkColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: CkButton(
                        label: '+ Broadcast Open Challenge',
                        onPressed: () {
                          context.push('/matches/send-challenge');
                        },
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: myBroadcasts.length + 1,
                itemBuilder: (context, idx) {
                  if (idx == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'OPEN CHALLENGES HOSTED BY YOUR TEAMS (${myBroadcasts.length})',
                        style: CkType.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: CkColors.muted,
                        ),
                      ),
                    );
                  }
                  final item = myBroadcasts[idx - 1];
                  return _MyBroadcastItem(
                    item: item,
                    onTap: () {
                      context.push('/challenges/${item.request.id.value}');
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MyBroadcastItem extends ConsumerWidget {
  const _MyBroadcastItem({required this.item, required this.onTap});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final from = item.fromTeam;
    final appsAsync = ref.watch(challengePoolApplicationsProvider(item.request.id.value));
    final applications = appsAsync.value ?? const [];
    final pendingCount = applications.where((a) => a.status.name == 'pending').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Crest(
                      short: _teamShort(from),
                      color: _teamColor(from),
                      size: 42,
                      radius: 12,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  from?.name ?? 'Your Team',
                                  style: CkType.display(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Pill(label: 'HOSTING', tone: PillTone.amber),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.formatLabel} · ${item.venue}',
                            style: CkType.body(fontSize: 12.5, color: CkColors.ink2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: pendingCount > 0
                        ? const Color(0xFFFEF3C7)
                        : CkColors.paper2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: pendingCount > 0
                          ? const Color(0xFFFCD34D)
                          : CkColors.hairline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pendingCount > 0
                            ? Icons.group_outlined
                            : Icons.hourglass_empty_rounded,
                        size: 16,
                        color: pendingCount > 0
                            ? const Color(0xFF92400E)
                            : CkColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pendingCount > 0
                              ? '$pendingCount team proposal${pendingCount > 1 ? 's' : ''} waiting for review'
                              : 'Broadcast is live. Waiting for applicant teams...',
                          style: CkType.mono(
                            fontSize: 11,
                            fontWeight: pendingCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: pendingCount > 0
                                ? const Color(0xFF92400E)
                                : CkColors.ink2,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: CkColors.ink,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13.5,
                      color: CkColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item.timeLabel,
                        style: CkType.body(
                          fontSize: 11.5,
                          color: CkColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Review Applications →',
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
        ),
      ),
    );
  }
}
