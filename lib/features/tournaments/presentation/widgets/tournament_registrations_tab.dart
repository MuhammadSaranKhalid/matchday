import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_registration.dart';
import 'tournament_wizard_kit.dart';

/// Console tab 1 — the applications inbox (artboards 24, 24b).
///
/// Decline is red text on a ghost button, the only red on the screen, earned
/// because it is destructive. Approve is ink-filled. "Mark fee as paid" is a
/// toggle, not a payment, and the row says so.
class TournamentRegistrationsTab extends StatelessWidget {
  const TournamentRegistrationsTab({
    super.key,
    required this.tournament,
    required this.pending,
    required this.approved,
    required this.waitlisted,
    required this.onApprove,
    required this.onDecline,
    required this.onTogglePaid,
    required this.onShare,
    required this.onInviteTeams,
    this.statusLine,
  });

  final Tournament tournament;

  /// Applications still inside the draw's capacity.
  final List<TournamentRegistration> pending;
  final List<TournamentRegistration> approved;

  /// Applications beyond capacity — the draw is full, so they wait.
  final List<TournamentRegistration> waitlisted;

  final void Function(TournamentRegistration) onApprove;
  final void Function(TournamentRegistration) onDecline;
  final void Function(TournamentRegistration) onTogglePaid;
  final VoidCallback onShare;
  final VoidCallback onInviteTeams;

