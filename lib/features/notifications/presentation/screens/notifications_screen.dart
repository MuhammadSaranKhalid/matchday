import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/error/failures.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';
import '../state/notifications_view.dart';
import '../widgets/notification_icon.dart';
import '../widgets/notifications_shimmer_skeleton.dart';

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
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: async.when(
                loading: () => const NotificationsShimmerSkeleton(),
                error:
                    (e, _) => _Error(
                      message:
                          e is FailureWrapper
                              ? e.failure.message
                              : e.toString(),
                      onRetry: () => ref.invalidate(liveNotificationsProvider),
                    ),
                data:
                    (_) =>
                        view.isEmpty
                            ? const _Empty()
                            : _Body(
                              view: view,
                              onTap: (n) => _onTap(context, ref, n),
                              hasMore: async.value?.hasMore ?? false,
                              loadingMore: async.value?.loadingMore ?? false,
                              onLoadMore:
                                  () =>
                                      ref
                                          .read(notificationsRepositoryProvider)
                                          .loadMore(),
                            ),
              ),
            ),
          ],
        ),
      ),
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
      ref.read(notificationsRepositoryProvider).markRead(n.id);
    }
    final route = _routeFor(n);
    if (route != null &&
        !GoRouter.of(
          context,
        ).configuration.findMatch(Uri.parse(route)).isError) {
      context.push(route);
    }
  }

  /// The row carries its own deep link, rendered server-side from the
  /// catalogue's route_template. A null route (or one this build's router does
  /// not recognise) must fail SOFT — stay on the inbox, never crash — which is
  /// what lets a notification type invented after this release still open
  /// somewhere sensible.
  String? _routeFor(AppNotification n) {
    final route = n.route;
    if (route == null || route.isEmpty) return null;
    return route.startsWith('/') ? route : null;
  }
}

