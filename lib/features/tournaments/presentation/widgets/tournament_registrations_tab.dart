import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_fee_entry.dart';
import '../../domain/entities/tournament_registration.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';

/// The ink the canvas uses for text on Seam Cream. `CkColors.amberDark` is a
/// different, darker value used elsewhere; 24e specifies this one.
const _creamInk = Color(0xFF8C5311);

/// "5k", "15k", "900" — the canvas states fees in thousands (24e).
String _money(double v) {
  if (v <= 0) return '0';
  return v >= 1000 ? '${(v / 1000).round()}k' : v.round().toString();
}

/// Console tab 1 — the confirmed-teams roster (artboard 24e).
///
/// The applications queue used to live here as a stack of approve/decline
/// cards. It now lives behind the nav-bar inbox icon, which is reachable from
/// all three tabs; what stays behind is a one-line stub so the queue is never
/// invisible, and the roster gets its full height back.
class TournamentRegistrationsTab extends ConsumerWidget {
  const TournamentRegistrationsTab({
    super.key,
    required this.tournament,
    required this.pending,
    required this.approved,
    required this.onShare,
    required this.onInviteTeams,
    this.statusLine,
  });

  final Tournament tournament;

  /// Still-waiting applications. The tab no longer lists them — it only says
  /// how many there are, and points at the inbox (artboard 24e).
  final List<TournamentRegistration> pending;
  final List<TournamentRegistration> approved;

  final VoidCallback onShare;
  final VoidCallback onInviteTeams;

  /// "Closes in 2 days · 6 of 8 approved" — cream, at the head of the queue.
  final String? statusLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pending.isEmpty && approved.isEmpty) {
      return _EmptyQueue(
        tournament: tournament,
        onShare: onShare,
        onInviteTeams: onInviteTeams,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Artboard 24e — registration requests inbox stub
        if (pending.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4ECDD),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFDED0AC)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${pending.length} '
                    '${pending.length == 1 ? 'REQUEST' : 'REQUESTS'} '
                    'AWAITING YOU',
                    style: CkType.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: const Color(0xFF8C5311),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () =>
                      context.push('/tournaments/${tournament.id}/requests'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'REVIEW',
                        style: CkType.mono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.06,
                          color: const Color(0xFF8C5311),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 13, color: Color(0xFF8C5311)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (statusLine != null) _StatusBanner(text: statusLine!),
        if (approved.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ApprovedList(
            tournament: tournament,
            approved: approved,
            heading: 'Confirmed teams · ${approved.length}',
          ),
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

class _ApprovedList extends ConsumerStatefulWidget {
  const _ApprovedList({
    required this.tournament,
    required this.approved,
    required this.heading,
  });

  final Tournament tournament;
  final List<TournamentRegistration> approved;
  final String heading;

  @override
  ConsumerState<_ApprovedList> createState() => _ApprovedListState();
}

class _ApprovedListState extends ConsumerState<_ApprovedList> {
  static const _collapsedCount = 6;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.approved;
    final shown = _expanded ? all : all.take(_collapsedCount).toList();
    final fee = widget.tournament.entryFee ?? 0;

    // The ledger is the only place a *part* payment is recorded, so the
    // summary and the row chips both read from it. Until it arrives the rows
    // fall back to the registration's coarse paid/unpaid flag.
    final ledger = ref.watch(
      tournamentFeeLedgerProvider(widget.tournament.id),
    );
    final byRegistration = <String, TournamentFeeEntry>{
      for (final e in ledger.value ?? const <TournamentFeeEntry>[])
        e.registrationId: e,
    };

    // Expected is what these teams owe, not what a full draw would owe: there
    // is no cap on entries any more (24f), so capacity cannot set the target.
    final expected = all.length * fee;
    final collected = all.fold<double>(0, (sum, r) {
      final entry = byRegistration[r.registrationId];
      if (entry != null) return sum + entry.amountPaid;
      return sum + (r.isPaid ? fee : 0);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionHeading(
                widget.heading,
                action: all.length > _collapsedCount
                    ? (_expanded ? 'Show fewer' : 'Show all')
                    : null,
                onAction: () => setState(() => _expanded = !_expanded),
              ),
            ),
            if (fee > 0)
              InkWell(
                onTap: () =>
                    context.push('/tournaments/${widget.tournament.id}/fees'),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Fees ${_money(collected)} / ${_money(expected)}',
                    style: CkType.mono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.04,
                      color: CkColors.muted,
                    ),
                  ),
                ),
              ),
          ],
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
                  tournament: widget.tournament,
                  position: i + 1,
                  reg: shown[i],
                  fee: byRegistration[shown[i].registrationId],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap a fee chip for the ledger; the overflow menu is shown at right.',
          style: CkType.body(fontSize: 11, color: CkColors.muted),
        ),
      ],
    );
  }
}

class _ApprovedRow extends ConsumerWidget {
  const _ApprovedRow({
    required this.tournament,
    required this.position,
    required this.reg,
    required this.fee,
  });

