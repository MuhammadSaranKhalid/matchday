import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_fee_entry.dart';
import '../controllers/tournaments_controller.dart';
import '../providers/tournaments_providers.dart';
import '../widgets/record_payment_sheet.dart';

/// Artboard 24c — the payment reconciliation ledger.
///
/// Fees are collected in cash at the ground, so this is a bookkeeping surface,
/// not a dunning screen: **money never turns red here**. Unpaid is neutral
/// paper, a near deadline is amber, and every amount, date and percentage is
/// mono so columns of PKR line up.
class TournamentFeeLedgerScreen extends ConsumerStatefulWidget {
  const TournamentFeeLedgerScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<TournamentFeeLedgerScreen> createState() =>
      _TournamentFeeLedgerScreenState();
}

enum _LedgerFilter { all, paid, partial, unpaid }

class _TournamentFeeLedgerScreenState
    extends ConsumerState<TournamentFeeLedgerScreen> {
  _LedgerFilter _filter = _LedgerFilter.all;

  /// Paid teams collapse behind "3 more paid teams" — the ledger's job is the
  /// money still moving, not a roll of honour.
  bool _showAllPaid = false;

  static final _money = NumberFormat.decimalPattern();

  Future<void> _record(TournamentFeeEntry entry) async {
    // Hand the sheet the cup-wide totals so its "After saving" block can state
    // what the tournament collects afterwards, rather than only this team.
    final rows = ref.read(tournamentFeeLedgerProvider(widget.tournamentId)).value;
    final outcome = await showRecordPaymentSheet(
      context,
      entry: entry,
      totals: rows == null ? null : FeeLedgerTotals.from(rows),
    );
    if (outcome == null || !mounted) return;

    final ok = await ref.read(tournamentsControllerProvider.notifier).recordPayment(
          tournamentId: widget.tournamentId,
          registrationId: entry.registrationId,
          amountPaid: outcome.amountPaid,
          channel: outcome.channel,
          reference: outcome.reference,
        );
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Recorded PKR ${_money.format(outcome.amountPaid)} '
            'for ${entry.teamName}.',
          ),
        ),
      );
    } else {
      final state = ref.read(tournamentsControllerProvider);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: CkColors.redInk,
          content: Text(
            state.hasError ? '${state.error}' : 'That did not save.',
          ),
        ),
      );
    }
  }

  /// The design offers a reminder on an unpaid line. There is no dunning
  /// pipeline behind it and inventing one would be a different feature, so it
  /// goes out through the announcement path the organiser already uses.
  void _sendReminder(TournamentFeeEntry entry) {
    context.push(
      '/tournaments/${widget.tournamentId}/announce',
      extra: 'Reminder for ${entry.teamName}: PKR '
          '${_money.format(entry.outstanding)} of the entry fee is still '
          'outstanding. Please settle it before your next fixture.',
    );
  }

  void _exportCsv(List<TournamentFeeEntry> entries, Tournament? tournament) {
    final buffer = StringBuffer()
      ..writeln('Team,Status,Amount paid,Entry fee,Outstanding,'
          'Channel,Reference,Recorded on,Recorded by');
    for (final e in entries) {
      buffer.writeln([
        _csv(e.teamName),
        _csv(e.state.label),
        e.amountPaid.toStringAsFixed(0),
        e.entryFee.toStringAsFixed(0),
        e.outstanding.toStringAsFixed(0),
        _csv(e.channel?.label ?? ''),
        _csv(e.reference ?? ''),
        _csv(e.recordedAt == null
            ? ''
            : DateFormat('yyyy-MM-dd').format(e.recordedAt!)),
        _csv(e.recordedByName ?? ''),
      ].join(','));
    }

    final name = tournament?.name ?? 'Tournament';
    SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: '$name — fee ledger',
      ),
    );
  }

  static String _csv(String raw) {
    if (!raw.contains(',') && !raw.contains('"') && !raw.contains('\n')) {
      return raw;
    }
    return '"${raw.replaceAll('"', '""')}"';
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(tournamentFeeLedgerProvider(widget.tournamentId));
    final tournament =
        ref.watch(tournamentDetailProvider(widget.tournamentId)).value;

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _LedgerTopBar(
              subtitle: tournament?.name ?? '',
              onExport: switch (ledger) {
                AsyncData(value: final rows) when rows.isNotEmpty =>
                  () => _exportCsv(rows, tournament),
                _ => null,
              },
            ),
            Expanded(
              child: switch (ledger) {
                AsyncLoading() => const Center(
                    child: CircularProgressIndicator(color: CkColors.ink),
                  ),
                AsyncError(:final error) => _LedgerError(
                    message: '$error',
                    onRetry: () => ref.invalidate(
                      tournamentFeeLedgerProvider(widget.tournamentId),
                    ),
                  ),
                AsyncData(value: final rows) => _LedgerBody(
                    entries: rows,
                    filter: _filter,
                    showAllPaid: _showAllPaid,
                    onFilter: (f) => setState(() {
                      _filter = f;
                      _showAllPaid = false;
                    }),
                    onShowAllPaid: () => setState(() => _showAllPaid = true),
                    onRecord: _record,
                    onRemind: _sendReminder,
                    onExport: () => _exportCsv(rows, tournament),
                    onRefresh: () async => ref.invalidate(
                      tournamentFeeLedgerProvider(widget.tournamentId),
                    ),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chrome ───────────────────────────────────────────────────────────────────

class _LedgerTopBar extends StatelessWidget {
  const _LedgerTopBar({required this.subtitle, this.onExport});

  final String subtitle;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fee Ledger',
                  style: CkType.display(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _RoundButton(
            icon: Icons.ios_share,
            onTap: onExport,
            tooltip: 'Export CSV',
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: CkColors.paper2,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 17,
            color: onTap == null ? CkColors.soft : CkColors.ink,
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _LedgerBody extends StatelessWidget {
  const _LedgerBody({
    required this.entries,
    required this.filter,
    required this.showAllPaid,
    required this.onFilter,
    required this.onShowAllPaid,
    required this.onRecord,
    required this.onRemind,
    required this.onExport,
    required this.onRefresh,
  });

  final List<TournamentFeeEntry> entries;
  final _LedgerFilter filter;
  final bool showAllPaid;
  final ValueChanged<_LedgerFilter> onFilter;
  final VoidCallback onShowAllPaid;
  final ValueChanged<TournamentFeeEntry> onRecord;
  final ValueChanged<TournamentFeeEntry> onRemind;
  final VoidCallback onExport;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _LedgerEmpty();
    }

    final totals = FeeLedgerTotals.from(entries);

    // A free cup has nothing to reconcile; saying so beats a row of zeroes.
    if (totals.expected <= 0) {
      return const _FreeCup();
    }

    final paid = entries.where((e) => e.state == FeeState.paid).toList();
    final partial = entries.where((e) => e.state == FeeState.partial).toList();
    final unpaid = entries.where((e) => e.state == FeeState.unpaid).toList();

    final visible = switch (filter) {
      _LedgerFilter.all => entries,
      _LedgerFilter.paid => paid,
      _LedgerFilter.partial => partial,
      _LedgerFilter.unpaid => unpaid,
    };

    // On "All", settled teams collapse to a single line so the money still
    // moving stays at the top of the screen.
    final collapsePaid = filter == _LedgerFilter.all && !showAllPaid;
    final rows = collapsePaid
        ? visible.where((e) => e.state != FeeState.paid).toList()
        : visible;
    final hiddenPaid = collapsePaid ? paid.length : 0;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: CkColors.ink,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: _TotalsCard(totals: totals, entries: entries),
          ),
          _FilterRow(
            filter: filter,
            counts: {
              _LedgerFilter.all: entries.length,
              _LedgerFilter.paid: paid.length,
              _LedgerFilter.partial: partial.length,
              _LedgerFilter.unpaid: unpaid.length,
            },
            onFilter: onFilter,
          ),
          const Divider(height: 1, thickness: 1, color: CkColors.hairline),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 34),
              child: Center(
                child: Text(
                  'No teams in this bucket.',
                  style: CkType.body(fontSize: 13, color: CkColors.muted),
                ),
              ),
            )
          else
            for (final entry in rows)
              _LedgerRow(
                entry: entry,
                onRecord: () => onRecord(entry),
                onRemind: () => onRemind(entry),
              ),
          _LedgerFooter(
            hiddenPaid: hiddenPaid,
            onShowAllPaid: onShowAllPaid,
            onExport: onExport,
          ),
        ],
      ),
    );
  }
}

