import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament_live_match.dart';

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
                subtitle: '',
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
  changeScorer,
  changeGroundOrTime,
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
