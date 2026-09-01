import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';

/// Artboard 21b — the publish confirmation.
///
/// Publishing is **reversible**: it opens registrations, it does not lock a
/// draw. So this dialog is ink-affirmative, not destructive. Compare the Lock
/// & Publish dialog (artboard 26), which is permanent, and Cancel (27g), which
/// destroys something people rely on.
///
/// Dialogs in this feature are surface white on a flat 32% ink scrim, radius
/// 14, no blur — centred rather than a bottom sheet, because they demand an
/// answer.
Future<bool?> showPublishTournamentDialog(
  BuildContext context, {
  required String name,
  required String city,
  DateTime? registrationDeadline,
}) {
  final deadline = registrationDeadline == null
      ? null
      : DateFormat('d MMM').format(registrationDeadline);

  return showDialog<bool>(
    context: context,
    barrierColor: CkColors.ink.withValues(alpha: 0.32),
    builder: (ctx) => AlertDialog(
      backgroundColor: CkColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CkRadii.md),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      title: Text(
        'Ready to open registrations?',
        style: CkType.display(fontSize: 19, height: 1.25),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name becomes visible in Explore'
            '${city.isEmpty ? '' : ' to managers near $city'} and they can '
            'apply. You can still edit dates, rules and prizes afterwards.',
            style: CkType.body(
              fontSize: 12.5,
              height: 1.55,
              color: CkColors.ink2,
            ),
          ),
          const SizedBox(height: 14),
          const _Consequence('Listed publicly in Explore'),
          _Consequence(
            deadline == null
                ? 'Team applications open immediately'
                : 'Team applications open until $deadline',
          ),
          const _Consequence('Fixtures stay unlocked until you seed the draw'),
          const SizedBox(height: 4),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(foregroundColor: CkColors.ink2),
          child: Text(
            'Not yet',
            style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: CkColors.ink,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CkRadii.sm),
            ),
          ),
          child: Text(
            'Publish',
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CkColors.paper,
            ),
          ),
        ),
      ],
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
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.check, size: 14, color: CkColors.greenInk),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: CkType.body(
                fontSize: 12,
                height: 1.45,
                color: CkColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
