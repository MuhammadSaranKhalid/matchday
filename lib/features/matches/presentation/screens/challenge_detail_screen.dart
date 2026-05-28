import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_request.dart';
import '../../domain/usecases/accept_match_challenge.dart';
import '../../domain/usecases/decline_match_challenge.dart';
import '../providers/matches_providers.dart';
import '../providers/my_matches_providers.dart';

/// Receiver-side detail. Shows the sender's proposed terms, the head-to-head
/// proxy line, and a sticky bottom reply bar with Decline / Counter / Accept.
class ChallengeDetailScreen extends ConsumerStatefulWidget {
  const ChallengeDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState
    extends ConsumerState<ChallengeDetailScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchChallengeProvider(widget.requestId));
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: async.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: CkColors.ink)),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (req) => req == null
              ? const Center(child: Text('Challenge not found'))
              : _body(req),
        ),
      ),
    );
  }

  Widget _body(MatchRequest req) {
    final from = ref.watch(teamProvider(req.fromTeamId.value)).value;
    final to = req.toTeamId == null
        ? null
        : ref.watch(teamProvider(req.toTeamId!.value)).value;

    final actionable = req.isPending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(onBack: () => context.pop(), kicker: 'INCOMING CHALLENGE'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            children: [
              _Hero(req: req, from: from, to: to),
              const SizedBox(height: 14),
              _Spec(req: req),
              if (req.message != null && req.message!.isNotEmpty) ...[
                const SizedBox(height: 14),
                _Note(text: req.message!),
              ],
              if (!actionable) ...[
                const SizedBox(height: 14),
                _StatusBanner(status: req.status),
              ],
            ],
          ),
        ),
        if (actionable)
          _ReplyBar(
            busy: _busy,
            onDecline: () => _onDecline(req),
            onCounter: () => context.push('/challenges/${req.id.value}/counter'),
            onAccept: () => _onAccept(req),
          ),
      ],
    );
  }

  Future<void> _onAccept(MatchRequest req) async {
    setState(() => _busy = true);
    final result = await ref.read(acceptMatchChallengeUseCaseProvider).call(
          AcceptMatchChallengeParams(requestId: req.id),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (matchId) {
        ref.invalidate(myMatchChallengesProvider);
        ref.invalidate(myMatchesViewProvider);
        context.go('/matches/${matchId.value}/start');
      },
    );
  }

  Future<void> _onDecline(MatchRequest req) async {
    final picked = await showModalBottomSheet<_DeclineResult>(
      context: context,
      backgroundColor: CkColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => const _DeclineSheet(),
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    final result = await ref.read(declineMatchChallengeUseCaseProvider).call(
          DeclineMatchChallengeParams(
            requestId: req.id,
            decisionReason: picked.reason,
            decisionNote: picked.note,
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ref.invalidate(myMatchChallengesProvider);
        context.go('/');
      },
    );
  }
}

