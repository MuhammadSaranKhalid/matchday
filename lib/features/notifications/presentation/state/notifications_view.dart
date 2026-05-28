import 'package:flutter/foundation.dart';

import '../../domain/entities/app_notification.dart';

/// Tier-grouped view of the user's notifications. Passive struct (Pattern 3
/// per CLAUDE.md §5.3) — the controller composes it from the live broadcast
/// stream.
@immutable
class NotificationsView {
  const NotificationsView({
    required this.now,
    required this.week,
    required this.fyi,
    required this.unreadCount,
  });

  const NotificationsView.empty()
      : now = const [],
        week = const [],
        fyi = const [],
        unreadCount = 0;

  final List<AppNotification> now;
  final List<AppNotification> week;
  final List<AppNotification> fyi;
  final int unreadCount;

  bool get isEmpty => now.isEmpty && week.isEmpty && fyi.isEmpty;
  int get total => now.length + week.length + fyi.length;

  factory NotificationsView.from(List<AppNotification> all) {
    final now = <AppNotification>[];
    final week = <AppNotification>[];
    final fyi = <AppNotification>[];
    var unread = 0;
    for (final n in all) {
      if (!n.isRead) unread++;
      switch (n.tier) {
        case NotificationTier.now:
          now.add(n);
        case NotificationTier.week:
          week.add(n);
        case NotificationTier.fyi:
          fyi.add(n);
      }
    }
    return NotificationsView(
      now: now,
      week: week,
      fyi: fyi,
      unreadCount: unread,
    );
  }
}