/// The cream card across the top: Expected · Collected · Outstanding, then the
/// progress rail. Collected is green-ink and Outstanding amber-ink — the two
/// darkened status hues this project already uses for small mono text.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals, required this.entries});

  final FeeLedgerTotals totals;
  final List<TournamentFeeEntry> entries;

  static final _money = NumberFormat.decimalPattern();

  /// "8 × 15,000" when every team owes the same, which is the normal case.
  String get _expectedNote {
    if (entries.isEmpty) return '';
    final fees = entries.map((e) => e.entryFee).toSet();
    if (fees.length == 1) {
      return '${entries.length} × ${_money.format(fees.first)}';
    }
    return '${entries.length} teams';
  }

  static String _compact(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      final text = k >= 100 || k == k.roundToDouble()
          ? k.round().toString()
          : k.toStringAsFixed(1);
      return '${text}k';
    }
    return v.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.creamBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Total(
                      label: 'Expected',
                      value: _money.format(totals.expected),
                      note: _expectedNote,
                      valueColor: CkColors.ink,
                      noteColor: CkColors.muted,
                    ),
                  ),
                  const _TotalDivider(),
                  Expanded(
                    child: _Total(
                      label: 'Collected',
                      value: _money.format(totals.collected),
                      note: '${totals.collectedPercent}%',
                      valueColor: CkColors.greenInk,
                      noteColor: CkColors.greenInk,
                    ),
                  ),
                  const _TotalDivider(),
                  Expanded(
                    child: _Total(
                      label: 'Outstanding',
                      value: _money.format(totals.outstanding),
                      // Amber, never red: the obligation is real but it is not
                      // an emergency, and money does not turn red here.
                      note: totals.unsettledTeams == 1
                          ? '1 team'
                          : '${totals.unsettledTeams} teams',
                      valueColor: CkColors.amberInk,
                      noteColor: CkColors.amberInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: CkColors.paper,
              border: Border(top: BorderSide(color: CkColors.creamBorder)),
            ),
            child: Row(
              children: [
                Text(
                  'PKR',
                  style: CkType.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.muted,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: totals.collectedFraction,
                      minHeight: 5,
                      backgroundColor: CkColors.hairline,
                      valueColor: const AlwaysStoppedAnimation(
                        CkColors.greenInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  '${_compact(totals.collected)} / '
                  '${_compact(totals.expected)}',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: CkColors.ink2,
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

class _TotalDivider extends StatelessWidget {
  const _TotalDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: CkColors.creamBorder,
      );
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    required this.note,
    required this.valueColor,
    required this.noteColor,
  });

  final String label;
  final String value;
  final String note;
  final Color valueColor;
  final Color noteColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CkType.mono(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.10,
            color: CkColors.muted,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: CkType.mono(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          note,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CkType.mono(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.06,
            color: noteColor,
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.counts,
    required this.onFilter,
  });

  final _LedgerFilter filter;
  final Map<_LedgerFilter, int> counts;
  final ValueChanged<_LedgerFilter> onFilter;

  static const _labels = {
    _LedgerFilter.all: 'All',
    _LedgerFilter.paid: 'Paid in full',
    _LedgerFilter.partial: 'Partial',
    _LedgerFilter.unpaid: 'Unpaid',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final f in _LedgerFilter.values) ...[
            _FilterChip(
              label: '${_labels[f]} (${counts[f] ?? 0})',
              selected: filter == f,
              onTap: () => onFilter(f),
            ),
            if (f != _LedgerFilter.values.last) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: selected ? 7 : 7.5),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? CkColors.ink : CkColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

/// One team's line. Three shapes, one per [FeeState] — the design gives each
/// its own treatment because the organiser is scanning for a different thing
/// in each case.
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.entry,
    required this.onRecord,
    required this.onRemind,
  });

  final TournamentFeeEntry entry;
  final VoidCallback onRecord;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          _Crest(entry: entry),
          const SizedBox(width: 11),
          Expanded(child: _Details(entry: entry)),
          const SizedBox(width: 10),
          _Action(entry: entry, onRecord: onRecord, onRemind: onRemind),
        ],
      ),
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest({required this.entry});

  final TournamentFeeEntry entry;

  @override
  Widget build(BuildContext context) {
    final url = entry.teamLogoUrl;
    return Container(
      width: 34,
      height: 34,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CkColors.paper2,
        shape: BoxShape.circle,
        border: Border.all(color: CkColors.line),
      ),
      alignment: Alignment.center,
      child: url == null || url.isEmpty
          ? Text(
              entry.monogram,
              style: CkType.display(fontSize: 11, fontWeight: FontWeight.w700),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              width: 34,
              height: 34,
              errorBuilder: (_, __, ___) => Text(
                entry.monogram,
                style:
                    CkType.display(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.entry});

  final TournamentFeeEntry entry;

  static final _money = NumberFormat.decimalPattern();

  /// The trailing grey line: how the money arrived, and when.
  String? get _provenance {
    if (entry.state == FeeState.unpaid) return null;
    final parts = <String>[];
    final channel = entry.channel;
    if (channel != null) {
      if (channel == PaymentChannel.cash && entry.recordedByName != null) {
        parts.add('Cash handed to ${entry.recordedByName}');
      } else {
        parts.add(channel.label);
      }
    }
    final ref = entry.reference;
    if (ref != null && ref.isNotEmpty) parts.add('ref $ref');
    final at = entry.recordedAt;
    if (at != null) parts.add(DateFormat('dd MMM').format(at));
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.teamName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CkType.display(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        switch (entry.state) {
          // Paid is a plain green-ink mono line — no chip. It is settled, so it
          // gets the least furniture on the row.
          FeeState.paid => Text(
              'PAID · ${_money.format(entry.amountPaid)}',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06,
                color: CkColors.greenInk,
              ),
            ),
          FeeState.partial => _StatusChip(
              label: 'Partial · ${_money.format(entry.amountPaid)} / '
                  '${_money.format(entry.entryFee)}',
              background: CkColors.cream,
              border: CkColors.creamBorder,
              foreground: CkColors.amberInk,
            ),
          // Unpaid is neutral paper, not red. Nothing has gone wrong yet.
          FeeState.unpaid => _StatusChip(
              label: 'Unpaid · ${_money.format(entry.entryFee)}',
              background: CkColors.paper2,
              border: CkColors.line,
              foreground: CkColors.ink2,
            ),
        },
        if (entry.state == FeeState.partial) ...[
          const SizedBox(height: 4),
          Text(
            'Remaining PKR ${_money.format(entry.outstanding)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.body(fontSize: 11, color: CkColors.muted),
          ),
        ] else if (_provenance case final line?) ...[
          const SizedBox(height: 2),
          Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CkType.body(fontSize: 11, color: CkColors.muted),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: CkType.mono(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: foreground,
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.entry,
    required this.onRecord,
    required this.onRemind,
  });

  final TournamentFeeEntry entry;
  final VoidCallback onRecord;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    switch (entry.state) {
      // Settled: a tick, and a tap that still opens the sheet so a wrong
      // entry can be corrected.
      case FeeState.paid:
        return Material(
          color: CkColors.paper2,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onRecord,
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.check, size: 17, color: CkColors.greenInk),
            ),
          ),
        );
      case FeeState.partial:
        return _OutlineAction(label: 'Record', onTap: onRecord);
      case FeeState.unpaid:
        // Amber text, no border — a nudge, not a demand.
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onRemind,
            onLongPress: onRecord,
            child: Container(
              height: 36,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Send reminder',
                style: CkType.body(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: CkColors.amberInk,
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CkColors.paper,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: CkColors.ink),
          ),
          child: Text(
            label,
            style: CkType.body(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: CkColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerFooter extends StatelessWidget {
  const _LedgerFooter({
    required this.hiddenPaid,
    required this.onShowAllPaid,
    required this.onExport,
  });

  final int hiddenPaid;
  final VoidCallback onShowAllPaid;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (hiddenPaid > 0)
            GestureDetector(
              onTap: onShowAllPaid,
              child: Text(
                hiddenPaid == 1
                    ? '1 more paid team'
                    : '$hiddenPaid more paid teams',
                style: CkType.body(fontSize: 11.5, color: CkColors.muted),
              ),
            ),
          const SizedBox(width: 9),
          const Expanded(child: Divider(height: 1, color: CkColors.hairline)),
          const SizedBox(width: 9),
          GestureDetector(
            onTap: onExport,
            child: Text(
              'Export CSV',
              style: CkType.mono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CkColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── The states nobody designs ────────────────────────────────────────────────

class _LedgerEmpty extends StatelessWidget {
  const _LedgerEmpty();

  @override
  Widget build(BuildContext context) => const _Notice(
        icon: Icons.receipt_long_outlined,
        title: 'No approved teams yet',
        body: 'The ledger fills up as you approve teams. Fees are yours to '
            'collect at the ground — matchday never holds the money.',
      );
}

class _FreeCup extends StatelessWidget {
  const _FreeCup();

  @override
  Widget build(BuildContext context) => const _Notice(
        icon: Icons.volunteer_activism_outlined,
        title: 'This cup is free to enter',
        body: 'There is no entry fee set, so there is nothing to reconcile. '
            'Add a fee in tournament settings if that changes.',
      );
}

class _LedgerError extends StatelessWidget {
  const _LedgerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Notice(
        icon: Icons.cloud_off_outlined,
        title: 'The ledger did not load',
        body: message,
        action: OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: CkColors.line),
            foregroundColor: CkColors.ink,
          ),
          child: const Text('Try again'),
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: CkColors.soft),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: CkType.display(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 12.5,
                height: 1.55,
                color: CkColors.muted,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
