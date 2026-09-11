import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/database/database_provider.dart';
import '../../../../../core/theme/circk_theme.dart';
import '../../controllers/team_create_controller.dart';

final teamCreationDraftProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) =>
    ref.watch(wizardDraftStoreProvider).watch(TeamCreateController.draftKey));

bool hasTeamCreationDraft(Map<String, dynamic>? draft) =>
    (draft?['name'] as String? ?? '').trim().isNotEmpty ||
    (draft?['city'] as String? ?? '').trim().isNotEmpty;

class TeamDraftCard extends ConsumerWidget {
  const TeamDraftCard({super.key, required this.draft});
  final Map<String, dynamic> draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = (draft['name'] as String? ?? '').trim();
    final step = switch (draft['step']) {
      'review' => 'Review · step 3 of 3',
      'identity' || 'home' || 'crest' => 'Look & location · step 2 of 3',
      _ => 'Team details · step 1 of 3',
    };
    return Container(margin: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: CkColors.paper2, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('SAVED DRAFT', style: CkType.mono(fontSize: 12, color: CkColors.ink2)),
        const SizedBox(height: 8),
        Text(name.isEmpty ? 'Your new team' : name,
          style: CkType.display(fontSize: 21, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5), Text(step, style: CkType.body(fontSize: 14, color: CkColors.ink2)),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => context.push('/teams/create'), child: const Text('Resume draft')),
        TextButton(onPressed: () async {
          final discard = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
            title: const Text('Discard this draft?'),
            content: const Text('The details saved for this team will be removed from this device.'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Keep draft')),
              TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Discard'))]));
          if (discard != true || !context.mounted) return;
          await ref.read(wizardDraftStoreProvider).clear(TeamCreateController.draftKey);
          ref.invalidate(teamCreateControllerProvider);
        }, child: const Text('Discard draft')),
      ]));
  }
}
