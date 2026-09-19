import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/ck_toast.dart';
import '../../controllers/team_page_controller.dart';

void showTeamJoinRequestSheet(
  BuildContext context, {
  required String teamId,
  required String teamName,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CkColors.paper,
    barrierColor: CkColors.ink.withValues(alpha: 0.42),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CkRadii.lg)),
    ),
    builder: (_) => _JoinRequestSheet(teamId: teamId, teamName: teamName),
  );
}

class _JoinRequestSheet extends ConsumerStatefulWidget {
  const _JoinRequestSheet({required this.teamId, required this.teamName});
  final String teamId;
  final String teamName;

  @override
  ConsumerState<_JoinRequestSheet> createState() => _JoinRequestSheetState();
}

class _JoinRequestSheetState extends ConsumerState<_JoinRequestSheet> {
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    final note = _message.text.trim();
    final error = await ref
        .read(teamPageControllerProvider(widget.teamId).notifier)
        .requestToJoin(message: note.isEmpty ? null : note);
    if (!mounted) return;
    final pageContext = Navigator.of(context).context;
    Navigator.of(context).pop();
    if (!pageContext.mounted) return;
    CkToast.show(
      pageContext,
      message: error ?? 'Request sent to the ${widget.teamName} managers',
      isError: error != null,
      icon: error == null ? Icons.person_add_alt : null,
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CkColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Join ${widget.teamName}',
              style: CkType.display(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Send a join request to the team managers.',
              style: CkType.body(fontSize: 12.5, color: CkColors.muted),
            ),
            const SizedBox(height: 16),
            Text(
              'NOTE / MESSAGE (OPTIONAL)',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _message,
              maxLines: 3,
              style: CkType.body(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Right-arm fast bowler, available on weekends...',
                hintStyle: const TextStyle(fontSize: 12.5, color: CkColors.muted),
                filled: true,
                fillColor: CkColors.paper2,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: CkColors.hairline),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CkColors.ink,
                  foregroundColor: CkColors.paper,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CkColors.paper,
                        ),
                      )
                    : const Text(
                        'Send Request',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
}
