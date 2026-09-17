import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../notifications/presentation/widgets/notification_settings_sheet.dart';
import '../../../safety/presentation/providers/safety_providers.dart';
import 'legal_screen.dart';
import 'legal_content.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool deleting = false;
  String? error;
  void _legal(String doc) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => LegalScreen(document: doc)));
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteConfirmation(),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      deleting = true;
      error = null;
    });
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.deleteAccount();
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        deleting = false;
        error = f.message;
      }),
      (_) => setState(() => deleting = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(blockedAccountsProvider);
    return PopScope(
      canPop: !deleting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: AbsorbPointer(
          absorbing: deleting,
          child: ListView(
            children: [
              if (deleting) const LinearProgressIndicator(),
              if (deleting)
                const ListTile(
                  title: Text('Deleting your account…'),
                  subtitle: Text('Keep the app open until this completes.'),
                ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder:
                          (_) => const FractionallySizedBox(
                            heightFactor: .85,
                            child: NotificationSettingsSheet(),
                          ),
                    ),
              ),
              const Divider(),
              const ListTile(title: Text('Blocked users')),
              ...switch (blocked) {
                AsyncData(:final value) =>
                  value.isEmpty
                      ? [const ListTile(subtitle: Text('No blocked users'))]
                      : value
                          .map(
                            (u) => ListTile(
                              title: Text(u.name),
                              trailing: TextButton(
                                child: const Text('Unblock'),
                                onPressed: () async {
                                  final result = await ref
                                      .read(safetyRepositoryProvider)
                                      .unblock(u.id);
                                  if (!context.mounted) return;
                                  result.fold(
                                    (f) => ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(content: Text(f.message)),
                                    ),
                                    (_) =>
                                        ref.invalidate(blockedAccountsProvider),
                                  );
                                },
                              ),
                            ),
                          )
                          .toList(),
                AsyncError() => [
                  ListTile(
                    title: const Text('Could not load blocked users'),
                    trailing: TextButton(
                      onPressed: () => ref.invalidate(blockedAccountsProvider),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
                _ => [const LinearProgressIndicator()],
              },
              const Divider(),
              ListTile(
                title: const Text('Privacy policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _legal('privacy'),
              ),
              ListTile(
                title: const Text('Terms and community standards'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _legal('terms'),
              ),
              ListTile(
                title: const Text('Support and report a safety concern'),
                subtitle: const Text(supportEmail),
                onTap:
                    () => openLegalLink(
                      context,
                      Uri(scheme: 'mailto', path: supportEmail),
                    ),
              ),
              ListTile(
                title: const Text('Account deletion information'),
                onTap: () => _legal('delete-account'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap:
                    () => ref.read(authControllerProvider.notifier).signOut(),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete account',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text(
                  'Permanently remove your account and personal data',
                ),
                onTap: _delete,
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteConfirmation extends StatefulWidget {
  const _DeleteConfirmation();
  @override
  State<_DeleteConfirmation> createState() => _DeleteConfirmationState();
}

class _DeleteConfirmationState extends State<_DeleteConfirmation> {
  String confirmation = '';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Permanently delete account?'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Your profile, posts, comments and uploaded files will be removed. Your messages become deletion notices. Shared scorecards remain with your identity removed. Teams may transfer to another manager or be archived. This cannot be undone.\n\nType DELETE to confirm.',
          ),
          TextField(
            onChanged: (v) => setState(() => confirmation = v),
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Confirmation'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed:
            confirmation == 'DELETE'
                ? () => Navigator.pop(context, true)
                : null,
        child: const Text('Delete account'),
      ),
    ],
  );
}
