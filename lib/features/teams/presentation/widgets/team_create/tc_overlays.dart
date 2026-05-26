import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';

/// Save & exit bottom sheet (Guard B from the design source).
/// Three actions: save draft + exit, keep going, discard.
Future<void> showSaveExitSheet(
  BuildContext context, {
  required int step,
  required int totalSteps,
  required VoidCallback onSaveAndExit,
  required VoidCallback onDiscard,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SheetShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Grab(),
            const SizedBox(height: 12),
            Text(
              'Save your draft?',
              style: CkType.display(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You're on step $step of $totalSteps. We'll keep your draft "
              'under Pavilion → Drafts so you can pick up where you left off.',
              style: CkType.body(
                  fontSize: 13, color: CkColors.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            _SheetBtn(
              label: 'Save draft & exit',
              primary: true,
              onTap: () {
                Navigator.of(context).pop();
                onSaveAndExit();
              },
            ),
            const SizedBox(height: 8),
            _SheetBtn(
              label: 'Keep going',
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onDiscard();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    'Discard changes',
                    style: CkType.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CkColors.red,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Ownership briefing bottom sheet (Guard C).
/// Tabular capability list — what owners can do that members/managers can't.
Future<void> showOwnershipSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SheetShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Grab(),
            const SizedBox(height: 12),
            Text(
              "What it means to own a team",
              style: CkType.display(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A quick rundown of what you can do — and what you share with '
              'co-managers and players.',
              style: CkType.body(
                  fontSize: 13, color: CkColors.muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            const _CapabilityHeader(),
            const _CapRow(
              label: 'Edit team profile',
              owner: true,
              manager: true,
              player: false,
            ),
            const _CapRow(
              label: 'Add & remove players',
              owner: true,
              manager: true,
              player: false,
            ),
            const _CapRow(
              label: 'Score matches',
              owner: true,
              manager: true,
              player: false,
            ),
            const _CapRow(
              label: 'Approve join requests',
              owner: true,
              manager: true,
              player: false,
            ),
            const _CapRow(
              label: 'Transfer ownership',
              owner: true,
              manager: false,
              player: false,
              irreversible: true,
            ),
            const _CapRow(
              label: 'Delete the team',
              owner: true,
              manager: false,
              player: false,
              irreversible: true,
            ),
            const SizedBox(height: 18),
            _SheetBtn(
              label: 'Got it',
              primary: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CapabilityHeader extends StatelessWidget {
  const _CapabilityHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: SizedBox.shrink()),
          _HeaderCell('OWNER'),
          _HeaderCell('MANAGER'),
          _HeaderCell('PLAYER'),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Center(
        child: Text(
          label,
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: CkColors.muted,
          ),
        ),
      ),
    );
  }
}

class _CapRow extends StatelessWidget {
  const _CapRow({
    required this.label,
    required this.owner,
    required this.manager,
    required this.player,
    this.irreversible = false,
  });
  final String label;
  final bool owner;
  final bool manager;
  final bool player;
  final bool irreversible;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: CkType.body(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                if (irreversible) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Irreversible',
                    style: CkType.mono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: CkColors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _CapCell(value: owner),
          _CapCell(value: manager),
          _CapCell(value: player),
        ],
      ),
    );
  }
}

class _CapCell extends StatelessWidget {
  const _CapCell({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Center(
        child: Icon(
          value ? Icons.check_rounded : Icons.remove,
          size: 16,
          color: value ? CkColors.green : CkColors.muted,
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _Grab extends StatelessWidget {
  const _Grab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: CkColors.line,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _SheetBtn extends StatelessWidget {
  const _SheetBtn({
    required this.label,
    this.primary = false,
    required this.onTap,
  });
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: CkColors.hairline),
        ),
        child: Text(
          label,
          style: CkType.body(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: primary ? CkColors.paper : CkColors.ink,
          ),
        ),
      ),
    );
  }
}
