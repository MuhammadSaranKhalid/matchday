import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/ck_button.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/match.dart';
import '../../domain/usecases/accept_match.dart';
import '../../domain/usecases/decline_match.dart';
import '../providers/matches_providers.dart';

enum _View { review, acceptXi, decline }

/// The opponent captain's side of a friendly: review → accept (pick team B's
/// XI) or decline (reason). Propose-changes and the roster-gap resolver are v1.1.
class MatchRequestScreen extends ConsumerStatefulWidget {
  const MatchRequestScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<MatchRequestScreen> createState() => _MatchRequestScreenState();
}

class _MatchRequestScreenState extends ConsumerState<MatchRequestScreen> {
  _View _view = _View.review;
  final Set<String> _picked = {};
  String? _captain;
  String? _keeper;
  String? _reason;
  bool _busy = false;

  static const _reasons = [
    "Date doesn't work",
    'Players unavailable',
    'Venue too far',
    "Format doesn't suit",
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchProvider(widget.matchId));
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: switch (async) {
          AsyncData(:final value?) => _body(value),
          AsyncData() => const Center(child: Text('Match not found')),
          AsyncError() => const Center(child: Text('Could not load match')),
          _ => const Center(
              child: CircularProgressIndicator(color: CkColors.ink)),
        },
      ),
    );
  }

  Widget _body(Match match) {
    final myTeams = ref.watch(myTeamsProvider).value ?? const [];
    final managesB = myTeams.any((t) => t.id == match.teamBId);
    final managesA = myTeams.any((t) => t.id == match.teamAId);

    final header = _Header(onBack: () => context.pop());

    if (match.status != MatchStatus.pending) {
      return _centered(header, '${_statusLabel(match.status)} match',
          'This match is no longer awaiting a response.');
    }
    if (!managesB) {
      return _centered(
        header,
        managesA ? 'Awaiting reply' : 'Match request',
        managesA
            ? 'Waiting for the opponent to accept or decline.'
            : 'Only the opponent captain can respond to this request.',
      );
    }

    return switch (_view) {
      _View.review => _ReviewView(
          match: match,
          onAccept: () => setState(() => _view = _View.acceptXi),
          onDecline: () => setState(() => _view = _View.decline),
          header: header,
        ),
      _View.acceptXi => _acceptXi(match),
      _View.decline => _declineView(match),
    };
  }

  // ─── Accept: pick team B's XI ───────────────────────────────────────────

  Widget _acceptXi(Match match) {
    final roster = ref.watch(rosterProvider(match.teamBId.value));
    final need = match.format.playersPerTeam;
    return switch (roster) {
      AsyncData(:final value) => _xiBody(match, value, need),
      _ => const Center(child: CircularProgressIndicator(color: CkColors.ink)),
    };
  }

  Widget _xiBody(Match match, List<RosterMember> members, int need) {
    if (members.length < need) {
      return Column(
        children: [
          _Header(onBack: () => setState(() => _view = _View.review)),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Your squad doesn't have enough players",
                        textAlign: TextAlign.center,
                        style: CkType.display(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text('${members.length} of $need needed.',
                        style:
                            CkType.body(fontSize: 14, color: CkColors.muted)),
                    const SizedBox(height: 16),
                    CkButton.secondary(
                      label: 'Manage team',
                      expand: false,
                      onPressed: () =>
                          context.push('/teams/${match.teamBId.value}/manage'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final complete =
        _picked.length == need && _captain != null && _picked.contains(_captain);
    return Column(
      children: [
        _Header(onBack: () => setState(() => _view = _View.review)),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lock your XI', style: CkType.display(fontSize: 22)),
              Text('${_picked.length} of $need',
                  style: CkType.mono(fontSize: 12, color: CkColors.muted)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: members.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: CkColors.hairline),
            itemBuilder: (_, i) {
              final m = members[i];
              final id = m.member.playerId;
              final sel = _picked.contains(id);
              return CheckboxListTile(
                value: sel,
                activeColor: CkColors.ink,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (_) => setState(() => _toggle(id, need)),
                title: Text(m.displayName,
                    style:
                        CkType.body(fontSize: 15, fontWeight: FontWeight.w500)),
                subtitle: sel
                    ? Row(children: [
                        _mini('Captain', _captain == id,
                            () => setState(() => _captain = _captain == id ? null : id)),
                        const SizedBox(width: 8),
                        _mini('Keeper', _keeper == id,
                            () => setState(() => _keeper = _keeper == id ? null : id)),
                      ])
                    : null,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: CkButton(
            label: 'Confirm — accept match',
            busy: _busy,
            onPressed: complete ? () => _accept(match, need) : null,
          ),
        ),
      ],
    );
  }

  void _toggle(String id, int need) {
    if (_picked.contains(id)) {
      _picked.remove(id);
      if (_captain == id) _captain = null;
      if (_keeper == id) _keeper = null;
    } else if (_picked.length < need) {
      _picked.add(id);
    }
  }

  Future<void> _accept(Match match, int need) async {
    setState(() => _busy = true);
    final result = await ref.read(acceptMatchUseCaseProvider).call(
          AcceptMatchParams(
            id: match.id,
            playersPerTeam: need,
            squad: _picked.toList(),
            captain: _captain!,
            keeper: _keeper,
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => _snack(f.message),
      (_) {
        _snack('Match confirmed');
        context.go('/match');
      },
    );
  }

  // ─── Decline ────────────────────────────────────────────────────────────

  Widget _declineView(Match match) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(onBack: () => setState(() => _view = _View.review)),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: Text('Decline this match', style: CkType.display(fontSize: 24)),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Pick a reason (optional). They only see the reason.',
              style: CkType.body(fontSize: 14, color: CkColors.muted)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _reasons)
                    GestureDetector(
                      onTap: () => setState(() => _reason = _reason == r ? null : r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _reason == r ? CkColors.ink : CkColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: _reason == r ? CkColors.ink : CkColors.line,
                              width: 1.5),
                        ),
                        child: Text(r,
                            style: CkType.body(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _reason == r
                                    ? CkColors.paper
                                    : CkColors.ink)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: CkButton(
            label: _reason == null ? 'Decline without reason' : 'Decline & send reason',
            busy: _busy,
            onPressed: () => _decline(match),
          ),
        ),
      ],
    );
  }

  Future<void> _decline(Match match) async {
    setState(() => _busy = true);
    final result = await ref
        .read(declineMatchUseCaseProvider)
        .call(DeclineMatchParams(id: match.id, reason: _reason));
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => _snack(f.message),
      (_) {
        _snack('Match declined');
        context.go('/match');
      },
    );
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Widget _mini(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active ? CkColors.ink : CkColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? CkColors.ink : CkColors.line),
          ),
          child: Text(label,
              style: CkType.mono(
                  fontSize: 10,
                  color: active ? CkColors.paper : CkColors.muted)),
        ),
      );

  Widget _centered(Widget header, String title, String sub) => Column(
        children: [
          header,
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        textAlign: TextAlign.center,
                        style: CkType.display(fontSize: 22)),
                    const SizedBox(height: 6),
                    Text(sub,
                        textAlign: TextAlign.center,
                        style: CkType.body(fontSize: 14, color: CkColors.muted)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  String _statusLabel(MatchStatus s) =>
      s.name[0].toUpperCase() + s.name.substring(1);
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
          ),
        ),
      );
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({
    required this.match,
    required this.onAccept,
    required this.onDecline,
    required this.header,
  });
  final Match match;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final f = match.format;
    final rows = <(String, String)>[
      ('FORMAT',
          'T${f.oversPerInnings} · ${f.playersPerTeam}-a-side · ${f.ballType.name}'),
      ('MAX OVERS', '${f.maxOversPerBowler} per bowler'),
      if (match.venue != null)
        ('WHERE',
            [match.venue!.ground, if (match.venue!.city != null) match.venue!.city!]
                .join(' · ')),
      if (match.scheduledStartTime != null)
        ('WHEN', _fmt(match.scheduledStartTime!)),
      ('THEIR XI', '${match.teamASquad.length} players pencilled in'),
    ];
    return Column(
      children: [
        header,
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            children: [
              Text('Match request', style: CkType.display(fontSize: 26)),
              const SizedBox(height: 4),
              Text('A captain wants to play your team.',
                  style: CkType.body(fontSize: 14, color: CkColors.muted)),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: CkColors.surface,
                  borderRadius: BorderRadius.circular(CkRadii.md),
                  border: Border.all(color: CkColors.hairline),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      Container(
                        decoration: BoxDecoration(
                          border: i == 0
                              ? null
                              : const Border(
                                  top: BorderSide(color: CkColors.hairline)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 90,
                                child: Text(rows[i].$1,
                                    style: CkType.mono(
                                        fontSize: 10, color: CkColors.muted))),
                            Expanded(
                                child: Text(rows[i].$2,
                                    style: CkType.body(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              CkButton(label: 'Accept · pick XI', onPressed: onAccept),
              const SizedBox(height: 8),
              CkButton.ghost(label: 'Decline', onPressed: onDecline),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmt(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} · $h:$mm $ap';
  }
}
