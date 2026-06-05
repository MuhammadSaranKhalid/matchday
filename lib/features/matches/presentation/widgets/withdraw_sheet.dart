import 'package:flutter/material.dart';

import '../../../../core/theme/circk_theme.dart';

/// Result of [WithdrawSheet]. A non-null value means the user confirmed the
/// withdrawal; [note] is an optional free-text reason (≤500 chars server-side).
class WithdrawResult {
  const WithdrawResult({this.note});
  final String? note;
}

/// Shared confirm sheet for a sender withdrawing their own match challenge.
/// Used by BOTH the My Matches "Requests" row and the challenge detail screen
/// so the affordance is identical wherever Withdraw appears. Mirrors the
/// decline sheet's styling, but has no reason enum — `cancel_match_request`
/// takes only an optional note.
class WithdrawSheet extends StatefulWidget {
  const WithdrawSheet({super.key, this.opponentName});

  /// Opponent team name for the body copy. Null for open challenges.
  final String? opponentName;

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final who = widget.opponentName ?? 'The other team';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CkColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: CkColors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('WITHDRAW',
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                        color: CkColors.paper,
                      )),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Withdraw this challenge?',
                style: CkType.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$who will be notified you've pulled out. You can always send "
                'a new challenge later.',
                style: CkType.body(
                  fontSize: 13.5,
                  color: CkColors.ink2,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Optional note',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: CkColors.hairline),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: CkColors.red,
                    foregroundColor: CkColors.paper,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(
                    WithdrawResult(
                      note: _noteCtrl.text.trim().isEmpty
                          ? null
                          : _noteCtrl.text.trim(),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Withdraw challenge'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: CkColors.muted),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Keep it'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