// ─── Layout ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // Same chrome as every other pushed page (see Challenges): circular back
    // affordance, display title, hairline rule. No counts, no actions — the
    // tier heads below already say what needs you.
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap:
                () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: CkColors.paper2,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 17,
                  color: CkColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications',
              style: CkType.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02,
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
  const _Body({
    required this.view,
    required this.onTap,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;
  final NotificationsView view;
  final void Function(AppNotification) onTap;

  @override
  Widget build(BuildContext context) {
    Widget rowFor(AppNotification n) {
      // The only place a type key is inspected: a richer row (sender
      // crest, bold team name, expiry pill). Everything else renders
      // straight from the row.
      if (n.typeKey == 'match.challenge.received') {
        return _MatchRequestRow(n: n, onTap: () => onTap(n));
      }
      return _Row(n: n, onTap: () => onTap(n));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (view.now.isNotEmpty) ...[
          const _TierHead(label: 'REPLY NOW', tone: _TierTone.red),
          for (final n in view.now) rowFor(n),
        ],
        if (view.week.isNotEmpty) ...[
          const _TierHead(label: 'THIS WEEK', tone: _TierTone.amber),
          for (final n in view.week) rowFor(n),
        ],
        if (view.fyi.isNotEmpty) ...[
          const _TierHead(label: 'FYI', tone: _TierTone.muted),
          for (final n in view.fyi) rowFor(n),
        ],
        const SizedBox(height: 24),
        if (hasMore)
          TextButton(
            onPressed: loadingMore ? null : onLoadMore,
            child: Text(loadingMore ? 'Loading…' : 'Load older notifications'),
          )
        else
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
      _TierTone.amber => CkColors.amberInk,
      _TierTone.muted => CkColors.muted,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
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
                color:
                    unread
                        ? (n.isUrgent ? CkColors.red : CkColors.ink2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            NotificationIcon(path: n.iconPath, tone: n.tone),
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
                          n.title,
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
                  if (n.body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        n.body,
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

  static String _shortTime(DateTime t) {
    final delta = DateTime.now().difference(t);
    if (delta.inMinutes < 1) return 'now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m';
    if (delta.inHours < 24) return '${delta.inHours}h';
    if (delta.inDays < 7) {
      return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday -
          1];
    }
    return timeago.format(t, locale: 'en_short');
  }
}

/// Faithful port of the `match-request` row from the Notification Flow
/// design (notification-flow/nf-shared.jsx + 04-InboxActive.jsx). Renders:
///
/// * 3px left unread stripe — red because match_request is urgent.
/// * 32×32 sender team crest (mono on team.primaryColor).
/// * Body line with the sender team name bolded, e.g.
///   "**Lahore Lions** challenged you to a friendly".
/// * Tier-label pill ("MATCH REQUEST · expires 23h") computed from the
///   request's 48h window (created_at).
///
/// The row carries no inline actions — accept / counter / decline all need
/// confirmation (a confirm sheet, a reason picker), so tapping the row opens
/// the challenge detail screen where those already live.
class _MatchRequestRow extends ConsumerWidget {
  const _MatchRequestRow({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  String get _requestId => (n.payload['request_id'] as String?) ?? '';
  String get _fromTeamId => (n.payload['from_team_id'] as String?) ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTeams = ref.watch(allTeamsProvider).value ?? const <Team>[];
    final fromTeam = allTeams.cast<Team?>().firstWhere(
      (t) => t!.id.value == _fromTeamId,
      orElse: () => null,
    );

    final unread = !n.isRead;
    return InkWell(
      onTap: _requestId.isEmpty ? null : onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 13, 18, 13),
        decoration: const BoxDecoration(
          color: CkColors.paper,
          border: Border(top: BorderSide(color: CkColors.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread stripe (red — match_request is always urgent).
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                color: unread ? CkColors.red : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _TeamCrest(team: fromTeam),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Body line + timestamp.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _BoldBody(
                          before: '',
                          bold: fromTeam?.name ?? 'A team',
                          after: ' challenged you to a friendly',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _shortAgo(n.createdAt),
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                  if (n.body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        n.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.body(
                          fontSize: 11.5,
                          color: CkColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  // Tier label gets its own line — "MATCH REQUEST ·
                  // expires 23h" is too long to share one with the
                  // timestamp.
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'MATCH REQUEST · EXPIRES ${_expiresInLabel(n.createdAt).toUpperCase()}',
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
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
    );
  }

  static String _expiresInLabel(DateTime createdAt) {
    // Challenge proposal expires 48h after send (see migration 0615).
    final remaining = createdAt
        .add(const Duration(hours: 48))
        .difference(DateTime.now());
    if (remaining.isNegative) return 'expired';
    if (remaining.inHours < 1) return '${remaining.inMinutes}m';
    if (remaining.inHours < 24) return '${remaining.inHours}h';
    return '${remaining.inDays}d';
  }

  static String _shortAgo(DateTime t) {
    final delta = DateTime.now().difference(t);
    if (delta.inMinutes < 1) return 'now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m';
    if (delta.inHours < 24) return '${delta.inHours}h';
    if (delta.inDays < 7) {
      return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday -
          1];
    }
    return '${t.day}/${t.month}';
  }
}

/// Rich-text body line — `<before><bold-span><after>` baked into a single
/// TextSpan tree so it lays out as one paragraph.
class _BoldBody extends StatelessWidget {
  const _BoldBody({
    required this.before,
    required this.bold,
    required this.after,
  });
  final String before;
  final String bold;
  final String after;

  @override
  Widget build(BuildContext context) {
    final base = CkType.body(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: bold,
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 32×32 crest tile — mono on the team's primary colour. Falls back to a
/// neutral muted tile when the team isn't in the local teams cache yet.
class _TeamCrest extends StatelessWidget {
  const _TeamCrest({required this.team});
  final Team? team;

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(team?.primaryColor) ?? CkColors.muted;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        _short(team),
        style: CkType.display(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: CkColors.paper,
        ),
      ),
    );
  }

  static String _short(Team? t) {
    if (t == null) return '??';
    final mono = t.logoMonogram;
    if (mono != null && mono.isNotEmpty) return mono.toUpperCase();
    final words =
        t.name
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .take(2)
            .toList();
    if (words.isEmpty) return '??';
    return words.map((w) => w[0]).join().toUpperCase();
  }

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final c = hex.replaceAll('#', '').trim();
    if (c.length == 6) {
      final n = int.tryParse(c, radix: 16);
      if (n != null) return Color(0xFF000000 | n);
    } else if (c.length == 8) {
      final n = int.tryParse(c, radix: 16);
      if (n != null) return Color(n);
    }
    return null;
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
            child: const Icon(
              Icons.notifications_none,
              size: 32,
              color: CkColors.muted,
            ),
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
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
