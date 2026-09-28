import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../providers/notifications_providers.dart';

class NotificationSettingsSheet extends ConsumerStatefulWidget {
  const NotificationSettingsSheet({super.key});
  @override
  ConsumerState<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends ConsumerState<NotificationSettingsSheet> {
  bool _saving = false;
  Future<void> _set(String category, String channel, bool value) async {
    setState(() => _saving = true);
    final result = await ref
        .read(notificationsRepositoryProvider)
        .setPreference(category, channel, value);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => ref.invalidate(notificationSettingsProvider),
    );
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: ref
          .watch(notificationSettingsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (_, st) => Center(
                  child: TextButton(
                    onPressed:
                        () => ref.invalidate(notificationSettingsProvider),
                    child: const Text('Retry notification settings'),
                  ),
                ),
            data:
                (settings) => ListView(
                  children: [
                    Text(
                      'Notification settings',
                      style: CkType.display(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Turning off inbox notifications also stops their pushes. Required account notices remain enabled.',
                    ),
                    const SizedBox(height: 16),
                    for (final s in settings) ...[
                      Text(
                        s.name,
                        style: CkType.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        s.description,
                        style: CkType.body(fontSize: 12, color: CkColors.ink2),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('In inbox'),
                        value: s.inapp,
                        onChanged:
                            _saving
                                ? null
                                : (v) => _set(s.category, 'inapp', v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Push notifications'),
                        value: s.push,
                        onChanged:
                            _saving || !s.inapp
                                ? null
                                : (v) => _set(s.category, 'push', v),
                      ),
                      const Divider(),
                    ],
                  ],
                ),
          ),
    ),
  );
}