  final Tournament tournament;
  final int position;
  final TournamentRegistration reg;

  /// This team's ledger line, when the ledger has loaded. Null falls back to
  /// the registration's own coarse paid/unpaid flag.
  final TournamentFeeEntry? fee;

  bool get _isPaid =>
      fee?.state == FeeState.paid ||
      (fee == null && (reg.paymentStatus ?? '').toLowerCase() == 'paid');

  void _showTeamActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CkColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 12),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _Crest(reg: reg, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reg.teamName ?? 'Team',
                          style: CkType.display(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.01,
                          ),
                        ),
                        Text(
                          'Approved · ${reg.squad.length} players',
                          style: CkType.mono(
                            fontSize: 9.5,
                            color: CkColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFeeChip(context),
                ],
              ),
            ),
            const Divider(height: 1, color: CkColors.hairline),
            _ActionListTile(
              icon: Icons.shield_outlined,
              title: 'Open team profile',
              subtitle: 'Squad, past tournaments, form',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/teams/${reg.teamId}');
              },
            ),
            _ActionListTile(
              icon: Icons.groups_outlined,
              title: 'View squad · ${reg.squad.length} players',
              subtitle: '${reg.squad.length} players listed',
              onTap: () {
                Navigator.pop(ctx);
                _showSquadSheet(context);
              },
            ),
            if (reg.captainName != null || reg.registeredByName != null)
              _ActionListTile(
                icon: Icons.chat_bubble_outline,
                title: 'Message manager',
                subtitle: reg.registeredByName ?? reg.captainName ?? 'Manager',
                onTap: () => Navigator.pop(ctx),
              ),
            _ActionListTile(
              icon: Icons.payments_outlined,
              title: 'Payment history',
              subtitle: _isPaid
                  ? 'Fee paid in full'
                  : 'Fee pending offline collection',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/tournaments/${tournament.id}/fees');
              },
            ),
            _ActionListTile(
              icon: Icons.delete_outline,
              title: 'Remove from tournament',
              subtitle: 'Frees their fixtures · asks for a reason',
              color: CkColors.redInk,
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemove(context, ref);
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CkColors.hairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: CkType.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
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

  void _showSquadSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${reg.teamName} · Squad (${reg.squad.length})',
              style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: reg.squad.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: CkColors.hairline),
                itemBuilder: (c, idx) {
                  final name = reg.squad[idx].replaceAll('guest_', '*');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${idx + 1}',
                          style: CkType.mono(
                            fontSize: 11,
                            color: CkColors.muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(name, style: CkType.body(fontSize: 13)),
                        const Spacer(),
                        if (idx == 0)
                          Text(
                            'CAPT',
                            style: CkType.mono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: CkColors.muted,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CkColors.paper,
        title: Text(
          'Remove ${reg.teamName}?',
          style: CkType.display(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will remove the team from this tournament and free their slot.',
          style: CkType.body(fontSize: 13, color: CkColors.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: CkType.body(fontSize: 14, color: CkColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: CkType.body(fontSize: 14, color: CkColors.redInk)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tournamentsControllerProvider.notifier).rejectRegistration(
            tournament.id,
            reg.registrationId,
            'Removed by organiser',
          );
    }
  }

  /// Three states, not two (24e): a weekend cup is usually part-paid, and
  /// "5k / 15k" is the fact the organiser needs. Cream carries both of the
  /// unfinished states — money never turns red on this screen.
  Widget _buildFeeChip(BuildContext context) {
    final entry = fee;
    final label = _isPaid
        ? 'PAID'
        : entry != null && entry.state == FeeState.partial
            ? '${_money(entry.amountPaid)} / ${_money(entry.entryFee)}'
            : 'UNPAID';

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _isPaid ? CkColors.greenSoft : CkColors.cream,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _isPaid ? const Color(0xFFA9D9B2) : CkColors.creamBorder,
        ),
      ),
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.04,
          color: _isPaid ? const Color(0xFF1E5A2C) : _creamInk,
        ),
      ),
    );

    // The chip is a way in to the ledger, not a toggle. Marking a fee paid is
    // a bookkeeping entry with an amount and a channel, and 24c owns it.
    return InkWell(
      onTap: () => context.push('/tournaments/${tournament.id}/fees'),
      borderRadius: BorderRadius.circular(4),
      child: chip,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          _buildFeeChip(context),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 18, color: CkColors.muted),
            tooltip: 'Team options',
            visualDensity: VisualDensity.compact,
            onPressed: () => _showTeamActions(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ActionListTile extends StatelessWidget {
  const _ActionListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? CkColors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CkType.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: color ?? CkColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest({required this.reg, this.size = 36});

  final TournamentRegistration reg;
  final double size;

  /// The waitlist draws its crest recessed — the team is not in yet.

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
        border: Border.all(color: CkColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        monogram.toUpperCase(),
        style: CkType.display(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: CkColors.ink,
        ),
      ),
    );
  }
}

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
