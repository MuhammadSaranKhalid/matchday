import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';

/// Artboard 27g — the one genuinely red confirm in the feature.
///
/// Three escalating confirm patterns exist and the difference is deliberate:
/// Publish is a plain ink dialog because it is reversible; Lock & Publish adds
/// a cream consequence list because it is permanent but benign; Cancel adds
/// red, a typed name and a public reason because it destroys something people
/// are relying on.
///
/// Returns the reason when confirmed, or null when the organiser keeps it.
Future<String?> showCancelTournamentDialog(
  BuildContext context, {
  required Tournament tournament,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CancelTournamentDialog(tournament: tournament),
  );
}

class _CancelTournamentDialog extends StatefulWidget {
  const _CancelTournamentDialog({required this.tournament});

  final Tournament tournament;

  @override
  State<_CancelTournamentDialog> createState() =>
      _CancelTournamentDialogState();
}

class _CancelTournamentDialogState extends State<_CancelTournamentDialog> {
  final _reason = TextEditingController();
  final _confirmName = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reason.addListener(_onChanged);
    _confirmName.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _reason.dispose();
    _confirmName.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _reason.text.trim().length >= 10 &&
      _confirmName.text.trim().toLowerCase() ==
          widget.tournament.name.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final fee = t.entryFee ?? 0;
    final teams = t.approvedTeamsCount;

    return AlertDialog(
      backgroundColor: CkColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CkRadii.lg),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DESTROYS A LIVE TOURNAMENT',
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.redInk,
            ),
          ),
          const SizedBox(height: 6),
          Text('Cancel ${t.name}?', style: CkType.display(fontSize: 19)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'All registered teams, their players and every follower are '
              'notified immediately. Completed scorecards are kept and stay '
              'visible, but no further matches can be played.',
              style: CkType.body(
                fontSize: 12.5,
                height: 1.55,
                color: CkColors.ink2,
              ),
            ),
            const SizedBox(height: 14),
            const _Consequence('Unplayed fixtures are voided'),
            if (fee > 0)
              _Consequence(
                'You are responsible for refunding the '
                '${NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0).format(fee * teams)} '
                'collected in fees',
              ),
            const _Consequence(
              'The cup cannot be reopened — you would create a new one',
            ),
            const SizedBox(height: 16),
            Text(
              'REASON · SHOWN TO EVERYONE',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reason,
              maxLines: 3,
              style: CkType.body(fontSize: 13),
              decoration: _dec(
                'Ground flooded, no replacement venue available.',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'TYPE THE TOURNAMENT NAME TO CONFIRM',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmName,
              style: CkType.body(fontSize: 13),
              decoration: _dec(t.name),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: CkColors.ink),
          child: Text(
            'Keep it',
            style: CkType.display(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: _canConfirm
              ? () => Navigator.pop(context, _reason.text.trim())
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: CkColors.red,
            disabledBackgroundColor: CkColors.soft,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CkRadii.sm),
            ),
          ),
          child: Text(
            'Cancel Tournament',
            style: CkType.display(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: CkType.body(fontSize: 13, color: CkColors.soft),
        filled: true,
        fillColor: CkColors.paper,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CkRadii.sm),
          borderSide: const BorderSide(color: CkColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CkRadii.sm),
          borderSide: const BorderSide(color: CkColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CkRadii.sm),
          borderSide: const BorderSide(color: CkColors.ink, width: 1.5),
        ),
      );
}

class _Consequence extends StatelessWidget {
  const _Consequence(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.remove, size: 14, color: CkColors.redInk),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: CkType.body(
                fontSize: 12,
                height: 1.45,
                color: CkColors.redInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Artboard 27i · the cancelled console ────────────────────────────────────

/// A cancelled cup keeps its tabs hidden — there is nothing left to manage, so
/// the screen is a record rather than a workspace.
class CancelledConsoleView extends StatelessWidget {
  const CancelledConsoleView({super.key, required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final reason = tournament.rules['cancelled_reason'] as String?;
    final cancelledAtRaw = tournament.rules['cancelled_at'];
    final cancelledAt = cancelledAtRaw is String
        ? DateTime.tryParse(cancelledAtRaw)?.toLocal()
        : null;
    final fee = tournament.entryFee ?? 0;
    final collected = fee * tournament.approvedTeamsCount;

    return Scaffold(
      backgroundColor: CkColors.paper,
      appBar: AppBar(
        backgroundColor: CkColors.paper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CkColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage', style: CkType.display(fontSize: 17)),
            Text(
              tournament.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 12, color: CkColors.muted),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CkColors.redSurface,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.redBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CANCELLED',
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                    color: CkColors.redInk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This tournament was cancelled',
                  style: CkType.display(fontSize: 17),
                ),
                if (cancelledAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    DateFormat("d MMM yyyy, h:mm a").format(cancelledAt),
                    style: CkType.body(fontSize: 11.5, color: CkColors.ink2),
                  ),
                ],
              ],
            ),
          ),
          if (reason != null) ...[
            const SizedBox(height: 16),
            Text(
              'REASON GIVEN',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '“$reason”',
              style: CkType.body(
                fontSize: 13.5,
                height: 1.55,
                color: CkColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Shown to every manager, player and follower.',
              style: CkType.body(fontSize: 11.5, color: CkColors.muted),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'WHAT WAS KEPT',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12,
            ),
          ),
          const SizedBox(height: 8),
          const _KeptRow(
            title: 'Completed scorecards',
            subtitle: 'Still visible · count towards player stats',
          ),
          const _KeptRow(
            title: 'Unplayed fixtures voided',
            subtitle: 'No result recorded for either side',
          ),
          if (collected > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                // Cream rather than red: the obligation is real but it is not
                // an emergency, and naming the amount saves the organiser the
                // arithmetic.
                color: CkColors.cream,
                borderRadius: BorderRadius.circular(CkRadii.md),
                border: Border.all(color: CkColors.creamBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REFUNDS ARE YOURS TO SETTLE',
                    style: CkType.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.10,
                      color: CkColors.amberDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'matchday never held the money. '
                    '${NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0).format(collected)} '
                    'was collected from ${tournament.approvedTeamsCount} teams '
                    'offline — return it the same way you took it.',
                    style: CkType.body(
                      fontSize: 12.5,
                      height: 1.5,
                      color: CkColors.amberDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CkColors.paper,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try again later in the season?',
                  style: CkType.display(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'A cancelled cup cannot reopen, but you can duplicate its '
                  'format, rules and venues into a fresh draft.',
                  style: CkType.body(
                    fontSize: 12.5,
                    height: 1.5,
                    color: CkColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push(
                    '/tournaments/create?duplicateOf=${tournament.id}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CkColors.ink,
                    side: const BorderSide(color: CkColors.line),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CkRadii.sm),
                    ),
                  ),
                  child: Text(
                    'Duplicate as a new draft',
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeptRow extends StatelessWidget {
  const _KeptRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: CkType.display(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
          ),
        ],
      ),
    );
  }
}
