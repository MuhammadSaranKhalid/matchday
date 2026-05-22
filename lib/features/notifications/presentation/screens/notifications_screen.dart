import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/circk_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../matches/domain/entities/match.dart';
import '../../../matches/presentation/providers/matches_providers.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';

/// Notification center (Notifications.jsx). Phase 1 derives match-event
/// notifications from the user's matches — there is no notifications backend
/// yet (push, tournament/social/milestone alerts are v1.1).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(myMatchesProvider);
    final myTeamIds =
        (ref.watch(myTeamsProvider).value ?? const <Team>[]).map((t) => t.id).toSet();
    final teamNames = <String, String>{
      for (final t in ref.watch(allTeamsProvider).value ?? const <Team>[])
        t.id.value: t.name,
    };
    final userId = ref.watch(currentUserStreamProvider).value?.id.value;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: switch (matches) {
                AsyncData(:final value) => _feed(
                    context,
                    _buildItems(value, myTeamIds, teamNames, userId),
                  ),
                AsyncError() => const Center(child: Text('Could not load notifications')),
                _ => const Center(
                    child: CircularProgressIndicator(color: CkColors.ink)),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
            ),
            Text('Notifications', style: CkType.display(fontSize: 22)),
          ],
        ),
      );

  Widget _feed(BuildContext context, List<_Notif> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  size: 56, color: CkColors.soft),
              const SizedBox(height: 14),
              Text("You're all caught up", style: CkType.display(fontSize: 20)),
              const SizedBox(height: 6),
              Text('Match requests and updates will show up here.',
                  textAlign: TextAlign.center,
                  style: CkType.body(fontSize: 14, color: CkColors.muted)),
            ],
          ),
        ),
      );
    }

    final today = items.where((i) => i.isToday).toList();
    final earlier = items.where((i) => !i.isToday).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (today.isNotEmpty) ...[
          _sectionLabel('TODAY'),
          for (final n in today) _row(context, n),
        ],
        if (earlier.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionLabel('EARLIER'),
          for (final n in earlier) _row(context, n),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: CkType.mono(fontSize: 11, color: CkColors.muted)),
      );

  Widget _row(BuildContext context, _Notif n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push(n.route),
        borderRadius: BorderRadius.circular(CkRadii.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: n.unread ? CkColors.cream : CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(
                color: n.unread ? CkColors.creamBorder : CkColors.hairline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(n.icon, size: 20, color: CkColors.ink2),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n.title,
                              style: CkType.body(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        if (n.pill != null) _pill(n.pill!),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(n.body,
                        style: CkType.body(fontSize: 12, color: CkColors.ink2)),
                    const SizedBox(height: 4),
                    Text(n.time,
                        style: CkType.mono(fontSize: 9, color: CkColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(_Pill p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(p.text, style: CkType.mono(fontSize: 9, color: p.fg)),
      );

  List<_Notif> _buildItems(
    List<Match> matches,
    Set<TeamId> myTeamIds,
    Map<String, String> teamNames,
    String? userId,
  ) {
    final items = <_Notif>[];
    final sorted = [...matches]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final m in sorted) {
      final incoming = myTeamIds.contains(m.teamBId);
      final mine = incoming ? m.teamBId : m.teamAId;
      final opponentId = (mine == m.teamAId ? m.teamBId : m.teamAId).value;
      final opponent = teamNames[opponentId] ?? 'A team';
      final time = timeago.format(m.createdAt);

      final _Notif? n = switch (m.status) {
        MatchStatus.pending when incoming => _Notif(
            icon: Icons.mark_email_unread_outlined,
            title: 'Match request',
            body: '$opponent challenged you to a friendly',
            time: time,
            unread: true,
            pill: const _Pill('REQUEST', CkColors.amber, CkColors.ink2),
            route: '/matches/${m.id.value}/request',
            createdAt: m.createdAt,
          ),
        MatchStatus.pending => _Notif(
            icon: Icons.schedule,
            title: 'Awaiting reply',
            body: 'You challenged $opponent',
            time: time,
            route: '/matches/${m.id.value}/request',
            createdAt: m.createdAt,
          ),
        MatchStatus.accepted => _Notif(
            icon: Icons.play_circle_outline,
            title: 'Match confirmed',
            body: 'vs $opponent · ready to start',
            time: time,
            unread: true,
            pill: const _Pill('READY', CkColors.green, Colors.white),
            route: '/matches/${m.id.value}/start',
            createdAt: m.createdAt,
          ),
        MatchStatus.declined => _Notif(
            icon: Icons.cancel_outlined,
            title: 'Match declined',
            body: 'vs $opponent',
            time: time,
            route: '/matches/${m.id.value}/request',
            createdAt: m.createdAt,
          ),
        MatchStatus.live => _Notif(
            icon: Icons.sensors_rounded,
            title: 'Match is live',
            body: 'vs $opponent',
            time: time,
            unread: true,
            pill: const _Pill('LIVE', CkColors.red, Colors.white),
            route: '/matches/${m.id.value}/live',
            createdAt: m.createdAt,
          ),
        MatchStatus.completed => _Notif(
            icon: Icons.emoji_events_outlined,
            title: 'Match finished',
            body: m.resultDescription ?? 'vs $opponent',
            time: time,
            route: '/matches/${m.id.value}/live',
            createdAt: m.createdAt,
          ),
        _ => null,
      };
      if (n != null) items.add(n);
    }
    return items;
  }
}

class _Notif {
  _Notif({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.route,
    required this.createdAt,
    this.unread = false,
    this.pill,
  });

  final IconData icon;
  final String title;
  final String body;
  final String time;
  final String route;
  final DateTime createdAt;
  final bool unread;
  final _Pill? pill;

  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }
}

class _Pill {
  const _Pill(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;
}
