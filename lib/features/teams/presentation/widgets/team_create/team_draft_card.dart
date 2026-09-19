import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';

class TeamDraftCard extends StatelessWidget {
  const TeamDraftCard({
    super.key,
    required this.draft,
    required this.onResume,
    required this.onDiscard,
  });

  final Map<String, dynamic> draft;
  final Future<void> Function() onResume;
  final Future<void> Function() onDiscard;

  @override
  Widget build(BuildContext context) {
    final name = (draft['name'] as String? ?? '').trim();
    final step = switch (draft['step']) {
      'review' => 'Review · step 3 of 3',
      'identity' || 'home' || 'crest' => 'Look & location · step 2 of 3',
      _ => 'Team details · step 1 of 3',
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SAVED DRAFT',
            style: CkType.mono(fontSize: 12, color: CkColors.ink2),
          ),
          const SizedBox(height: 8),
          Text(
            name.isEmpty ? 'Your new team' : name,
            style: CkType.display(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(step, style: CkType.body(fontSize: 14, color: CkColors.ink2)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await onResume();
            },
            child: const Text('Resume draft'),
          ),
          TextButton(
            onPressed: () async {
              final discard = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Discard this draft?'),
                  content: const Text(
                    'The details saved for this team will be removed from this device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Keep draft'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );

              if (discard != true || !context.mounted) {
                return;
              }

              await onDiscard();
            },
            child: const Text('Discard draft'),
          ),
        ],
      ),
    );
  }
}
