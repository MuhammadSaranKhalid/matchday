import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament_fee_entry.dart';

/// What the organiser decided in the sheet.
class RecordPaymentOutcome {
  const RecordPaymentOutcome({
    required this.amountPaid,
    this.channel,
    this.reference,
  });

  /// The new cumulative figure for this registration, not a delta.
  final double amountPaid;
  final PaymentChannel? channel;
  final String? reference;
}

/// Artboard 24c, sheet — "Record offline payment".
///
/// The organiser is writing down money that already changed hands, so the
/// sheet reads as a receipt being filed rather than a payment being taken:
/// amount, how it arrived, a note, and a plain statement of what the ledger
/// will say afterwards.
Future<RecordPaymentOutcome?> showRecordPaymentSheet(
  BuildContext context, {
  required TournamentFeeEntry entry,
  FeeLedgerTotals? totals,
}) {
  return showModalBottomSheet<RecordPaymentOutcome>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Flat 32% ink scrim, no blur — the sheet convention from artboard 28.
    barrierColor: const Color(0x5229251E),
    builder: (_) => _RecordPaymentSheet(entry: entry, totals: totals),
  );
}

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({required this.entry, this.totals});

  final TournamentFeeEntry entry;
  final FeeLedgerTotals? totals;

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _reference;
  PaymentChannel _channel = PaymentChannel.cash;

  static final _money = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    // Pre-filled with the full outstanding amount: the common case is that the
    // manager has just settled up.
    final suggested = widget.entry.entryFee;
    _amount = TextEditingController(text: suggested.round().toString());
    _reference = TextEditingController(text: widget.entry.reference ?? '');
    _channel = widget.entry.channel ?? PaymentChannel.cash;
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  double get _entered => double.tryParse(_amount.text.trim()) ?? 0;

  bool get _valid =>
      _entered >= 0 &&
      (widget.entry.entryFee <= 0 || _entered <= widget.entry.entryFee);

  String? get _error {
    if (_amount.text.trim().isEmpty) return null;
    if (double.tryParse(_amount.text.trim()) == null) {
      return 'Enter the amount in figures.';
    }
    if (_entered < 0) return 'An amount cannot be negative.';
    if (widget.entry.entryFee > 0 && _entered > widget.entry.entryFee) {
      return 'That is more than the '
          'PKR ${_money.format(widget.entry.entryFee)} entry fee.';
    }
    return null;
  }

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop(
      RecordPaymentOutcome(
        amountPaid: _entered,
        channel: _channel,
        reference: _reference.text.trim().isEmpty
            ? null
            : _reference.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final already = entry.amountPaid;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: CkColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Record offline payment',
                  style: CkType.display(
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  already > 0
                      ? '${entry.teamName} · PKR ${_money.format(already)} of '
                          '${_money.format(entry.entryFee)} already received'
                      : '${entry.teamName} · PKR '
                          '${_money.format(entry.entryFee)} entry fee',
                  style: CkType.body(fontSize: 12.5, color: CkColors.muted),
                ),

                const SizedBox(height: 16),
                const _Label('Amount received · PKR'),
                const SizedBox(height: 7),
                _AmountField(
                  controller: _amount,
                  outstanding: entry.outstanding,
                  onChanged: () => setState(() {}),
                ),
                if (_error case final message?) ...[
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: CkType.body(
                      fontSize: 11.5,
                      color: CkColors.redInk,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _AmountPresets(
                  entry: entry,
                  entered: _entered,
                  onPick: (value) => setState(() {
                    _amount.text = value.round().toString();
                  }),
                ),

                const SizedBox(height: 16),
                const _Label('Payment channel'),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final c in PaymentChannel.values)
                      if (c != PaymentChannel.other)
                        _Pill(
                          label: c.label,
                          selected: _channel == c,
                          onTap: () => setState(() => _channel = c),
                        ),
                  ],
                ),

                const SizedBox(height: 16),
                const _Label('Reference / note'),
                const SizedBox(height: 7),
                _ReferenceField(controller: _reference),

                const SizedBox(height: 14),
                _AfterSaving(
                  entry: entry,
                  entered: _entered,
                  totals: widget.totals,
                ),

                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _valid ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CkColors.ink,
                      foregroundColor: CkColors.paper,
                      disabledBackgroundColor: CkColors.paper2,
                      disabledForegroundColor: CkColors.soft,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Save Payment Record',
                      style: CkType.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _valid ? CkColors.paper : CkColors.soft,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CkColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: CkType.mono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: CkColors.muted,
        ),
      );
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.outstanding,
    required this.onChanged,
  });

  final TextEditingController controller;
  final double outstanding;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        children: [
          Text(
            'PKR',
            style: CkType.mono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlignVertical: TextAlignVertical.center,
              style: CkType.mono(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CkColors.ink,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'REMAINING',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: CkColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The three quick amounts. "Other" simply focuses the field — it is a hint
/// that free entry is allowed, not a fourth value.
class _AmountPresets extends StatelessWidget {
  const _AmountPresets({
    required this.entry,
    required this.entered,
    required this.onPick,
  });

  final TournamentFeeEntry entry;
  final double entered;
  final ValueChanged<double> onPick;

  static final _money = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final outstanding = entry.outstanding;
    final full = entry.entryFee;

    final options = <(String, double)>[
      if (outstanding > 0 && outstanding != full)
        (_money.format(outstanding), outstanding),
      if (full > 0) ('${_money.format(full)} · full', full),
    ];

    if (options.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final (label, value) in options)
          _MonoPill(
            label: label,
            selected: entered == value,
            onTap: () => onPick(value),
          ),
        _MonoPill(
          label: 'Other',
          selected: !options.any((o) => o.$2 == entered),
          onTap: () {},
        ),
      ],
    );
  }
}

