import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../../teams/domain/entities/team.dart';
import '../pool/pool_challenge_card.dart';
import '../pool/pool_icons.dart';
import 'host_kit.dart';

// ─── 17 · Accept ───────────────────────────────────────────────────────────

/// Confirms the one irreversible decision a host makes — `Pool.dc.html`
/// artboard 17.
///
/// It states both consequences rather than asking "are you sure": a match is
/// created, and every other applicant is declined automatically. The confirm
/// is ink, not red — accepting an opponent is a positive act, even though it
/// cannot be undone.
Future<bool> showAcceptApplicantSheet(
  BuildContext context, {
  required Team? applicant,
  required List<String> otherApplicantNames,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) => _AcceptSheet(
      applicant: applicant,
      otherApplicantNames: otherApplicantNames,
    ),
  );
  return confirmed ?? false;
}

class _AcceptSheet extends StatelessWidget {
  const _AcceptSheet({
    required this.applicant,
    required this.otherApplicantNames,
  });

  final Team? applicant;
  final List<String> otherApplicantNames;

  @override
  Widget build(BuildContext context) {
    final others = otherApplicantNames.length;

    return HostSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Crest(
                short: teamMonogram(applicant),
                color: teamCrestColor(applicant),
                logoUrl: applicant?.logoUrl,
                size: 44,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Accept ${applicant?.name ?? 'this team'}?',
                      style: CkType.display(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'This confirms your opponent.',
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CkColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CkColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const _Consequence(
                  icon: PoolIcons.consequenceGood,
                  title: 'A match will be created',
                  body: 'Both line-ups populate and it appears in Matches '
                      'for both teams.',
                ),
                if (others > 0)
                  _Consequence(
                    icon: PoolIcons.consequenceWarning,
                    title: others == 1
                        ? 'The other applicant is declined'
                        : 'The other $others applicants are declined',
                    body: '${_names(otherApplicantNames)} '
                        '${others == 1 ? 'is' : 'are'} notified '
                        "automatically. This can't be undone.",
                    ground: CkColors.redSoft,
                    bodyColor: CkColors.ink2,
                    ruled: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          HostActionButton(
            label: 'Accept & create the match',
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          SheetDismiss(
            label: 'Cancel',
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  /// "Model Town, Ravi Riders and 1 more" — names the ones the host will
  /// recognise, counts the rest.
  static String _names(List<String> names) {
    if (names.isEmpty) return 'They';
    if (names.length <= 2) return names.join(' and ');
    final rest = names.length - 2;
    return '${names[0]}, ${names[1]} and $rest more';
  }
}

class _Consequence extends StatelessWidget {
  const _Consequence({
    required this.icon,
    required this.title,
    required this.body,
    this.ground,
    this.bodyColor = CkColors.muted,
    this.ruled = false,
  });

  final String icon;
  final String title;
  final String body;
  final Color? ground;
  final Color bodyColor;
  final bool ruled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: ground,
        border: ruled
            ? const Border(top: BorderSide(color: CkColors.hairline))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: PoolIcon(icon, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: CkType.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: CkType.body(
                    fontSize: 12,
                    height: 1.5,
                    color: bodyColor,
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

// ─── 18 · Reject ───────────────────────────────────────────────────────────

/// What the host chose in [showRejectApplicantSheet].
class RejectDecision {
  const RejectDecision({this.reason});

  /// Chip label plus note, or null if the host declined to say why. The
  /// reason is optional by design — a host who owes no explanation should not
  /// be blocked from declining.
  final String? reason;
}

/// Declines one applicant — `Pool.dc.html` artboard 18. Others stay pending,
/// so the copy says so. Destructive, so the confirm is red.
Future<RejectDecision?> showRejectApplicantSheet(
  BuildContext context, {
  required Team? applicant,
}) {
  return showModalBottomSheet<RejectDecision>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RejectSheet(applicant: applicant),
  );
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.applicant});

  final Team? applicant;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  static const _chips = ['Slot filled', 'Format mismatch', 'Too far'];

  final _note = TextEditingController();
  String? _chip;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _confirm() {
    final note = _note.text.trim();
    final parts = [if (_chip != null) _chip!, if (note.isNotEmpty) note];
    Navigator.of(context).pop(
      RejectDecision(reason: parts.isEmpty ? null : parts.join(' — ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.applicant?.name ?? 'this team';

    return HostSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Crest(
                short: teamMonogram(widget.applicant),
                color: teamCrestColor(widget.applicant),
                logoUrl: widget.applicant?.logoUrl,
                size: 44,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Decline $name?',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CkType.display(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: CkColors.ink,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "They'll be notified. Your other applicants stay.",
                      style: CkType.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CkColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'REASON',
                style: CkType.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '· optional',
                style: CkType.body(fontSize: 11, color: CkColors.soft)
                    .copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in _chips)
                _ReasonChip(
                  label: chip,
                  active: _chip == chip,
                  // Tapping the active chip clears it: the reason is optional,
                  // so a mis-tap must be undoable without closing the sheet.
                  onTap: () =>
                      setState(() => _chip = _chip == chip ? null : chip),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            minLines: 2,
            maxLength: 500,
            style: CkType.body(fontSize: 13, height: 1.5, color: CkColors.ink),
            decoration: InputDecoration(
              filled: false,
              counterText: '',
              hintText: 'Add a short note (optional)…',
              hintStyle:
                  CkType.body(fontSize: 13, height: 1.5, color: CkColors.soft),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: _border(CkColors.line),
              enabledBorder: _border(CkColors.line),
              focusedBorder: _border(CkColors.ink),
            ),
          ),
          const SizedBox(height: 18),
          HostActionButton(
            label: 'Decline applicant',
            tone: CkColors.red,
            onTap: _confirm,
          ),
          const SizedBox(height: 10),
          SheetDismiss(
            label: 'Cancel',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: active ? CkColors.ink : CkColors.paper2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? CkColors.ink : CkColors.line),
        ),
        child: Text(
          label.toUpperCase(),
          style: CkType.mono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: active ? CkColors.paper : CkColors.muted,
          ),
        ),
      ),
    );
  }
}

// ─── 19 · Withdraw ─────────────────────────────────────────────────────────

/// Pulls the whole challenge off the board — `Pool.dc.html` artboard 19.
///
/// States the consequence plainly: it leaves the pool and every applicant is
/// told it was cancelled. Red confirm, and the dismiss is "Keep it live"
/// rather than "Cancel", which would be ambiguous next to a cancellation.
Future<bool> showWithdrawChallengeSheet(
  BuildContext context, {
  required Team? hostTeam,
  required String summary,
  required int pendingApplicants,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WithdrawSheet(
      hostTeam: hostTeam,
      summary: summary,
      pendingApplicants: pendingApplicants,
    ),
  );
  return confirmed ?? false;
}

class _WithdrawSheet extends StatelessWidget {
  const _WithdrawSheet({
    required this.hostTeam,
    required this.summary,
    required this.pendingApplicants,
  });

  final Team? hostTeam;
  final String summary;
  final int pendingApplicants;

  @override
  Widget build(BuildContext context) {
    return HostSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.redSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const PoolIcon(PoolIcons.discard, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            'Withdraw this challenge?',
            style: CkType.display(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: CkType.body(
                fontSize: 13,
                height: 1.6,
                color: CkColors.ink2,
              ),
              children: [
                const TextSpan(
                  text: "It leaves the pool immediately and can't be "
                      'reinstated.',
                ),
                if (pendingApplicants > 0) ...[
                  const TextSpan(text: ' All '),
                  TextSpan(
                    text: pendingApplicants == 1
                        ? '1 applicant'
                        : '$pendingApplicants applicants',
                    style: CkType.body(
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
                    ),
                  ),
                  const TextSpan(
                    text: ' will be notified that the challenge was '
                        'cancelled.',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CkColors.line),
            ),
            child: Row(
              children: [
                Crest(
                  short: teamMonogram(hostTeam),
                  color: teamCrestColor(hostTeam),
                  logoUrl: hostTeam?.logoUrl,
                  size: 32,
                  radius: 9,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your open challenge',
                        style: CkType.display(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        summary.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.05,
                          color: CkColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: HostActionButton(
              label: 'Withdraw challenge',
              tone: CkColors.red,
              onTap: () => Navigator.of(context).pop(true),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SheetDismiss(
              label: 'Keep it live',
              onTap: () => Navigator.of(context).pop(false),
            ),
          ),
        ],
      ),
    );
  }
}
