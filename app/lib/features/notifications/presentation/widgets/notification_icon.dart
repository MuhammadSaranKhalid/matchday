import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/circk_theme.dart';
import '../providers/notifications_providers.dart';

/// Asset identity and semantic color are independent server-supplied values.
class NotificationIcon extends ConsumerWidget {
  const NotificationIcon({super.key, required this.path, required this.tone});
  final String? path;
  final String tone;

  static Color colorFor(String tone) => switch (tone) {
    'brand' || 'danger' => CkColors.redInk,
    'success' => CkColors.greenInk,
    'warning' || 'achievement' => CkColors.amberInk,
    _ => CkColors.ink2,
  };

  static const Set<String> _bundledPaths = {
    'v1/at.svg',
    'v1/bell.svg',
    'v1/calendar-event.svg',
    'v1/circle-check.svg',
    'v1/circle-x.svg',
    'v1/cricket.svg',
    'v1/heart.svg',
    'v1/message-circle.svg',
    'v1/messages.svg',
    'v1/shield-check.svg',
    'v1/star.svg',
    'v1/trophy.svg',
    'v1/user-plus.svg',
    'v1/users-group.svg',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ColorFilter.mode(colorFor(tone), BlendMode.srcIn);
    Widget fallback() => SvgPicture.asset(
      'assets/notification_icons/v1/bell.svg',
      width: 18,
      height: 18,
      colorFilter: filter,
    );

    Widget iconWidget;
    if (path != null && _bundledPaths.contains(path)) {
      iconWidget = SvgPicture.asset(
        'assets/notification_icons/$path',
        width: 18,
        height: 18,
        colorFilter: filter,
      );
    } else {
      final url = ref.watch(notificationsRepositoryProvider).iconUrl(path);
      iconWidget =
          url == null
              ? fallback()
              : SvgPicture.network(
                url,
                width: 18,
                height: 18,
                colorFilter: filter,
                placeholderBuilder: (_) => fallback(),
                errorBuilder: (_, error, stackTrace) => fallback(),
              );
    }

    return ExcludeSemantics(
      child: Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: iconWidget,
      ),
    );
  }
}
