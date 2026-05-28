import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';
import '../state/notifications_view.dart';

/// Notifications inbox — bell-tap destination. Live feed via the
/// `user:<id>:notifications` broadcast channel, tier-grouped into REPLY NOW
/// / THIS WEEK / FYI per the design.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(liveNotificationsProvider);
    final view = ref.watch(notificationsViewProvider);

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              unreadCount: view.unreadCount,
              total: view.total,
              onClose: () => Navigator.of(context).maybePop(),
              onMarkAllRead: view.unreadCount == 0
                  ? null
                  : () => _markAllRead(context, ref),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: CkColors.ink),
                ),
                error: (e, _) => _Error(
                  message: e is FailureWrapper ? e.failure.message : e.toString(),
                  onRetry: () => ref.invalidate(liveNotificationsProvider),
                ),
                data: (_) => view.isEmpty
                    ? const _Empty()
                    : _Body(view: view, onTap: (n) => _onTap(context, ref, n)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(markAllNotificationsReadUseCaseProvider)
        .call(const NoParams());
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {},
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    // Optimistic read flag — the broadcast `notification_updated` will
    // confirm. Fire-and-forget so the deep-link is snappy.
    if (!n.isRead) {
      // ignore: unawaited_futures
      ref.read(markNotificationReadUseCaseProvider).call(n.id);
    }
    final route = _routeFor(n);
    if (route != null) context.push(route);
  }

  String? _routeFor(AppNotification n) {
    final p = n.payload;
    switch (n.type) {
      case NotificationType.matchRequest:
      case NotificationType.matchRequestDecision:
        final requestId = p['request_id'] as String?;
        if (requestId != null) return '/challenges/$requestId';
        return null;
      case NotificationType.matchStarting:
      case NotificationType.matchUpcoming:
        final matchId = p['match_id'] as String?;
        if (matchId != null) return '/matches/$matchId/start';
        return null;
      case NotificationType.teamInvitation:
      case NotificationType.teamPost:
        final teamId = p['team_id'] as String?;
        if (teamId != null) return '/teams/$teamId';
        return null;
      case NotificationType.claimDecision:
      case NotificationType.statMilestone:
      case NotificationType.postLike:
      case NotificationType.postComment:
      case NotificationType.commentReply:
      case NotificationType.mention:
      case NotificationType.tournamentPost:
      case NotificationType.follow:
        return null;
    }
  }
}

