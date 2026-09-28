import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/match_official.dart';
import '../providers/tournaments_providers.dart';

/// Artboard 27j, sheet — "Assign umpire 2".
///
/// Returns the chosen candidate, or null if the organiser backed out.
Future<OfficialCandidate?> showAssignOfficialSheet(
  BuildContext context, {
  required String tournamentId,
  required String matchId,
  required OfficialRole role,
  required String matchLine,
  Set<String> alreadyAppointed = const {},
}) {
  return showModalBottomSheet<OfficialCandidate>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x5229251E),
    builder: (_) => _AssignOfficialSheet(
      tournamentId: tournamentId,
      matchId: matchId,
      role: role,
      matchLine: matchLine,
      alreadyAppointed: alreadyAppointed,
    ),
  );
}

enum _CandidateFilter { all, neutral, past }

class _AssignOfficialSheet extends ConsumerStatefulWidget {
  const _AssignOfficialSheet({
    required this.tournamentId,
    required this.matchId,
    required this.role,
    required this.matchLine,
    required this.alreadyAppointed,
  });

  final String tournamentId;
  final String matchId;
  final OfficialRole role;
  final String matchLine;
  final Set<String> alreadyAppointed;

  @override
  ConsumerState<_AssignOfficialSheet> createState() =>
      _AssignOfficialSheetState();
}

class _AssignOfficialSheetState extends ConsumerState<_AssignOfficialSheet> {
  final _search = TextEditingController();

  // Neutral-first is the default because the rule the organiser is trying to
  // satisfy — "both umpires from neutral clubs" — is stated one screen back.
  _CandidateFilter _filter = _CandidateFilter.neutral;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<OfficialCandidate> _visible(List<OfficialCandidate> all) {
    final query = _search.text.trim().toLowerCase();
    return all.where((c) {
      if (widget.alreadyAppointed.contains(c.userId)) return false;
      final passesFilter = switch (_filter) {
        _CandidateFilter.all => true,
        _CandidateFilter.neutral => c.isNeutral,
        _CandidateFilter.past => c.matchesOfficiated > 0,
      };
      if (!passesFilter) return false;
      if (query.isEmpty) return true;
      return c.displayName.toLowerCase().contains(query) ||
          (c.username?.toLowerCase().contains(query) ?? false) ||
          (c.clubName?.toLowerCase().contains(query) ?? false);
    }).toList()
      // Most experienced first — the organiser is picking on track record.
      ..sort((a, b) => b.matchesOfficiated.compareTo(a.matchesOfficiated));
  }

  @override
  Widget build(BuildContext context) {
    final candidates = ref.watch(
      officialCandidatesProvider(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: CkColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SafeArea(
          top: false,
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
                'Assign ${widget.role.label.toLowerCase()}',
                style: CkType.display(
                  fontSize: 20,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.matchLine,
                style: CkType.body(fontSize: 12.5, color: CkColors.muted),
              ),

              const SizedBox(height: 13),
              _SearchField(
                controller: _search,
                onChanged: () => setState(() {}),
              ),

              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in _CandidateFilter.values) ...[
                      _Chip(
                        label: switch (f) {
                          _CandidateFilter.all => 'All officials',
                          _CandidateFilter.neutral => 'Neutral clubs only',
                          _CandidateFilter.past => 'Past scorers',
                        },
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                      if (f != _CandidateFilter.values.last)
                        const SizedBox(width: 7),
                    ],
                  ],
                ),
              ),

              Flexible(
                child: switch (candidates) {
                  AsyncLoading() => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: CkColors.ink),
                      ),
                    ),
                  AsyncError(:final error) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 34),
                      child: Center(
                        child: Text(
                          '$error',
                          textAlign: TextAlign.center,
                          style: CkType.body(
                            fontSize: 12.5,
                            color: CkColors.muted,
                          ),
                        ),
                      ),
                    ),
                  AsyncData(value: final all) => _CandidateList(
                      visible: _visible(all),
                      total: all.length,
                      filter: _filter,
                    ),
                },
              ),

              const SizedBox(height: 10),
              // Nothing behind this yet — the invite path is its own ticket —
              // so it says what it will do rather than pretending to do it.
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Inviting officials who are not on matchday is not '
                        'available yet.',
                      ),
                    ),
                  );
                },
                child: Text(
                  'Invite someone not on Matchday',
                  style: CkType.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
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

class _CandidateList extends StatelessWidget {
  const _CandidateList({
    required this.visible,
    required this.total,
    required this.filter,
  });

  final List<OfficialCandidate> visible;
  final int total;
  final _CandidateFilter filter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            filter == _CandidateFilter.neutral
                ? '${visible.length} available · '
                    'members of both sides hidden'
                : '${visible.length} of $total available',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.08,
              color: CkColors.muted,
            ),
          ),
        ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              filter == _CandidateFilter.neutral
                  ? 'Nobody neutral is free. Switch to All officials to see '
                      'everyone at this cup.'
                  : 'Nobody matches that search.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 12.5,
                height: 1.5,
                color: CkColors.muted,
              ),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: visible.length,
              itemBuilder: (_, i) => _CandidateRow(candidate: visible[i]),
            ),
          ),
      ],
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate});

  final OfficialCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final club = candidate.clubName;
    final busy = candidate.busyOn;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CkColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CkColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(color: CkColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              candidate.monogram,
              style: CkType.display(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
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
                        candidate.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CkType.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (candidate.isNeutral) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_outlined,
                        size: 13,
                        color: CkColors.greenInk,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  busy != null
                      // Shown, not enforced: a small cup often runs on one
                      // person and the organiser knows their ground.
                      ? 'Also on $busy'
                      : [
                          if (club != null && club.isNotEmpty) club,
                          '${candidate.matchesOfficiated} matches officiated',
                        ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CkType.body(
                    fontSize: 11,
                    color: busy != null ? CkColors.amberInk : CkColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: CkColors.paper,
            borderRadius: BorderRadius.circular(999),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(candidate),
              child: Container(
                height: 32,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: CkColors.ink),
                ),
                child: Text(
                  'Assign',
                  style: CkType.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: CkColors.surface,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 17, color: CkColors.soft),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              style: CkType.body(fontSize: 13, color: CkColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search registered umpires & scorers…',
                hintStyle: CkType.body(fontSize: 13, color: CkColors.soft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: selected ? 7 : 7.5,
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
