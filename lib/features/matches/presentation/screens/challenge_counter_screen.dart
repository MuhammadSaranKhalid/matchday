import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../domain/entities/match_request.dart';
import '../providers/matches_providers.dart';

/// Receiver counter screen. The 0600 RPC `counter_match_request` is the only
/// path; v1 supports counter on date/time + venue (format counter is rare
/// and adds keyboard friction — leave for v2).
class ChallengeCounterScreen extends ConsumerStatefulWidget {
  const ChallengeCounterScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<ChallengeCounterScreen> createState() =>
      _ChallengeCounterScreenState();
}

class _ChallengeCounterScreenState
    extends ConsumerState<ChallengeCounterScreen> {
  DateTime? _newStart;
  final _venueCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _venueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchChallengeProvider(widget.requestId));
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: CkColors.ink),
          ),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (req) => req == null
              ? const Center(child: Text('Challenge not found'))
              : _body(req),
        ),
      ),
    );
  }

  Widget _body(MatchRequest req) {
    final origStart = req.proposedStartTime;
    final origVenue = req.proposedVenue;
    final changedStart = _newStart != null && _newStart != origStart;
    final changedVenue = _venueCtrl.text.trim().isNotEmpty &&
        _venueCtrl.text.trim() != (origVenue ?? '');
    final canSubmit = (changedStart || changedVenue) && !_busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          changeCount: (changedStart ? 1 : 0) + (changedVenue ? 1 : 0),
          onBack: () => context.pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            children: [
              _DiffRow(
                label: 'Time',
                original: origStart == null ? '—' : _human(origStart),
                value: _newStart == null ? null : _human(_newStart!),
                onTap: _pickStart,
              ),
              const SizedBox(height: 8),
              const _SectionLabel('New venue (optional)'),
              TextField(
                controller: _venueCtrl,
                decoration: InputDecoration(
                  hintText: origVenue ?? 'Type a different venue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: CkColors.hairline),
                  ),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              const _SectionLabel('Optional · why?'),
              TextField(
                controller: _noteCtrl,
                maxLength: 280,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Half the squad busy at 18:30. 16:00 works for us.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: CkColors.hairline),
                  ),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: CkColors.paper,
            border: Border(top: BorderSide(color: CkColors.hairline)),
          ),
          child: Row(children: [
            Expanded(
              child: CkButton.secondary(
                label: 'Cancel',
                onPressed: _busy ? null : () => context.pop(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: CkButton(
                label: 'Send counter →',
                busy: _busy,
                onPressed: canSubmit ? () => _submit(req) : null,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 30),
    );
    if (time == null || !mounted) return;
    setState(() {
      _newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit(MatchRequest req) async {
    setState(() => _busy = true);
    final result = await ref.read(counterMatchChallengeUseCaseProvider)(
          requestId: req.id,
          counteredStartTime: _newStart,
          counteredVenue: _venueCtrl.text.trim().isEmpty
              ? null
              : _venueCtrl.text.trim(),
          decisionNote: _noteCtrl.text.trim().isEmpty
              ? null
              : _noteCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ref.invalidate(myMatchChallengesProvider);
        ref.invalidate(matchChallengeProvider(req.id.value));
        context.go('/pavilion');
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.changeCount, required this.onBack});
  final int changeCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
            ),
            const SizedBox(width: 4),
            Text(
              'COUNTER · ${changeCount == 0 ? 'NO CHANGE' : '$changeCount CHANGE${changeCount == 1 ? '' : 'S'}'}',
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: changeCount == 0 ? CkColors.muted : CkColors.amber,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 0, 0),
            child: Text(
              'Propose a change',
              style: CkType.display(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.025,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.label,
    required this.original,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String original;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changed = value != null && value != original;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: changed ? CkColors.cream : CkColors.paper,
          border: Border.all(
              color: changed ? CkColors.amber : CkColors.hairline, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Text(label.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.muted,
                  )),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: CkType.body(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    if (changed) ...[
                      TextSpan(
                        text: original,
                        style: CkType.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: CkColors.muted,
                        ).copyWith(decoration: TextDecoration.lineThrough),
                      ),
                      const TextSpan(text: '  →  '),
                      TextSpan(text: value!),
                    ] else ...[
                      TextSpan(text: value ?? original),
                    ],
                  ],
                ),
              ),
            ),
            const Icon(Icons.edit_outlined, size: 16, color: CkColors.muted),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
      child: Text(label.toUpperCase(),
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: CkColors.muted,
          )),
    );
  }
}

String _human(DateTime t) {
  final dow =
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '$dow ${t.day} · $hh:$mm';
}
