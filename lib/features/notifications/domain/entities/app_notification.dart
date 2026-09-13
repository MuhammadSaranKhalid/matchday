import 'package:equatable/equatable.dart';

/// One in-app notification. Mirrors `public.notifications` 1:1.
///
/// **There is deliberately no `NotificationType` enum any more.** It was
/// removed on 2026-09-12 along with the Postgres enum it mirrored, because the
/// pair made the client the bottleneck on the server: the Dart enum carried 14
/// of the 20 server values, and `fromWire` fell back to
/// `NotificationType.follow`, so any type the app didn't know rendered as
/// "someone followed you" and deep-linked to a profile. The server could not
/// send a new notification type until every user had updated.
///
/// [typeKey] is now an opaque hierarchical string (`team.join.requested`) and
/// the row carries its own rendered [title], [body], [route], [icon] and
/// [tier]. A build shipped today renders a type invented next month correctly,
/// because rendering reads the row rather than switching on a closed set.
///
/// Switch on [typeKey] ONLY to add richer affordances on top (the challenge
/// row's sender crest and expiry pill), never to produce basic copy — and
/// always with a default branch.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.typeKey,
    required this.title,
    required this.body,
    required this.tier,
    required this.icon,
    this.iconPath,
    this.tone = 'neutral',
    required this.isRead,
    required this.createdAt,
    this.route,
    this.actorId,
    this.entityScope,
    this.entityId,
    this.groupCount = 1,
    this.payload = const <String, dynamic>{},
  });

  final NotificationId id;
  final String recipientId;

  /// Hierarchical catalogue key, e.g. `match.challenge.received`. Opaque to the
  /// client — treat it as an identifier, not a closed set.
  final String typeKey;

  /// Server-rendered copy. Already interpolated; display verbatim.
  final String title;
  final String body;

  /// Deep link, or null when the type has no destination (the client falls
  /// back to the notifications inbox).
  final String? route;

  final NotificationTier tier;

  /// Presentation token (`heart`, `trophy`, `bat`…), mapped to an icon with a
  /// default so an unrecognised token degrades rather than throwing.
  final String icon;
  final String? iconPath;
  final String tone;

  final String? actorId;
  final String? entityScope;
  final String? entityId;

  /// How many events folded into this row. 1 = a single event.
  final int groupCount;

  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;

  /// Top-level catalogue category — the key's first segment
  /// (`match`, `team`, `tournament`, `chat`, `social`, `system`).
  String get category {
    final i = typeKey.indexOf('.');
    return i == -1 ? typeKey : typeKey.substring(0, i);
  }

  /// Promotes to the urgent (red bar) styling. Previously an explicit list of
  /// two enum values; both were `now`-tier, so the tier carries it and the
  /// decision moved to the catalogue where it is editable without a release.
  bool get isUrgent => tier == NotificationTier.now;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    recipientId: recipientId,
    typeKey: typeKey,
    title: title,
    body: body,
    route: route,
    tier: tier,
    icon: icon,
    iconPath: iconPath,
    tone: tone,
    actorId: actorId,
    entityScope: entityScope,
    entityId: entityId,
    groupCount: groupCount,
    payload: payload,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    route,
    tier,
    iconPath,
    tone,
    isRead,
    groupCount,
    createdAt,
  ];
}

class NotificationId extends Equatable {
  const NotificationId(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
  @override
  String toString() => value;
}

/// The design's three-tier inbox model. Server-supplied (copied onto the row
/// from `notification_types.tier`) rather than derived from the type, so
/// re-tiering a notification is a catalogue UPDATE, not an app release.
enum NotificationTier {
  /// Reply now — needs immediate action.
  now('now'),

  /// This week — soft deadline.
  week('week'),

  /// FYI — celebrate, file away.
  fyi('fyi');

  const NotificationTier(this.wire);
  final String wire;

  /// Unknown values fall back to [fyi] — the least intrusive tier. A new tier
  /// added server-side must never promote itself into the urgent bar on a
  /// client that has never heard of it.
  static NotificationTier fromWire(String? w) =>
      values.where((t) => t.wire == w).firstOrNull ?? NotificationTier.fyi;
}

/// Platform the device token came from. Mirrors the loose `text` column in
/// `device_tokens.platform`.
enum DevicePlatform {
  ios('ios'),
  android('android');

  const DevicePlatform(this.wire);
  final String wire;
}

/// A bounded inbox window; badge count includes unread rows outside this window.
class NotificationFeed {
  const NotificationFeed({
    this.items = const [],
    this.unreadCount = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });
  final List<AppNotification> items;
  final int unreadCount;
  final bool hasMore;
  final bool loadingMore;
}

class NotificationSetting {
  const NotificationSetting({
    required this.category,
    required this.name,
    required this.description,
    required this.inapp,
    required this.push,
  });
  final String category;
  final String name;
  final String description;
  final bool inapp;
  final bool push;
}