// ─── Layout ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.unreadCount,
    required this.total,
    required this.onClose,
    this.onMarkAllRead,
  });
  final int unreadCount;
  final int total;
  final VoidCallback onClose;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.close_rounded, color: CkColors.ink),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notifications',
                  style: CkType.display(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    unreadCount == 0
                        ? 'All caught up · $total total'
                        : '$unreadCount needs you · $total total',
                    style: CkType.body(fontSize: 12, color: CkColors.muted),
                  ),
                ),
              ],
            ),
          ),
          if (onMarkAllRead != null)
            TextButton(
              onPressed: onMarkAllRead,
              child: Text(
                'Mark all read',
                style: CkType.body(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.view, required this.onTap});
  final NotificationsView view;
  final void Function(AppNotification) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (view.now.isNotEmpty) ...[
          const _TierHead(label: 'REPLY NOW', tone: _TierTone.red),
          for (final n in view.now) _Row(n: n, onTap: () => onTap(n)),
        ],
        if (view.week.isNotEmpty) ...[
          const _TierHead(label: 'THIS WEEK', tone: _TierTone.amber),
          for (final n in view.week) _Row(n: n, onTap: () => onTap(n)),
        ],
        if (view.fyi.isNotEmpty) ...[
          const _TierHead(label: 'FYI', tone: _TierTone.muted),
          for (final n in view.fyi) _Row(n: n, onTap: () => onTap(n)),
        ],
        const SizedBox(height: 24),
        Center(
          child: Text(
            'END OF INBOX',
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: CkColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

enum _TierTone { red, amber, muted }

class _TierHead extends StatelessWidget {
  const _TierHead({required this.label, required this.tone});
  final String label;
  final _TierTone tone;

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (tone) {
      _TierTone.red => CkColors.red,
      _TierTone.amber => CkColors.amber,
      _TierTone.muted => CkColors.muted,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !n.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 13, 18, 13),
        decoration: const BoxDecoration(
          color: CkColors.paper,
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left unread indicator (3px tall stripe).
            Container(
              width: 3,
              height: 32,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                color: unread
                    ? (n.isUrgent ? CkColors.red : CkColors.ink2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _CatIcon(type: n.type),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _titleFor(n),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.body(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _shortTime(n.createdAt),
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                  if (_subFor(n) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _subFor(n)!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                          fontSize: 11.5,
                          color: CkColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _titleFor(AppNotification n) {
    final p = n.payload;
    switch (n.type) {
      case NotificationType.matchRequest:
        return 'New match challenge';
      case NotificationType.matchRequestDecision:
        final status = (p['status'] as String?) ?? '';
        if (status == 'accepted') return 'Your challenge was accepted';
        if (status == 'declined') return 'Your challenge was declined';
        if (status == 'countered') return 'Your challenge has a counter offer';
        if (status == 'cancelled') return 'Your challenge was withdrawn';
        return 'Match challenge update';
      case NotificationType.matchStarting:
        return 'Your match is starting now';
      case NotificationType.matchUpcoming:
        return 'Match coming up';
      case NotificationType.teamInvitation:
        return 'You were invited to a team';
      case NotificationType.claimDecision:
        return 'Your player-profile claim was reviewed';
      case NotificationType.statMilestone:
        return 'Career milestone reached';
      case NotificationType.postLike:
        return 'Someone liked your post';
      case NotificationType.postComment:
        return 'New comment on your post';
      case NotificationType.commentReply:
        return 'Someone replied to your comment';
      case NotificationType.mention:
        return 'You were mentioned';
      case NotificationType.teamPost:
        return 'New team post';
      case NotificationType.tournamentPost:
        return 'New tournament post';
      case NotificationType.follow:
        return 'You have a new follower';
    }
  }

  static String? _subFor(AppNotification n) {
    final p = n.payload;
    // Pass through whatever the producer trigger put in `sub` if present;
    // otherwise leave null.
    final sub = p['sub'] ?? p['message'] ?? p['preview'];
    if (sub is String && sub.isNotEmpty) return sub;
    return null;
  }

  static String _shortTime(DateTime t) {
    final delta = DateTime.now().difference(t);
    if (delta.inMinutes < 1) return 'now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m';
    if (delta.inHours < 24) return '${delta.inHours}h';
    if (delta.inDays < 7) {
      return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
          [t.weekday - 1];
    }
    return timeago.format(t, locale: 'en_short');
  }
}

class _CatIcon extends StatelessWidget {
  const _CatIcon({required this.type});
  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.matchRequest ||
      NotificationType.matchRequestDecision =>
        (Icons.sports_cricket, CkColors.red),
      NotificationType.matchStarting ||
      NotificationType.matchUpcoming =>
        (Icons.play_circle_outline, CkColors.red),
      NotificationType.teamInvitation =>
        (Icons.group_add_outlined, CkColors.amber),
      NotificationType.claimDecision => (Icons.verified, CkColors.green),
      NotificationType.statMilestone =>
        (Icons.emoji_events_outlined, CkColors.amber),
      NotificationType.postLike => (Icons.favorite_border, CkColors.red),
      NotificationType.postComment ||
      NotificationType.commentReply =>
        (Icons.chat_bubble_outline, CkColors.ink2),
      NotificationType.mention => (Icons.alternate_email, CkColors.ink2),
      NotificationType.teamPost ||
      NotificationType.tournamentPost =>
        (Icons.campaign_outlined, CkColors.ink2),
      NotificationType.follow => (Icons.person_add_outlined, CkColors.ink2),
    };
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_none,
                size: 32, color: CkColors.muted),
          ),
          const SizedBox(height: 18),
          Text(
            'Inbox zero — and we’d like to keep it that way.',
            style: CkType.display(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.025,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We’re an opinionated bell — not a feed. Match requests, '
            'roster gaps, milestones. Nothing here yet — your first '
            'match-day starts the clock.',
            style: CkType.body(
              fontSize: 13,
              color: CkColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load notifications.",
              style: CkType.display(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 12, color: CkColors.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