class _ReferenceField extends StatelessWidget {
  const _ReferenceField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: TextField(
        controller: controller,
        maxLines: 2,
        maxLength: 200,
        style: CkType.body(fontSize: 12.5, height: 1.5, color: CkColors.ink),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          filled: false,
          counterText: '',
          contentPadding: EdgeInsets.zero,
          hintText: 'e.g. Received at ground pavilion',
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

/// The cream consequence block. States what the ledger will read after saving,
/// so the organiser is not left computing it.
class _AfterSaving extends StatelessWidget {
  const _AfterSaving({
    required this.entry,
    required this.entered,
    this.totals,
  });

  final TournamentFeeEntry entry;
  final double entered;
  final FeeLedgerTotals? totals;

  static final _money = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final settled = entry.entryFee > 0 && entered >= entry.entryFee;
    final label = settled
        ? 'PAID · ${_money.format(entered)} / '
            '${_money.format(entry.entryFee)}'
        : 'PARTIAL · ${_money.format(entered)} / '
            '${_money.format(entry.entryFee)}';

    // The tournament-wide effect, when the caller passed the totals in.
    String? cupLine;
    final t = totals;
    if (t != null && t.expected > 0) {
      final after = t.collected - entry.amountPaid + entered;
      final percent = ((after / t.expected) * 100).round();
      cupLine = 'Tournament collected rises to PKR '
          '${_money.format(after)} ($percent%). ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'AFTER SAVING',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.10,
                    color: CkColors.amberDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: CkType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: settled ? CkColors.greenInk : CkColors.amberInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${cupLine ?? ''}The manager gets a receipt with your name and '
            'today’s date; entries stay editable afterwards.',
            style: CkType.body(
              fontSize: 12,
              height: 1.5,
              color: CkColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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

class _MonoPill extends StatelessWidget {
  const _MonoPill({
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
            horizontal: 11,
            vertical: selected ? 5.5 : 6,
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
            style: CkType.mono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? CkColors.ink : CkColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
