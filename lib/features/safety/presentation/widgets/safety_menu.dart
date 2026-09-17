import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/safety_providers.dart';

class SafetyMenu extends ConsumerWidget {
  const SafetyMenu({super.key, required this.userId, required this.kind, required this.targetId, this.onShare});
  final String userId;
  final String kind;
  final String targetId;
  final VoidCallback? onShare;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final self = ref.watch(currentUserStreamProvider).value?.id.value == userId;
    final blocked = ref.watch(blockedAccountsProvider).value?.any((u) => u.id == userId) ?? false;
    return PopupMenuButton<String>(
      tooltip: 'Safety and options',
      icon: const Icon(Icons.more_horiz),
      itemBuilder: (_) => [
        if (onShare != null) const PopupMenuItem(value: 'share', child: Text('Share')),
        if (!self) PopupMenuItem(value: 'report', child: Text('Report $kind')),
        if (!self && kind != 'user') const PopupMenuItem(value: 'user', child: Text('Report user')),
        if (!self) PopupMenuItem(value: 'block', child: Text(blocked ? 'Unblock user' : 'Block user')),
      ],
      onSelected: (action) async {
        if (action == 'share') { onShare?.call(); return; }
        if (action == 'report' || action == 'user') {
          await showDialog<void>(context: context, builder: (_) => _ReportDialog(kind: action == 'user' ? 'user' : kind, targetId: action == 'user' ? userId : targetId));
          return;
        }
        final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: Text(blocked ? 'Unblock this player?' : 'Block this player?'),
          content: Text(blocked ? 'Their content will be visible again and direct messaging will be available.' : 'Their posts and messages will be hidden from you. Direct messages, follows and comments on each other’s posts will be blocked. Shared match records remain visible.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(blocked ? 'Unblock' : 'Block'))],
        ));
        if (confirmed != true || !context.mounted) return;
        final repo = ref.read(safetyRepositoryProvider);
        final result = blocked ? await repo.unblock(userId) : await repo.block(userId);
        if (!context.mounted) return;
        result.fold((f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))), (_) {
          ref.invalidate(blockedAccountsProvider);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked ? 'Player unblocked' : 'Player blocked')));
        });
      },
    );
  }
}
class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog({required this.kind, required this.targetId});
  final String kind;
  final String targetId;
  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}
class _ReportDialogState extends ConsumerState<_ReportDialog> {
  final details = TextEditingController();
  String reason = 'Spam';
  bool saving = false;
  String? error;
  @override
  void dispose() { details.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Report ${widget.kind}'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Reports are sent privately to Matchday moderation. For immediate danger, contact local emergency services.'),
      DropdownButtonFormField<String>(initialValue: reason, isExpanded: true, items: const ['Spam','Harassment or bullying','Hate or violence','Sexual content','Child safety','Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: saving ? null : (v) => setState(() => reason = v!)),
      TextField(controller: details, maxLength: 2000, maxLines: 3, enabled: !saving, decoration: const InputDecoration(labelText: 'Details (optional)')),
      if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ])),
    actions: [TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: saving ? null : () async {
      setState(() { saving = true; error = null; });
      final result = await ref.read(safetyRepositoryProvider).report(kind: widget.kind, targetId: widget.targetId, reason: reason, details: details.text);
      if (!mounted) return;
      result.fold((f) => setState(() { saving = false; error = f.message; }), (_) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report received. Thank you.'))); });
    }, child: Text(saving ? 'Sending…' : 'Send report'))],
  );
}
