import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';

/// Artboard 26 — locking the draw.
///
/// The third and strongest of the feature's escalating confirms. Publish (21b)
/// is a plain ink dialog because it is reversible. This one cannot be undone,
/// so it earns a cream warning block, an explicit consequence list and a
/// gating checkbox — but the confirm button **stays ink**. Red would say
/// "danger"; this is "final". Cancelling a tournament (27g) is the one that
/// gets red.
Future<bool?> showLockDrawDialog(
  BuildContext context, {
  required int teamCount,
  required int playerCount,
  required bool hasWaitlist,
  required int fixtureCount,
  required int roundCount,
  DateTime? lastDate,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: CkColors.ink.withValues(alpha: 0.32),
    builder: (_) => _LockDrawDialog(
      teamCount: teamCount,
      playerCount: playerCount,
      hasWaitlist: hasWaitlist,
      fixtureCount: fixtureCount,
      roundCount: roundCount,
      lastDate: lastDate,
    ),
  );
}

class _LockDrawDialog extends StatefulWidget {
  const _LockDrawDialog({
    required this.teamCount,
    required this.playerCount,
    required this.hasWaitlist,
    required this.fixtureCount,
    required this.roundCount,
    this.lastDate,
  });

  final int teamCount;
  final int playerCount;
  final bool hasWaitlist;

  /// The size of the draw about to be published. Named here because this is
  /// the last screen before it becomes permanent.
  final int fixtureCount;
  final int roundCount;
  final DateTime? lastDate;

  @override
  State<_LockDrawDialog> createState() => _LockDrawDialogState();
}

class _LockDrawDialogState extends State<_LockDrawDialog> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CkColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CkRadii.md),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CANNOT BE UNDONE',
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.amberDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lock the draw and publish fixtures?',
            style: CkType.display(fontSize: 19, height: 1.25),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seeds become permanent and the bracket is generated. You will '
              'not be able to add, remove or reorder teams afterwards.',
              style: CkType.body(
                fontSize: 12.5,
                height: 1.55,
                color: CkColors.ink2,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: CkColors.cream,
                borderRadius: BorderRadius.circular(CkRadii.sm),
                border: Border.all(color: CkColors.creamBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Consequence(
                    'All ${widget.teamCount} team managers and '
                    '${widget.playerCount} squad players are notified',
                  ),
                  _Consequence(
                    widget.hasWaitlist
                        ? 'Registration closes immediately — the waitlist is '
                            'discarded'
                        : 'Registration closes immediately',
                  ),
                  _Consequence(
                    '${widget.fixtureCount} fixture'
                    '${widget.fixtureCount == 1 ? '' : 's'} across '
                    '${widget.roundCount} round'
                    '${widget.roundCount == 1 ? '' : 's'} are created'
                    '${widget.lastDate == null ? '' : ', finishing '
                        '${DateFormat('d MMM').format(widget.lastDate!)}'}',
                  ),
                  const _Consequence(
                    'Times and grounds stay editable per match',
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // The checkbox gates the confirm; unchecked it renders paper2 with
            // a soft label — the same inert treatment as the wizard's step 4.
            InkWell(
              onTap: () => setState(() => _checked = !_checked),
              borderRadius: BorderRadius.circular(CkRadii.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _checked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: _checked ? CkColors.ink : CkColors.soft,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'I have checked the seeds and confirmed all payments',
                        style: CkType.body(
                          fontSize: 12.5,
                          height: 1.45,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: CkColors.ink2),
          child: Text(
            'Cancel',
            style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: _checked ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: CkColors.ink,
            disabledBackgroundColor: CkColors.paper2,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CkRadii.sm),
            ),
          ),
          child: Text(
            'Lock & Publish',
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _checked ? CkColors.paper : CkColors.soft,
            ),
          ),
        ),
      ],
    );
  }
}

class _Consequence extends StatelessWidget {
  const _Consequence(this.text, {this.last = false});

  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.remove, size: 13, color: CkColors.amberDark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: CkType.body(
                fontSize: 12,
                height: 1.45,
                color: CkColors.amberDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
