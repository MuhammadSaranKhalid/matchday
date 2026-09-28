import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament_live_match.dart';
import '../../domain/ops/revised_target.dart';

/// The ground-ops bottom sheets (artboard 28).
///
/// All three share the same chrome: white surface, 20pt top corners, a flat
/// 32% ink scrim and no blur. Abandon is the only one that spends red — on its
/// destructive confirm; the other two are administrative and stay ink.

// ─── Shared chrome ───────────────────────────────────────────────────────────

Future<T?> _showOpsSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: CkColors.ink.withValues(alpha: 0.32),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(CkRadii.lg)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(child: builder(ctx)),
        ),
      ),
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
              color: CkColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(title, style: CkType.display(fontSize: 19)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: CkType.body(fontSize: 12.5, color: CkColors.muted),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
            ),
          ),
          if (trailing != null) ...[
            Text(
              ' · ${trailing!}',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.10,
                color: CkColors.soft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A selectable card — the shared shape behind "what happens to this match",
/// "award the match to" and "set the winner".
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.leading,
    this.badge,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? leading;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? CkColors.paper2 : CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CkRadii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(
                color: selected ? CkColors.ink : CkColors.line,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: CkType.display(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: CkColors.paper2,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: CkColors.line),
                              ),
                              child: Text(
                                badge!.toUpperCase(),
                                style: CkType.mono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.10,
                                  color: CkColors.ink2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: CkType.body(
                            fontSize: 11.5,
                            height: 1.45,
                            color: CkColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: selected ? CkColors.ink : CkColors.soft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({
    required this.title,
    required this.body,
    this.cream = true,
  });

  final String title;
  final String body;
  final bool cream;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: cream ? CkColors.cream : CkColors.paper2,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(
          color: cream ? CkColors.creamBorder : CkColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: CkType.mono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: cream ? CkColors.amberDark : CkColors.ink2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: CkType.body(
              fontSize: 12,
              height: 1.5,
              color: cream ? CkColors.amberDark : CkColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  const _SheetActions({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.destructive = false,
  });

  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: CkColors.ink,
              side: const BorderSide(color: CkColors.line),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CkRadii.sm),
              ),
            ),
            child: Text(
              cancelLabel,
              style: CkType.display(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive ? CkColors.red : CkColors.ink,
              disabledBackgroundColor: CkColors.soft,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CkRadii.sm),
              ),
            ),
            child: Text(
              confirmLabel,
              style: CkType.display(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: CkType.body(fontSize: 13, color: CkColors.soft),
      filled: true,
      fillColor: CkColors.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
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

String _matchupOf(TournamentLiveMatch m) =>
    '${m.teamAName ?? 'TBC'} v ${m.teamBName ?? 'TBC'}';

String _oversBowled(TournamentLiveMatch m) {
  if (m.inningsLines.isEmpty) return 'not started';
  final total = m.inningsLines.fold<int>(0, (sum, l) => sum + l.legalBalls);
  final overs = total ~/ 6;
  final balls = total % 6;
  return '$overs.$balls overs bowled';
}

// ─── Sheet 1 · Abandon match ─────────────────────────────────────────────────

/// Result of the abandon sheet — null if the organiser kept playing.
class AbandonOutcome {
  const AbandonOutcome({
    required this.mode,
    this.rescheduleTo,
    this.reason,
  });

  final AbandonMode mode;
  final DateTime? rescheduleTo;
  final String? reason;
}

Future<AbandonOutcome?> showAbandonMatchSheet(
  BuildContext context,
  TournamentLiveMatch match,
) {
  return _showOpsSheet<AbandonOutcome>(
    context: context,
    builder: (ctx) => _AbandonSheet(match: match),
  );
}

class _AbandonSheet extends StatefulWidget {
  const _AbandonSheet({required this.match});

  final TournamentLiveMatch match;

  @override
  State<_AbandonSheet> createState() => _AbandonSheetState();
}

class _AbandonSheetState extends State<_AbandonSheet> {
  AbandonMode _mode = AbandonMode.reschedule;
  late DateTime _newDate = widget.match.scheduledStartTime.add(
    const Duration(days: 1),
  );
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _newDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_newDate),
    );
    if (!mounted) return;

    setState(() {
      _newDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _newDate.hour,
        time?.minute ?? _newDate.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            title: 'Abandon match',
            subtitle: '${_matchupOf(m)} · ${_oversBowled(m)}',
          ),
          const _FieldLabel('What happens to this match'),
          _ChoiceCard(
            selected: _mode == AbandonMode.reschedule,
            title: 'Reschedule to a new date',
            subtitle: 'The scorecard is discarded and the fixture returns as '
                'upcoming. Both teams are notified.',
            onTap: () => setState(() => _mode = AbandonMode.reschedule),
          ),
          _ChoiceCard(
            selected: _mode == AbandonMode.noResult,
            title: 'Declare no result',
            subtitle: 'Points split 1–1. Counts as played for both sides; '
                'NRR is unaffected.',
            onTap: () => setState(() => _mode = AbandonMode.noResult),
          ),
          if (_mode == AbandonMode.reschedule) ...[
            const SizedBox(height: 4),
            Material(
              color: CkColors.paper,
              borderRadius: BorderRadius.circular(CkRadii.sm),
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(CkRadii.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(CkRadii.sm),
                    border: Border.all(color: CkColors.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('d MMM yyyy · HH:mm').format(_newDate),
                          style: CkType.mono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            color: CkColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        'CHANGE',
                        style: CkType.mono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08,
                          color: CkColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const _FieldLabel('Reason', trailing: 'optional'),
          TextField(
            controller: _reason,
            maxLines: 2,
            style: CkType.body(fontSize: 13),
            decoration: _fieldDecoration('Rain at Model Town Ground.'),
          ),
          const SizedBox(height: 18),
          _SheetActions(
            cancelLabel: 'Keep playing',
            confirmLabel: 'Abandon Match',
            destructive: true,
            onCancel: () => Navigator.pop(context),
            onConfirm: () => Navigator.pop(
              context,
              AbandonOutcome(
                mode: _mode,
                rescheduleTo:
                    _mode == AbandonMode.reschedule ? _newDate : null,
                reason: _reason.text.trim().isEmpty
                    ? null
                    : _reason.text.trim(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet 2 · Declare a walkover ────────────────────────────────────────────

class WalkoverOutcome {
  const WalkoverOutcome({required this.winnerTeamId, this.reason});

  final String winnerTeamId;
  final String? reason;
}

Future<WalkoverOutcome?> showWalkoverSheet(
  BuildContext context,
  TournamentLiveMatch match,
) {
  return _showOpsSheet<WalkoverOutcome>(
    context: context,
    builder: (ctx) => _WalkoverSheet(match: match),
  );
}

class _WalkoverSheet extends StatefulWidget {
  const _WalkoverSheet({required this.match});

  final TournamentLiveMatch match;

  @override
  State<_WalkoverSheet> createState() => _WalkoverSheetState();
}

class _WalkoverSheetState extends State<_WalkoverSheet> {
  String? _winnerId;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final winnerName = _winnerId == null ? null : m.displayNameFor(_winnerId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            title: 'Declare a walkover',
            subtitle: '${_matchupOf(m)}'
                '${m.round == null ? '' : ' · ${m.round}'}',
          ),
          const _FieldLabel('Award the match to'),
          for (final id in [m.teamAId, m.teamBId])
            if (id != null)
              _ChoiceCard(
                selected: _winnerId == id,
                title: m.displayNameFor(id),
                // The two sides of the same fact (artboard 28) — but only
                // once a winner is picked; before that neither side has been
                // accused of anything.
                subtitle: _winnerId == null
                    ? ''
                    : _winnerId == id
                        ? 'Arrived and was ready to play'
                        : 'Did not arrive',
                leading: _TeamCrest(name: m.displayNameFor(id)),
                onTap: () => setState(() => _winnerId = id),
              ),
          const SizedBox(height: 6),
          _NoteBlock(
            title: 'Effect on the table',
            body: winnerName == null
                ? 'The winning side takes 2 points. No runs or overs are '
                    'recorded, so neither team’s NRR changes — a walkover '
                    'cannot help or hurt run rate.'
                : '$winnerName take 2 points. No runs or overs are recorded, '
                    'so neither team’s NRR changes — a walkover cannot '
                    'help or hurt run rate.',
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Reason', trailing: 'optional'),
          TextField(
            controller: _reason,
            maxLines: 2,
            style: CkType.body(fontSize: 13),
            decoration: _fieldDecoration(
              'Squad stuck in traffic, forfeited at 10:20.',
            ),
          ),
          const SizedBox(height: 18),
          _SheetActions(
            cancelLabel: 'Cancel',
            confirmLabel: 'Declare Walkover',
            onCancel: () => Navigator.pop(context),
            onConfirm: _winnerId == null
                ? null
                : () => Navigator.pop(
                      context,
                      WalkoverOutcome(
                        winnerTeamId: _winnerId!,
                        reason: _reason.text.trim().isEmpty
                            ? null
                            : _reason.text.trim(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _TeamCrest extends StatelessWidget {
  const _TeamCrest({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length == 1
        ? parts.first.characters.take(2).toString().toUpperCase()
        : (parts.first.characters.first + parts[1].characters.first)
            .toUpperCase();

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        shape: BoxShape.circle,
        border: Border.all(color: CkColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: CkType.display(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Sheet 3 · Override the result ───────────────────────────────────────────

class OverrideOutcome {
  const OverrideOutcome({required this.winnerTeamId, required this.reason});

  final String winnerTeamId;
  final String reason;
}

Future<OverrideOutcome?> showOverrideResultSheet(
  BuildContext context,
  TournamentLiveMatch match,
) {
  return _showOpsSheet<OverrideOutcome>(
    context: context,
    builder: (ctx) => _OverrideSheet(match: match),
  );
}

class _OverrideSheet extends StatefulWidget {
  const _OverrideSheet({required this.match});

  final TournamentLiveMatch match;

  @override
  State<_OverrideSheet> createState() => _OverrideSheetState();
}

class _OverrideSheetState extends State<_OverrideSheet> {
  late String? _winnerId = widget.match.winnerId;
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final reasonOk = _reason.text.trim().length >= 10;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            title: 'Override the result',
            subtitle: m.resultDescription ?? _matchupOf(m),
          ),
          const _FieldLabel('Set the winner'),
          for (final id in [m.teamAId, m.teamBId])
            if (id != null)
              _ChoiceCard(
                selected: _winnerId == id,
                title: m.displayNameFor(id),
                subtitle: '',
                badge: m.winnerId == id ? 'Current' : null,
                onTap: () => setState(() => _winnerId = id),
              ),
          const SizedBox(height: 8),
          const _FieldLabel('Reason', trailing: 'required'),
          TextField(
            controller: _reason,
            maxLines: 3,
            style: CkType.body(fontSize: 13),
            decoration: _fieldDecoration(
              'Scorer recorded 4 extra runs in the 18th over. Corrected after '
              'both captains signed the sheet.',
            ),
          ),
          const SizedBox(height: 12),
          const _NoteBlock(
            title: 'This action is audited',
            body: 'Your name, the timestamp and this reason are permanently '
                'attached to the scorecard and visible to both managers.',
            cream: false,
          ),
          const SizedBox(height: 18),
          _SheetActions(
            cancelLabel: 'Cancel',
            confirmLabel: 'Save Override',
            onCancel: () => Navigator.pop(context),
            onConfirm: (_winnerId == null || !reasonOk)
                ? null
                : () => Navigator.pop(
                      context,
                      OverrideOutcome(
                        winnerTeamId: _winnerId!,
                        reason: _reason.text.trim(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ─── The per-match Actions menu (artboard 27c, right) ────────────────────────

enum MatchOpsAction {
  assignOfficials,
  changeScorer,
  changeGroundOrTime,
  reviseConditions,
  launchSuperOver,
  declareWalkover,
  overrideResult,
  abandonMatch,
}

Future<MatchOpsAction?> showMatchActionsMenu(
  BuildContext context,
  TournamentLiveMatch match,
) {
  return _showOpsSheet<MatchOpsAction>(
    context: context,
    builder: (ctx) {
      final started = match.isLive || match.isFinished;
      final scorerLine = match.scorerName == null
          ? 'Nobody assigned yet'
          : 'Currently ${match.scorerName}';

      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(
              title: _matchupOf(match),
              subtitle: match.isLive
                  ? 'Live · ${match.venue} · ${_oversBowled(match)}'
                  : '${match.venue} · '
                      '${DateFormat('d MMM · HH:mm').format(match.scheduledStartTime)}',
            ),
            if (!match.isFinished)
              _MenuRow(
                title: 'Assign umpires & scorers',
                subtitle: 'Officials and the handover code',
                onTap: () =>
                    Navigator.pop(ctx, MatchOpsAction.assignOfficials),
              ),
            if (!match.isFinished)
              _MenuRow(
                title: 'Change scorer',
                subtitle: scorerLine,
                onTap: () => Navigator.pop(ctx, MatchOpsAction.changeScorer),
              ),
            if (!match.isFinished)
              _MenuRow(
                title: 'Change ground or time',
                subtitle: '${match.venue} · '
                    '${DateFormat('d MMM, HH:mm').format(match.scheduledStartTime)}',
                onTap: () =>
                    Navigator.pop(ctx, MatchOpsAction.changeGroundOrTime),
              ),
            // Rain: only once there is a match in progress to shorten.
            if (started && !match.isFinished)
              _MenuRow(
                title: 'Revise match conditions',
                subtitle: 'Rain — reduce overs and reset the target',
                onTap: () =>
                    Navigator.pop(ctx, MatchOpsAction.reviseConditions),
              ),
            // The engine decides the tie; this only opens the super over.
            if (match.status == 'tied')
              _MenuRow(
                title: 'Launch super over',
                subtitle: 'Scores are level after regulation',
                onTap: () =>
                    Navigator.pop(ctx, MatchOpsAction.launchSuperOver),
              ),
            if (!match.isFinished)
              _MenuRow(
                title: 'Declare walkover',
                subtitle: 'Award to a team that turned up',
                onTap: () => Navigator.pop(ctx, MatchOpsAction.declareWalkover),
              ),
            if (match.isFinished)
              _MenuRow(
                title: 'Override the result',
                subtitle: 'Audited · needs a reason',
                onTap: () => Navigator.pop(ctx, MatchOpsAction.overrideResult),
              ),
            if (started && !match.isFinished)
              // The one destructive item, last, in red text on white —
              // never a red row fill.
              _MenuRow(
                title: 'Abandon match',
                subtitle: 'Rain, light, or crowd trouble',
                destructive: true,
                onTap: () => Navigator.pop(ctx, MatchOpsAction.abandonMatch),
              ),
            const SizedBox(height: 6),
          ],
        ),
      );
    },
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final titleColor = !enabled
        ? CkColors.soft
        : destructive
            ? CkColors.redInk
            : CkColors.ink;

    return Material(
      color: CkColors.surface,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: CkColors.hairline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: CkType.display(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: CkType.body(fontSize: 11.5, color: CkColors.muted),
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(Icons.chevron_right, size: 18, color: CkColors.soft),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── The console overflow menu (artboard 27c, left) ──────────────────────────

enum ConsoleMenuAction {
  editSettings,
  feeLedger,
  sendAnnouncement,
  coOrganisers,
  closeRegistrationEarly,
  cancelTournament,
}

Future<ConsoleMenuAction?> showConsoleMenu(
  BuildContext context, {
  required String tournamentName,
  required String statusLine,
  required bool inRegistration,
  required bool drawLocked,
  bool isOwner = true,
  bool hasEntryFee = false,
}) {
  return _showOpsSheet<ConsoleMenuAction>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(title: tournamentName, subtitle: statusLine),
          _MenuRow(
            title: 'Edit tournament settings',
            subtitle: 'Dates, rules, prizes, venues',
            onTap: () => Navigator.pop(ctx, ConsoleMenuAction.editSettings),
          ),
          // Artboard 24c. Only offered when there is money to reconcile — a
          // free cup has no ledger, and an empty one is worse than absent.
          if (hasEntryFee)
            _MenuRow(
              title: 'Fee ledger',
              subtitle: 'Who has paid, and what is outstanding',
              onTap: () => Navigator.pop(ctx, ConsoleMenuAction.feeLedger),
            ),
          _MenuRow(
            title: 'Send an announcement',
            subtitle: 'Notifies all managers and followers',
            onTap: () => Navigator.pop(ctx, ConsoleMenuAction.sendAnnouncement),
          ),
          _MenuRow(
            title: 'Co-organisers',
            subtitle: 'They can score and approve',
            onTap: () => Navigator.pop(ctx, ConsoleMenuAction.coOrganisers),
          ),
          // Lifecycle-adaptive: after the draw locks this becomes a disabled
          // "Reopen registration" with a reason rather than vanishing,
          // because organisers go looking for it.
          if (inRegistration)
            _MenuRow(
              title: 'Close registration early',
              subtitle: 'Play with the teams you have',
              onTap: () => Navigator.pop(
                ctx,
                ConsoleMenuAction.closeRegistrationEarly,
              ),
            )
          else
            _MenuRow(
              title: 'Reopen registration',
              subtitle: drawLocked
                  ? 'Not available — the draw is locked'
                  : 'Registration is not currently closed',
              enabled: false,
              onTap: () {},
            ),
          _MenuRow(
            title: 'Cancel tournament',
            subtitle: isOwner
                ? 'Notifies everyone · cannot be undone'
                : 'Only the tournament creator can cancel it',
            destructive: isOwner,
            enabled: isOwner,
            onTap: isOwner
                ? () => Navigator.pop(ctx, ConsoleMenuAction.cancelTournament)
                : () {},
          ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
}

// ─── Match-law ops (artboards 27m, 28b) ──────────────────────────────────────

/// What the organiser applied on the rain sheet.
class ReviseConditionsOutcome {
  const ReviseConditionsOutcome({
    required this.revisedOvers,
    required this.bowlerQuota,
    required this.method,
    this.revisedTarget,
    this.reason,
  });

  final int revisedOvers;
  final int bowlerQuota;
  final TargetMethod method;
  final int? revisedTarget;
  final String? reason;
}

/// Artboards 27m / 28b — "Revise match conditions" and "Revise the target".
///
/// These are **calculators, not confirmations**: form on top, the computed
/// answer in a cream box, the action at the bottom. The organiser reads the
/// number back to both captains before committing, which is also why the DLS
/// figure is typed in rather than guessed at — see [RevisedTargetCalculator].
///
/// Cream throughout. Red is reserved for abandonment, which lives one row
/// below in the match-ops menu.
Future<ReviseConditionsOutcome?> showReviseConditionsSheet(
  BuildContext context, {
  required TournamentLiveMatch match,
  required StoppageContext stoppage,
  String? stoppageNote,
}) {
  return _showOpsSheet<ReviseConditionsOutcome>(
    context: context,
    builder: (ctx) => _ReviseConditionsSheet(
      match: match,
      stoppage: stoppage,
      stoppageNote: stoppageNote,
    ),
  );
}

class _ReviseConditionsSheet extends StatefulWidget {
  const _ReviseConditionsSheet({
    required this.match,
    required this.stoppage,
    this.stoppageNote,
  });

  final TournamentLiveMatch match;
  final StoppageContext stoppage;
  final String? stoppageNote;

  @override
  State<_ReviseConditionsSheet> createState() => _ReviseConditionsSheetState();
}

class _ReviseConditionsSheetState extends State<_ReviseConditionsSheet> {
  late int _overs;
  late TargetMethod _method;
  final _target = TextEditingController();
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Open one over short of the original — the organiser is here because
    // play was lost, so the starting guess should already be a reduction.
    final min = RevisedTargetCalculator.minimumSelectableOvers(widget.stoppage);
    final suggested = widget.stoppage.originalOvers - 1;
    _overs = suggested < min ? min : suggested;
    _method = TargetMethod.runRate;
  }

  @override
  void dispose() {
    _target.dispose();
    _reason.dispose();
    super.dispose();
  }

  RevisedTargetPreview get _preview => RevisedTargetCalculator.preview(
        context: widget.stoppage,
        revisedOvers: _overs,
        method: _method,
        enteredTarget: int.tryParse(_target.text.trim()),
      );

  @override
  Widget build(BuildContext context) {
    final stoppage = widget.stoppage;
    final preview = _preview;
    final min = RevisedTargetCalculator.minimumSelectableOvers(stoppage);
    final max = stoppage.originalOvers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            title: stoppage.isChaseInterrupted
                ? 'Revise the target'
                : 'Revise match conditions',
            subtitle: '${widget.match.teamAName ?? 'Team A'} v '
                '${widget.match.teamBName ?? 'Team B'}'
                '${widget.match.round == null ? '' : ' · ${widget.match.round}'}',
          ),

          // The situation, stated before anything is asked of the organiser.
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: CkColors.cream,
              borderRadius: BorderRadius.circular(CkRadii.md),
              border: Border.all(color: CkColors.creamBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  size: 16,
                  color: CkColors.amberDark,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    widget.stoppageNote ??
                        'Play stopped at ${stoppage.oversBowledText} overs in '
                            'the ${stoppage.inningsNumber == 1 ? '1st' : '2nd'} '
                            'innings. Reducing the match will recalculate the '
                            'bowler quota'
                            '${stoppage.isChaseInterrupted ? ' and the target' : ''}.',
                    style: CkType.body(
                      fontSize: 12,
                      height: 1.5,
                      color: CkColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _FieldLabel(
            'New match length per side',
            trailing: 'was ${stoppage.originalOvers}',
          ),
          const SizedBox(height: 8),
          _OversStepper(
            value: _overs,
            min: min,
            max: max,
            onChanged: (v) => setState(() => _overs = v),
          ),
          const SizedBox(height: 6),
          Text(
            'Minimum ${RevisedTargetCalculator.minimumOvers} overs per side '
            'for a result.',
            style: CkType.body(fontSize: 11.5, color: CkColors.muted),
          ),

          if (stoppage.isChaseInterrupted) ...[
            const SizedBox(height: 16),
            const _FieldLabel('Target calculation method'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final m in TargetMethod.values)
                  _MethodPill(
                    label: m.label,
                    selected: _method == m,
                    onTap: () => setState(() => _method = m),
                  ),
              ],
            ),
            if (_method != TargetMethod.runRate) ...[
              const SizedBox(height: 10),
              _TargetEntry(
                controller: _target,
                method: _method,
                onChanged: () => setState(() {}),
              ),
            ],
          ],

          const SizedBox(height: 14),
          _ImpactPreview(preview: preview, stoppage: stoppage),

          const SizedBox(height: 12),
          const _FieldLabel('Reason · shown to both captains'),
          const SizedBox(height: 8),
          _ReasonBox(
            controller: _reason,
            hint: 'e.g. Rain at Model Town Ground, 26 minutes lost',
          ),

          const SizedBox(height: 12),
          const _NoteBlock(
            title: 'When you apply this',
            body: 'Both captains and the scorer are notified the moment this '
                'is applied. The scoring app picks up the new overs and bowler '
                'quota immediately.',
          ),

          const SizedBox(height: 14),
          _SheetActions(
            // "Resume Play (Unchanged)" (artboard 28b): the organiser opened
            // the sheet because play stopped, and the commonest outcome is
            // that it resumes with nothing revised. Dismissing is that
            // outcome, so the cancel slot says so rather than "Cancel".
            cancelLabel: 'Resume Play (Unchanged)',
            confirmLabel: stoppage.isChaseInterrupted
                ? 'Apply Revised Target & Notify Teams'
                : 'Apply & Notify Teams',
            onCancel: () => Navigator.pop(context),
            onConfirm: preview.isValid
                ? () => Navigator.pop(
                      context,
                      ReviseConditionsOutcome(
                        revisedOvers: preview.revisedOvers,
                        bowlerQuota: preview.bowlerQuota,
                        method: _method,
                        revisedTarget: preview.target,
                        reason: _reason.text.trim().isEmpty
                            ? null
                            : _reason.text.trim(),
                      ),
                    )
                : null,
          ),
          if (!preview.isValid && preview.invalidReason != null) ...[
            const SizedBox(height: 8),
            Text(
              preview.invalidReason!,
              textAlign: TextAlign.center,
              style: CkType.body(fontSize: 11.5, color: CkColors.amberInk),
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// The cream computed box: the number the organiser reads back to the captains.
class _ImpactPreview extends StatelessWidget {
  const _ImpactPreview({required this.preview, required this.stoppage});

  final RevisedTargetPreview preview;
  final StoppageContext stoppage;

  @override
  Widget build(BuildContext context) {
    final target = preview.target;
    final rate = preview.requiredRunRate;
    final par = preview.parScore;
    final diff = preview.parDifference;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            target == null ? 'IMPACT PREVIEW' : 'REVISED TARGET',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.amberDark,
            ),
          ),
          if (target != null) ...[
            const SizedBox(height: 6),
            Text(
              '$target',
              style: CkType.mono(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: CkColors.ink,
              ),
            ),
            Text(
              'RUNS FROM ${preview.revisedOvers} OVERS',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: CkColors.amberDark,
              ),
            ),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _ImpactStat(
                label: 'Max overs per bowler',
                value: '${stoppage.originalQuota} → ${preview.bowlerQuota}',
              ),
              _ImpactStat(
                label: 'Overs bowled',
                value: '${stoppage.oversBowledText} of '
                    '${preview.revisedOvers}',
              ),
              if (rate != null)
                _ImpactStat(
                  label: 'Required rate',
                  value: '${rate.toStringAsFixed(2)} RPO · '
                      '${preview.ballsRemaining} balls left',
                ),
              if (par != null && diff != null)
                _ImpactStat(
                  label: 'Par at ${stoppage.oversBowledText}',
                  value: '$par · ${diff >= 0 ? '+' : ''}$diff',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  const _ImpactStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: CkType.mono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: CkType.mono(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: CkColors.ink,
          ),
        ),
      ],
    );
  }
}

/// Overs are *tapped*, not dragged — the same reasoning as the scheduler in
/// artboard 25: one number is being fixed in place, not explored.
class _OversStepper extends StatelessWidget {
  const _OversStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '$value',
                style: CkType.mono(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CkColors.ink,
                ),
              ),
              Text(
                value == 1 ? 'OVER' : 'OVERS',
                style: CkType.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.10,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
        _StepButton(
          icon: Icons.add,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CkColors.paper,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CkColors.line),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? CkColors.soft : CkColors.ink,
          ),
        ),
      ),
    );
  }
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CkColors.paper2 : CkColors.paper,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 13,
            vertical: selected ? 7.5 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? CkColors.ink : CkColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? CkColors.ink : CkColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

/// DLS is a lookup against the official table, so the organiser enters the
/// figure they read off it. See [RevisedTargetCalculator] for why this app
/// does not reproduce that table.
class _TargetEntry extends StatelessWidget {
  const _TargetEntry({
    required this.controller,
    required this.method,
    required this.onChanged,
  });

  final TextEditingController controller;
  final TargetMethod method;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: CkColors.surface,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  style: CkType.mono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CkColors.ink,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintText: method == TargetMethod.dls
                        ? 'Target from the DLS table'
                        : 'Agreed target',
                    hintStyle: CkType.body(fontSize: 13, color: CkColors.soft),
                  ),
                ),
              ),
              Text(
                'RUNS',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (method == TargetMethod.dls) ...[
          const SizedBox(height: 6),
          Text(
            'Read the revised target off the official DLS table or the ICC '
            'app, then enter it here. Matchday does not compute DLS — a table '
            'reproduced from memory would be wrong confidently.',
            style: CkType.body(
              fontSize: 11.5,
              height: 1.45,
              color: CkColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReasonBox extends StatelessWidget {
  const _ReasonBox({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: TextField(
        controller: controller,
        maxLines: 2,
        maxLength: 240,
        style: CkType.body(fontSize: 12.5, height: 1.5, color: CkColors.ink),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          filled: false,
          counterText: '',
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          hintStyle: CkType.body(
            fontSize: 12.5,
            height: 1.5,
            color: CkColors.soft,
          ),
        ),
      ),
    );
  }
}

// ─── Super over (artboard 28c) ───────────────────────────────────────────────

/// Which side bats first in the super over.
class SuperOverOutcome {
  const SuperOverOutcome({required this.batsFirstTeamId});

  final String batsFirstTeamId;
}

/// Artboard 28c — "Launch super over".
///
/// The scores are level and the engine has already said so; this sheet does
/// not decide the tie and does not score the over. It states the rules in
/// force, takes the one decision that is the organiser's — who bats first —
/// and hands over to the scorer console.
Future<SuperOverOutcome?> showSuperOverSheet(
  BuildContext context, {
  required TournamentLiveMatch match,
  bool boundaryCountback = true,
}) {
  return _showOpsSheet<SuperOverOutcome>(
    context: context,
    builder: (ctx) => _SuperOverSheet(
      match: match,
      boundaryCountback: boundaryCountback,
    ),
  );
}

class _SuperOverSheet extends StatefulWidget {
  const _SuperOverSheet({
    required this.match,
    required this.boundaryCountback,
  });

  final TournamentLiveMatch match;
  final bool boundaryCountback;

  @override
  State<_SuperOverSheet> createState() => _SuperOverSheetState();
}

class _SuperOverSheetState extends State<_SuperOverSheet> {
  String? _batsFirst;

  @override
  void initState() {
    super.initState();
    // The side that chased in regulation bats first by convention, and the
    // chasing side is whichever innings came last.
    final lines = widget.match.inningsLines;
    if (lines.isNotEmpty) {
      final last = lines.reduce(
        (a, b) => b.inningsNumber > a.inningsNumber ? b : a,
      );
      _batsFirst = last.battingTeamId;
    }
    _batsFirst ??= widget.match.teamBId;
  }

  String _scoreOf(String? teamId) {
    final line = widget.match.lineFor(teamId);
    return line?.scoreText ?? '—';
  }

  /// "Batted first" / "Chased second" — the artboard shows how each side got
  /// here, because the convention is that the side that chased bats first in
  /// the super over.
  String _regulationRole(String? teamId) {
    final line = widget.match.lineFor(teamId);
    if (line == null) return 'Regulation';
    return line.inningsNumber == 1 ? 'Batted first' : 'Chased second';
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final aId = match.teamAId;
    final bId = match.teamBId;

    // The level score, taken from whichever innings line is present.
    final level = match.inningsLines.isEmpty
        ? null
        : match.inningsLines.first.runs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            title: 'Launch super over',
            subtitle: '${match.teamAName ?? 'Team A'} v '
                '${match.teamBName ?? 'Team B'}'
                '${level == null ? '' : ' · scores level at $level'}',
          ),

          _NoteBlock(
            title: 'Rules in force',
            body: '1 over per team, 2 wickets max. If the super over is also '
                'tied, ${widget.boundaryCountback ? 'boundary countback decides' : 'the match is recorded as a tie'} '
                '— set by the organiser at creation.',
          ),

          const SizedBox(height: 14),
          const _FieldLabel('Bats first in the super over'),
          const SizedBox(height: 8),
          if (aId != null)
            _ChoiceCard(
              selected: _batsFirst == aId,
              title: match.teamAName ?? 'Team A',
              subtitle: '${_regulationRole(aId)} · ${_scoreOf(aId)}',
              leading: _TeamCrest(name: match.teamAName ?? 'Team A'),
              onTap: () => setState(() => _batsFirst = aId),
            ),
          if (aId != null && bId != null) const SizedBox(height: 8),
          if (bId != null)
            _ChoiceCard(
              selected: _batsFirst == bId,
              title: match.teamBName ?? 'Team B',
              subtitle: '${_regulationRole(bId)} · ${_scoreOf(bId)}',
              leading: _TeamCrest(name: match.teamBName ?? 'Team B'),
              onTap: () => setState(() => _batsFirst = bId),
            ),

          const SizedBox(height: 14),
          const _NoteBlock(
            title: 'Before the first ball',
            body: 'Nominate 3 batters and 1 bowler now. The super over is '
                'bowled from the same end as the final over of the innings. '
                'Both scorecards stay attached to this fixture — regulation '
                'first, the super over as a second card — and for the table '
                'the match is a win worth 2 points, with NRR taken from the '
                'regulation innings only.',
            cream: false,
          ),

          const SizedBox(height: 14),
          _SheetActions(
            // The match is already recorded as tied, so dismissing really is
            // "record as tie" — the label is a promise the state already keeps.
            cancelLabel: 'Record as tie — no super over',
            confirmLabel: 'Open Super Over Scorer Console',
            onCancel: () => Navigator.pop(context),
            onConfirm: _batsFirst == null
                ? null
                : () => Navigator.pop(
                      context,
                      SuperOverOutcome(batsFirstTeamId: _batsFirst!),
                    ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