// ─── Atoms ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.kicker});
  final VoidCallback onBack;
  final String kicker;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(bottom: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
        ),
        const SizedBox(width: 4),
        Text(
          kicker,
          style: CkType.mono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: CkColors.muted,
          ),
        ),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.req, required this.from, required this.to});
  final MatchRequest req;
  final Team? from;
  final Team? to;

  @override
  Widget build(BuildContext context) {
    final start = req.effectiveStartTime;
    final venue = req.effectiveVenue;
    final timeLabel = start == null
        ? 'No date proposed'
        : '${_dow(start)} ${start.day} · ${_hhmm(start)}';

    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: CkColors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('CHALLENGE',
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.paper,
                  )),
            ),
            const Spacer(),
            Text(timeLabel,
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: CkColors.muted,
                )),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Crest(team: from, fallback: 'A'),
              Text('vs',
                  style: CkType.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: CkColors.muted,
                    letterSpacing: -0.025,
                  )),
              _Crest(team: to, fallback: 'B'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${from?.name ?? 'Sender'}  vs  ${to?.name ?? 'You'}',
            textAlign: TextAlign.center,
            style: CkType.display(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.01,
            ),
          ),
          if (venue != null) ...[
            const SizedBox(height: 4),
            Text(venue,
                textAlign: TextAlign.center,
                style: CkType.body(fontSize: 12, color: CkColors.muted)),
          ],
        ],
      ),
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest({required this.team, required this.fallback});
  final Team? team;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _teamColor(team?.primaryColor),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(_short(team, fallback: fallback),
          style: CkType.display(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: CkColors.paper,
          )),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({required this.req});
  final MatchRequest req;

  @override
  Widget build(BuildContext context) {
    final f = req.effectiveFormat;
    final start = req.effectiveStartTime;
    Widget row(String key, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            SizedBox(
              width: 64,
              child: Text(key.toUpperCase(),
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: CkColors.muted,
                  )),
            ),
            Expanded(
              child: Text(value,
                  style: CkType.body(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ]),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border.all(color: CkColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (f != null)
            row('Format',
                'T${f.oversPerInnings} · ${_ballName(f.ballType)} · '
                '${f.maxOversPerBowler} ov/bowler'),
          if (start != null) row('When', _human(start)),
          if (req.effectiveVenue != null) row('Venue', req.effectiveVenue!),
          row('Stakes', 'Friendly · no pot'),
          row('Type', 'Friendly'),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: CkColors.paper2,
        border: Border(
          left: BorderSide(color: CkColors.red, width: 3),
        ),
      ),
      child: Text(
        text,
        style: CkType.body(
          fontSize: 13,
          color: CkColors.ink2,
        ).copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final MatchRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchRequestStatus.accepted => ('Accepted — match created.', CkColors.green),
      MatchRequestStatus.declined => ('Declined.', CkColors.red),
      MatchRequestStatus.cancelled => ('Withdrawn by sender.', CkColors.muted),
      MatchRequestStatus.expired => ('Expired — too late to act.', CkColors.muted),
      _ => ('No longer actionable.', CkColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CkColors.paper,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(label,
          style: CkType.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.busy,
    required this.onDecline,
    required this.onCounter,
    required this.onAccept,
  });
  final bool busy;
  final VoidCallback onDecline;
  final VoidCallback onCounter;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      decoration: const BoxDecoration(
        color: CkColors.paper,
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(children: [
        Expanded(
          child: CkButton.secondary(
            label: 'Decline',
            onPressed: busy ? null : onDecline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CkButton.secondary(
            label: 'Counter',
            onPressed: busy ? null : onCounter,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: CkButton(
            label: 'Accept →',
            busy: busy,
            onPressed: busy ? null : onAccept,
          ),
        ),
      ]),
    );
  }
}

class _DeclineResult {
  const _DeclineResult({required this.reason, this.note});
  final DeclineReason reason;
  final String? note;
}

class _DeclineSheet extends StatefulWidget {
  const _DeclineSheet();

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
  DeclineReason _selected = DeclineReason.busy;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                  child: Text('DECLINE',
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
                'Why are you passing?',
                style: CkType.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025,
                ),
              ),
              const SizedBox(height: 14),
              for (final r in DeclineReason.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selected = r),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: CkColors.paper,
                        border: Border.all(
                          color: _selected == r
                              ? CkColors.ink
                              : CkColors.hairline,
                          width: _selected == r ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(
                          _selected == r
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color:
                              _selected == r ? CkColors.ink : CkColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r.label,
                              style: CkType.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ]),
                    ),
                  ),
                ),
              if (_selected == DeclineReason.other) ...[
                const SizedBox(height: 6),
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
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: CkColors.red,
                    foregroundColor: CkColors.paper,
                  ),
                  onPressed: () => Navigator.of(context).pop(_DeclineResult(
                    reason: _selected,
                    note: _noteCtrl.text.trim().isEmpty
                        ? null
                        : _noteCtrl.text.trim(),
                  )),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Decline & send reason'),
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

// ─── Helpers ─────────────────────────────────────────────────────────────

String _short(Team? t, {required String fallback}) {
  if (t == null) return fallback;
  final mono = t.logoMonogram;
  if (mono != null && mono.isNotEmpty) return mono.toUpperCase();
  final letters = t.name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join();
  return letters.isEmpty ? fallback : letters.toUpperCase();
}

Color _teamColor(String? hex) {
  if (hex == null || hex.isEmpty) return CkColors.muted;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(0xFF000000 | n);
  } else if (cleaned.length == 8) {
    final n = int.tryParse(cleaned, radix: 16);
    if (n != null) return Color(n);
  }
  return CkColors.muted;
}

String _dow(DateTime t) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _ballName(MatchBallType b) {
  switch (b) {
    case MatchBallType.leather:
      return 'Hardball';
    case MatchBallType.tape:
      return 'Tape ball';
    case MatchBallType.tennis:
      return 'Tennis';
  }
}

String _human(DateTime t) => '${_dow(t)} ${t.day} · ${_hhmm(t)}';
