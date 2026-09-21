import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../teams/domain/entities/roster_member.dart';
import '../../../teams/domain/entities/team_membership.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../../teams/presentation/providers/team_membership_providers.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_player.dart';
import '../providers/matches_providers.dart';
import '../widgets/lineup_picker.dart';
import 'result_screen.dart' show battingFirstIsTeamA;

/// Innings break: shows the chase target and lets the batting captain pick the
/// second-innings openers + opening bowler, then starts the chase.
class InningsBreakScreen extends ConsumerStatefulWidget {
  const InningsBreakScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<InningsBreakScreen> createState() => _InningsBreakScreenState();
}

class _InningsBreakScreenState extends ConsumerState<InningsBreakScreen> {
  String? _strikerId;
  String? _nonStrikerId;
  String? _bowlerId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    // When the chasing team starts the 2nd innings, the match flips to 'live';
    // move everyone (including the waiting side / spectators) onto the innings-2
    // scoreboard. A finished match routes to the result.
    ref.listen(liveMatchProvider(widget.matchId), (prev, next) {
      switch (next.value?.status) {
        case MatchStatus.live:
          context.go('/matches/${widget.matchId}/score?innings=2');
        case MatchStatus.completed:
        case MatchStatus.abandoned:
        case MatchStatus.walkover:
          context.go('/matches/${widget.matchId}/result');
        case _:
          break;
      }
    });

    final match = ref.watch(liveMatchProvider(widget.matchId)).value;
    if (match == null) {
      return const Scaffold(
        backgroundColor: CkColors.paper,
        body: Center(child: CircularProgressIndicator(color: CkColors.ink)),
      );
    }
    final inns1 = ref.watch(liveInningsStateProvider(widget.matchId, 1)).value;
    final players =
        ref.watch(matchPlayersProvider(widget.matchId)).value ??
        const <MatchPlayer>[];
    final rosterA =
        ref.watch(rosterProvider(match.teamAId.value)).value ??
        const <RosterMember>[];
    final rosterB =
        ref.watch(rosterProvider(match.teamBId.value)).value ??
        const <RosterMember>[];
    // Name and avatar come off the lineup row, which resolves them at the data
    // boundary — guests and substitutes have no roster entry to be named by.
    // The roster is consulted only for the permanent jersey number.
    String nameOf(MatchPlayer p) => p.displayName;
    final jerseyByRef = <String, int?>{
      for (final m in rosterA) m.member.playerId: m.member.jerseyNumber,
      for (final m in rosterB) m.member.playerId: m.member.jerseyNumber,
    };

    // Team A batting first => team B bats the 2nd innings, and vice versa.
    final battingSide =
        battingFirstIsTeamA(match) ? MatchTeamSide.b : MatchTeamSide.a;
    final batters =
        players.where((p) => p.teamSide == battingSide).toList()..sort(
          (a, b) => (a.battingOrder ?? 99).compareTo(b.battingOrder ?? 99),
        );
    final bowlers = players.where((p) => p.teamSide != battingSide).toList();

    final target = (inns1?.totalRuns ?? 0) + 1;

    // Only the team batting the SECOND innings sets its openers + opening
    // bowler and starts the chase. The side that just batted (and spectators)
    // get a read-only "waiting" view — they must not pick the chasing team's
    // lineup. Mirrors the scoring screen's batting-side gate.
    final battingTeamId =
        battingSide == MatchTeamSide.a ? match.teamAId : match.teamBId;
    final battingTeam = ref.watch(teamProvider(battingTeamId.value)).value;
    final currentUserId =
        ref.watch(supabaseClientProvider).auth.currentUser?.id;
    // Match-day authority, not just staff: the captain of the side coming out
    // to bat is exactly who sets up the next innings. `isManagedBy` (removed
    // 2026-09-10) could not see them, so a captain-only user hit a dead
    // button at the innings break.
    final memberships =
        ref.watch(currentUserTeamMembershipsProvider).value ??
        const <TeamMembership>[];
    final canSetup =
        battingTeam != null &&
        currentUserId != null &&
        memberships.any(
          (membership) =>
              membership.team.id == battingTeamId &&
              membership.relationship.hasMatchAuthority,
        );

    final ready =
        _strikerId != null &&
        _nonStrikerId != null &&
        _bowlerId != null &&
        _strikerId != _nonStrikerId &&
        !_busy;