  /// "Closes in 2 days · 6 of 8 approved" — cream, at the head of the queue.
  final String? statusLine;

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty && approved.isEmpty && waitlisted.isEmpty) {
      return _EmptyQueue(
        tournament: tournament,
        onShare: onShare,
        onInviteTeams: onInviteTeams,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (statusLine != null) _StatusBanner(text: statusLine!),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionHeading('Pending applications (${pending.length})'),
          const SizedBox(height: 8),
          for (final reg in pending) ...[
            _ApplicationCard(
              reg: reg,
              entryFee: tournament.entryFee,
              onApprove: () => onApprove(reg),
              onDecline: () => onDecline(reg),
              onTogglePaid: () => onTogglePaid(reg),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
        ],
        if (approved.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ApprovedList(
            approved: approved,
            onTogglePaid: onTogglePaid,
            heading: 'Approved teams (${approved.length}'
                '${tournament.maxTeams == null ? '' : ' / ${tournament.maxTeams}'})',
          ),
        ],
        if (waitlisted.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SectionHeading('Waitlist (${waitlisted.length})'),
          const SizedBox(height: 8),
          for (final reg in waitlisted) ...[
            _WaitlistRow(reg: reg, onPromote: () => onApprove(reg)),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text, {this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: CkType.mono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.12,
      ),
    );
    if (action == null) return label;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: label),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              action!,
              style: CkType.body(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: CkColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The cream state banner at the head of the queue.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 14, color: CkColors.amber),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.amberDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pending application ─────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.reg,
    required this.entryFee,
    required this.onApprove,
    required this.onDecline,
    required this.onTogglePaid,
  });

  final TournamentRegistration reg;
  final double? entryFee;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onTogglePaid;

  bool get _isPaid => (reg.paymentStatus ?? '').toLowerCase() == 'paid';

  String get _appliedAgo {
    final d = DateTime.now().difference(reg.registeredAt);
    if (d.inMinutes < 60) return 'applied ${d.inMinutes}m ago';
    if (d.inHours < 24) return 'applied ${d.inHours}h ago';
    return 'applied ${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.decimalPattern();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Crest(reg: reg),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            reg.teamName ?? 'Team',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CkType.display(
                              fontSize: 15.5,
                              letterSpacing: -0.01,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (_isPaid) ...[
                          const SizedBox(width: 7),
                          const _PaidPill(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (reg.captainName != null) 'Capt. ${reg.captainName}',
                        '${reg.squad.length} players',
                        _appliedAgo,
                      ].join(' · '),
                      maxLines: 2,
                      style: CkType.body(
                        fontSize: 11.5,
                        height: 1.4,
                        color: CkColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((reg.message ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            // The manager's note is quoted: a hairline rule and italics, so it
            // reads as their voice rather than the app's.
            Container(
              padding: const EdgeInsets.only(left: 11),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: CkColors.line, width: 2),
                ),
              ),
              child: Text(
                '“${reg.message!.trim()}”',
                style: CkType.body(
                  fontSize: 12,
                  height: 1.45,
                  color: CkColors.ink2,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          if ((entryFee ?? 0) > 0) ...[
            const SizedBox(height: 9),
            // A toggle, not a payment — and the row says so.
            Material(
              color: CkColors.paper2,
              borderRadius: BorderRadius.circular(CkRadii.sm),
              child: InkWell(
                onTap: onTogglePaid,
                borderRadius: BorderRadius.circular(CkRadii.sm),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isPaid ? 'Fee marked paid' : 'Mark fee as paid',
                              style: CkType.display(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'PKR ${money.format(entryFee)} · collected by '
                              'you offline',
                              style: CkType.body(
                                fontSize: 11,
                                color: CkColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _PaidToggle(on: _isPaid),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: _CardButton(
                  label: 'Decline',
                  icon: Icons.close,
                  // The only red on this screen, earned because declining is
                  // destructive. Text and icon, never a fill.
                  foreground: CkColors.red,
                  onTap: onDecline,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                flex: 14,
                child: _CardButton(
                  label: 'Approve Team',
                  icon: Icons.check,
                  foreground: CkColors.paper,
                  fill: CkColors.ink,
                  onTap: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 44×26 pill toggle, matching the canvas rather than a Material Switch.
class _PaidToggle extends StatelessWidget {
  const _PaidToggle({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: on ? CkColors.greenInk : CkColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: on ? CkColors.greenInk : CkColors.line),
      ),
      child: Align(
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: on ? CkColors.paper : CkColors.soft,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onTap,
    this.fill,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final VoidCallback onTap;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill ?? Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: fill == null ? Border.all(color: CkColors.line) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: foreground,
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

// ─── Approved ────────────────────────────────────────────────────────────────

class _ApprovedList extends StatefulWidget {
  const _ApprovedList({
    required this.approved,
    required this.onTogglePaid,
    required this.heading,
  });

  final List<TournamentRegistration> approved;
  final void Function(TournamentRegistration) onTogglePaid;
  final String heading;

  @override
  State<_ApprovedList> createState() => _ApprovedListState();
}

class _ApprovedListState extends State<_ApprovedList> {
  static const _collapsedCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.approved;
    final shown = _expanded ? all : all.take(_collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          widget.heading,
          action: all.length > _collapsedCount
              ? (_expanded ? 'Show fewer' : 'Show all')
              : null,
          onAction: () => setState(() => _expanded = !_expanded),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(CkRadii.md),
            border: Border.all(color: CkColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) Container(height: 1, color: CkColors.hairline),
                _ApprovedRow(
                  position: i + 1,
                  reg: shown[i],
                  onTogglePaid: () => widget.onTogglePaid(shown[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ApprovedRow extends StatelessWidget {
  const _ApprovedRow({
    required this.position,
    required this.reg,
    required this.onTogglePaid,
  });

  final int position;
  final TournamentRegistration reg;
  final VoidCallback onTogglePaid;

  bool get _isPaid => (reg.paymentStatus ?? '').toLowerCase() == 'paid';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '${reg.seedNumber ?? position}',
              style: CkType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: CkColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _Crest(reg: reg, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reg.teamName ?? 'Team',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${reg.squad.length} players',
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
          if (_isPaid)
            const _PaidPill()
          else
            TextButton(
              onPressed: onTogglePaid,
              style: TextButton.styleFrom(
                foregroundColor: CkColors.amberDark,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'Mark paid',
                style: CkType.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.amberDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WaitlistRow extends StatelessWidget {
  const _WaitlistRow({required this.reg, required this.onPromote});

  final TournamentRegistration reg;
  final VoidCallback onPromote;

  @override
  Widget build(BuildContext context) {
    // Dashed outline: the team is not in the draw yet.
    return CkDashedBox(
      radius: CkRadii.md,
      color: CkColors.line,
      fill: CkColors.paper,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
        children: [
          _Crest(reg: reg, size: 32, muted: true),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reg.teamName ?? 'Team',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink2,
                  ),
                ),
                Text(
                  'Draw is full · promoted if a team drops out',
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
              ],
            ),
          ),
          Material(
            color: CkColors.ink,
            borderRadius: BorderRadius.circular(7),
            child: InkWell(
              onTap: onPromote,
              borderRadius: BorderRadius.circular(7),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                child: Text(
                  'PROMOTE',
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.paper,
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest({required this.reg, this.size = 36, this.muted = false});

  final TournamentRegistration reg;
  final double size;

  /// The waitlist draws its crest recessed — the team is not in yet.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final name = reg.teamName ?? 'Team';
    final monogram = reg.teamMonogram ??
        (name.trim().split(RegExp(r'\s+')).length == 1
            ? name.characters.take(2).toString()
            : name
                .trim()
                .split(RegExp(r'\s+'))
                .take(2)
                .map((w) => w.characters.first)
                .join());

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        shape: BoxShape.circle,
        border: Border.all(color: muted ? CkColors.soft : CkColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        monogram.toUpperCase(),
        style: CkType.display(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: muted ? CkColors.muted : CkColors.ink,
        ),
      ),
    );
  }
}

class _PaidPill extends StatelessWidget {
  const _PaidPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CkColors.greenSoft,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'PAID',
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10,
          // Darker than greenInk: this sits on the solid green pill, not on
          // the pale green surface the chips use.
          color: const Color(0xFF1E5A2C),
        ),
      ),
    );
  }
}

/// Artboard 24b — the state an organiser meets first.
class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({
    required this.tournament,
    required this.onShare,
    required this.onInviteTeams,
  });

  final Tournament tournament;
  final VoidCallback onShare;
  final VoidCallback onInviteTeams;

  @override
  Widget build(BuildContext context) {
    final minToStart = tournament.minTeams ?? 4;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      children: [
        Text(
          'No applications yet',
          textAlign: TextAlign.center,
          style: CkType.display(fontSize: 19),
        ),
        const SizedBox(height: 8),
        Text(
          'Your cup is listed in Explore, but nobody has applied. Most weekend '
          'cups fill within 48 hours of the organiser sharing the link.',
          textAlign: TextAlign.center,
          style: CkType.body(
            fontSize: 13,
            height: 1.55,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: onShare,
          style: ElevatedButton.styleFrom(
            backgroundColor: CkColors.ink,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CkRadii.sm),
            ),
          ),
          child: Text(
            'Share the link',
            style: CkType.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CkColors.paper,
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onInviteTeams,
          style: OutlinedButton.styleFrom(
            foregroundColor: CkColors.ink,
            side: const BorderSide(color: CkColors.line),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CkRadii.sm),
            ),
          ),
          child: Text(
            'Invite specific teams',
            style: CkType.body(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Fixtures unlock once $minToStart teams are approved.',
          textAlign: TextAlign.center,
          style: CkType.body(fontSize: 12, color: CkColors.soft),
        ),
      ],
    );
  }
}
