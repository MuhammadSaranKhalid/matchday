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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(notificationsRepositoryProvider).iconUrl(path);
    final filter = ColorFilter.mode(colorFor(tone), BlendMode.srcIn);
    Widget fallback() => SvgPicture.asset(
      'assets/notification_icons/v1/bell.svg',
      width: 18,
      height: 18,
      colorFilter: filter,
    );
    return ExcludeSemantics(
      child: Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            url == null
                ? fallback()
                : SvgPicture.network(
                  url,
                  width: 18,
                  height: 18,
                  colorFilter: filter,
                  placeholderBuilder: (_) => fallback(),
                  errorBuilder: (_, error, stackTrace) => fallback(),
                ),
      ),
    );
  }
}