    final mpById = <String, MatchPlayer>{
      for (final p in batters) p.id.value: p,
      for (final p in bowlers) p.id.value: p,
    };
    String? slotName(String? mpId) {
      final p = mpId == null ? null : mpById[mpId];
      return p == null ? null : nameOf(p);
    }

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Text('INNINGS BREAK', style: CkType.mono(fontSize: 12)),
            const SizedBox(height: 10),
            Text('Target $target', style: CkType.display(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              inns1 == null
                  ? ''
                  : 'Chasing ${inns1.totalRuns}/${inns1.totalWickets}',
              style: CkType.body(fontSize: 14, color: CkColors.muted),
            ),
            const SizedBox(height: 24),
            if (canSetup) ...[
              // Same tap-to-pick lineup UI as the first-innings Match Start:
              // slot cards on top, tap a roster row to fill the next slot.
              Row(
                children: [
                  Expanded(
                    child: LineupSlotCard(
                      label: 'ON STRIKE',
                      value: slotName(_strikerId),
                      hot: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LineupSlotCard(
                      label: 'NON-STRIKER',
                      value: slotName(_nonStrikerId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LineupSlotCard(
                      label: 'BOWLER',
                      value: slotName(_bowlerId),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('OPENERS — TAP TO PICK', style: CkType.mono(fontSize: 11)),
              const SizedBox(height: 4),
              for (final p in batters)
                LineupRosterRow(
                  name: nameOf(p),
                  photoUrl: p.photoUrl,
                  jersey: jerseyByRef[p.playerRefId],
                  badge:
                      _strikerId == p.id.value
                          ? 'STR'
                          : _nonStrikerId == p.id.value
                          ? 'NS'
                          : null,
                  onTap: () => setState(() => _tapBatter(p.id.value)),
                ),
              const SizedBox(height: 22),
              Text('OPENING BOWLER', style: CkType.mono(fontSize: 11)),
              const SizedBox(height: 4),
              for (final p in bowlers)
                LineupRosterRow(
                  name: nameOf(p),
                  photoUrl: p.photoUrl,
                  jersey: jerseyByRef[p.playerRefId],
                  badge: _bowlerId == p.id.value ? 'BWL' : null,
                  onTap:
                      () => setState(
                        () =>
                            _bowlerId =
                                _bowlerId == p.id.value ? null : p.id.value,
                      ),
                ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: ready ? () => _start(target) : null,
                child:
                    _busy
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CkColors.paper,
                          ),
                        )
                        : const Text('Start the chase'),
              ),
            ] else
              _WaitingForChase(teamName: battingTeam?.name),
          ],
        ),
      ),
    );
  }

  // Tap-to-fill openers: striker first, then non-striker. Tapping a chosen
  // opener clears them; tapping a new name when both slots are full replaces
  // the striker. (setState is owned by the caller.)
  void _tapBatter(String id) {
    if (_strikerId == id) {
      _strikerId = null;
    } else if (_nonStrikerId == id) {
      _nonStrikerId = null;
    } else if (_strikerId == null) {
      _strikerId = id;
    } else if (_nonStrikerId == null) {
      _nonStrikerId = id;
    } else {
      _strikerId = id;
    }
  }

  Future<void> _start(int target) async {
    setState(() => _busy = true);
    // The target has to travel. Without it `match_innings_state.target` stays
    // null, the engine's `targetReached` can never fire, and the chase runs to
    // its full quota of overs even after the runs are knocked off — the most
    // common way a limited-overs match ends simply would not register.
    final result = await ref
        .read(matchesRepositoryProvider)
        .startInnings(
          matchId: MatchId(widget.matchId),
          inningsNumber: 2,
          strikerId: _strikerId!,
          nonStrikerId: _nonStrikerId!,
          bowlerId: _bowlerId!,
          target: target,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(f.message))),
      (_) => context.go('/matches/${widget.matchId}/score?innings=2'),
    );
  }
}

/// Read-only innings-break view for everyone who is NOT on the chasing team —
/// the side that just batted, and spectators. They see the target but cannot
/// pick the chasing team's lineup or start the chase.
class _WaitingForChase extends StatelessWidget {
  const _WaitingForChase({this.teamName});

  final String? teamName;

  @override
  Widget build(BuildContext context) {
    final who =
        (teamName == null || teamName!.isEmpty)
            ? 'The chasing team'
            : teamName!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(CkRadii.md),
        border: Border.all(color: CkColors.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, size: 22, color: CkColors.muted),
          const SizedBox(height: 10),
          Text(
            '$who is choosing their openers',
            textAlign: TextAlign.center,
            style: CkType.body(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The chase begins once they are ready.',
            textAlign: TextAlign.center,
            style: CkType.body(fontSize: 13, color: CkColors.muted),
          ),
        ],
      ),
    );
  }
}
