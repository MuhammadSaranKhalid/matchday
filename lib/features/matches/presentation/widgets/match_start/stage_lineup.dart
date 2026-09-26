import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../teams/presentation/providers/teams_providers.dart';
import '../../../domain/entities/match_player.dart';
import '../../controllers/match_room_controller.dart';
import '../../providers/match_start_providers.dart';
import '../../state/match_room_state.dart';
import '../../state/match_start_state.dart';
import '../../state/match_start_views.dart';
import '../match_room/add_match_player_sheet.dart';
import 'match_start_atoms.dart';

/// Stage 2 — Strategic Lineup & Opening Pair.
///
/// Implements both the Populated and Empty states from Stitch:
///   1. 22 YDS pitch runway with On-Strike and Non-Striker crease slots
///   2. Swap Ends action
///   3. Opening Bowler slot with new ball attack
///   4. Late arrival registration card
///   5. Bottom sheet roster selector with search & category filters
///   6. Start match kickoff action
class MatchStartLineupStage extends ConsumerStatefulWidget {
  const MatchStartLineupStage({
    super.key,
    required this.matchId,
    required this.state,
    required this.room,
  });

  final String matchId;
  final MatchStartState state;
  final MatchRoomState room;

  @override
  ConsumerState<MatchStartLineupStage> createState() =>
      _MatchStartLineupStageState();
}

class _MatchStartLineupStageState extends ConsumerState<MatchStartLineupStage> {
  String _teamInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, math.min(2, name.length)).toUpperCase();
  }

  void _openSelector({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<MatchStartLineupCandidate> candidates,
    required String? currentSelectedRefId,
    required ValueChanged<String> onSelected,
    String? disabledRefId,
    String? disabledReason,
    VoidCallback? onAddPlayer,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RosterSelectorSheet(
        title: title,
        subtitle: subtitle,
        candidates: candidates,
        initialSelectedRefId: currentSelectedRefId,
        disabledRefId: disabledRefId,
        disabledReason: disabledReason,
        onAddPlayer: onAddPlayer,
        onConfirmed: (refId) {
          Navigator.of(sheetContext).pop();
          onSelected(refId);
        },
      ),
    );
  }

  void _openAddPlayerSheet(BuildContext context, MatchTeamSide side) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AddMatchPlayerSheet(
          initialSide: side,
          onSubmit: (chosenSide, displayName, idempotencyKey) async {
            final res = await ref
                .read(matchRoomControllerProvider(widget.matchId).notifier)
                .addParticipant(
                  side: chosenSide,
                  displayName: displayName,
                  idempotencyKey: idempotencyKey,
                );
            if (!sheetContext.mounted) return;
            res.fold(
              (failure) => ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(content: Text(failure.message)),
              ),
              (_) {
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$displayName added to lineup')),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.canManageBattingSetup) {
      return const Center(
        child: MatchStartWaitingCard(
          eyebrow: 'WAITING ON THE BATTING SIDE',
          title: 'They’re selecting the openers.',
          body:
              'A team member with match setup permission, or the assigned match official, will lock the opening pair and start the match.',
        ),
      );
    }

    final match = widget.state.match;
    final battingTeamId = widget.state.battingTeamId ?? match.teamAId;
    final bowlingTeamId = widget.state.bowlingTeamId ?? match.teamBId;

    final battingTeam = ref.watch(teamProvider(battingTeamId.value)).value;
    final bowlingTeam = ref.watch(teamProvider(bowlingTeamId.value)).value;

    final battingTeamName = battingTeam?.name ?? 'Batting Team';
    final bowlingTeamName = bowlingTeam?.name ?? 'Fielding Team';
    final battingCode = _teamInitials(battingTeamName);
    final bowlingCode = _teamInitials(bowlingTeamName);

    final battingCandidates =
        ref.watch(matchStartLineupProvider(widget.matchId));
    final bowlingCandidates =
        ref.watch(matchStartBowlingLineupProvider(widget.matchId));

    MatchStartLineupCandidate? candidateOf(
      String? refId,
      List<MatchStartLineupCandidate> list,
    ) {
      if (refId == null) return null;
      for (final c in list) {
        if (c.refId == refId) return c;
      }
      return null;
    }

    final strikerCandidate =
        candidateOf(widget.state.striker, battingCandidates);
    final nonStrikerCandidate =
        candidateOf(widget.state.nonStriker, battingCandidates);
    final bowlerCandidate =
        candidateOf(widget.state.bowler, bowlingCandidates);

    final controller = ref.read(
      matchRoomControllerProvider(widget.matchId).notifier,
    );

    final isReady =
        widget.room.selectedStrikerId != null &&
        widget.room.selectedNonStrikerId != null &&
        widget.room.selectedStrikerId != widget.room.selectedNonStrikerId &&
        widget.room.selectedBowlerId != null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // Headline & Context
              Text(
                'Opening players',
                style: CkType.display(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF24231F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select the on-strike batter, non-striker, and opening bowler together before calling play.',
                style: CkType.body(
                  fontSize: 13,
                  color: CkColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // ── SECTION 1: Batting Openers ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24231F),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          battingCode,
                          style: CkType.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${battingTeamName.toUpperCase()} BATTING',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF24231F),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '1st Innings Openers',
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Opening Partnership Crease Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E3DA)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF24231F).withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Top header ribbon
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F5F0),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE8E3DA)),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.sports_cricket,
                            size: 16,
                            color: Color(0xFFE94D3A),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'OPENING PARTNERSHIP CREASE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: Color(0xFF24231F),
                            ),
                          ),
                          Spacer(),
                          Text(
                            'Stage 2/2',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7C776F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Crease Slots with 22 YDS pitch track
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Stack(
                        children: [
                          // 22 YDS vertical runway line
                          Positioned(
                            left: 31,
                            top: 48,
                            bottom: 48,
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 2,
                                    height: double.infinity,
                                    color: const Color(0xFFD4CEBF),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: const Color(0xFFD4CEBF),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '22 YDS',
                                      style: CkType.mono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: CkColors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Slots Column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Slot 1: On Strike
                              _CreaseSlotTile(
                                roleTag: 'ON STRIKE',
                                roleSubtext: 'Faces 1st Ball',
                                slotNumber: 'Slot 1',
                                candidate: strikerCandidate,
                                emptyTitle: 'Select opening striker',
                                emptySubtext: 'Choose batter · RHB / LHB',
                                isHot: true,
                                onTap: () => _openSelector(
                                  context: context,
                                  title: 'Select On-Strike Batter',
                                  subtitle: '$battingTeamName · Striker End',
                                  candidates: battingCandidates,
                                  currentSelectedRefId: widget.state.striker,
                                  disabledRefId: widget.state.nonStriker,
                                  disabledReason: 'Currently Non-Striker',
                                  onAddPlayer: () => _openAddPlayerSheet(
                                    context,
                                    battingTeamId == match.teamAId
                                        ? MatchTeamSide.a
                                        : MatchTeamSide.b,
                                  ),
                                  onSelected: (refId) {
                                    final mpId = widget.room.snapshot.participants
                                            .matchPlayerIdOf(refId) ??
                                        refId;
                                    controller.selectStriker(mpId);
                                  },
                                ),
                              ),

                              // Swap Ends Button
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      controller.swapBatters();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Swapped batter ends'),
                                          duration: Duration(milliseconds: 900),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(
                                          color: const Color(0xFFE8E3DA),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.04,
                                            ),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.swap_vert,
                                            size: 14,
                                            color: Color(0xFF7C776F),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'SWAP ENDS',
                                            style: CkType.mono(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF24231F),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Slot 2: Non-Striker
                              _CreaseSlotTile(
                                roleTag: 'NON-STRIKER',
                                roleSubtext: "Runner's End",
                                slotNumber: 'Slot 2',
                                candidate: nonStrikerCandidate,
                                emptyTitle: 'Select non-striker',
                                emptySubtext: "Partner at bowler's wicket",
                                isHot: false,
                                onTap: () => _openSelector(
                                  context: context,
                                  title: 'Select Non-Striker',
                                  subtitle: '$battingTeamName · Runner End',
                                  candidates: battingCandidates,
                                  currentSelectedRefId: widget.state.nonStriker,
                                  disabledRefId: widget.state.striker,
                                  disabledReason: 'Currently On Strike',
                                  onAddPlayer: () => _openAddPlayerSheet(
                                    context,
                                    battingTeamId == match.teamAId
                                        ? MatchTeamSide.a
                                        : MatchTeamSide.b,
                                  ),
                                  onSelected: (refId) {
                                    final mpId = widget.room.snapshot.participants
                                            .matchPlayerIdOf(refId) ??
                                        refId;
                                    controller.selectNonStriker(mpId);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── SECTION 2: Opening Bowler ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24231F),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          bowlingCode,
                          style: CkType.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${bowlingTeamName.toUpperCase()} FIELDING',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF24231F),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Opening Spell Attack',
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bowler Slot Card
              _BowlerSlotCard(
                candidate: bowlerCandidate,
                onTap: () => _openSelector(
                  context: context,
                  title: 'Select Opening Bowler',
                  subtitle: '$bowlingTeamName · Over 1 Spell',
                  candidates: bowlingCandidates,
                  currentSelectedRefId: widget.state.bowler,
                  onSelected: (refId) {
                    final mpId = widget.room.snapshot.participants
                            .matchPlayerIdOf(refId) ??
                        refId;
                    controller.selectBowler(mpId);
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ── Late Arrival Action Tile ─────────────────────────────────
              GestureDetector(
                onTap: () => _openAddPlayerSheet(
                  context,
                  battingTeamId == match.teamAId
                      ? MatchTeamSide.a
                      : MatchTeamSide.b,
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD4CEBF),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1EEE7),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_add,
                          size: 18,
                          color: Color(0xFF24231F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add player or late arrival for this match',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF24231F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Quickly register a teammate standing at boundary',
                              style: CkType.body(
                                fontSize: 11,
                                color: CkColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Color(0xFF7C776F),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Sticky Bottom Kickoff Console ────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBF9F4),
            border: Border(top: BorderSide(color: Color(0xFFE8E3DA))),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  isReady && !widget.room.isCommandPending
                      ? () async {
                        final res = await controller.startMatch();
                        if (!context.mounted) return;
                        res.fold(
                          (failure) => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(failure.message)),
                          ),
                          (_) {},
                        );
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF24231F),
                disabledBackgroundColor: const Color(0xFFE6E2DB),
                foregroundColor: const Color(0xFFFBF9F4),
                disabledForegroundColor: const Color(0xFF7C776F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  widget.state.isBusy
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Calling play...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start match — first ball',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.bolt, size: 18),
                        ],
                      ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Crease Slot Tile Component
// ─────────────────────────────────────────────────────────────────────────────

class _CreaseSlotTile extends StatelessWidget {
  const _CreaseSlotTile({
    required this.roleTag,
    required this.roleSubtext,
    required this.slotNumber,
    required this.candidate,
    required this.emptyTitle,
    required this.emptySubtext,
    required this.isHot,
    required this.onTap,
  });

  final String roleTag;
  final String roleSubtext;
  final String slotNumber;
  final MatchStartLineupCandidate? candidate;
  final String emptyTitle;
  final String emptySubtext;
  final bool isHot;
  final VoidCallback onTap;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, math.min(2, name.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isPopulated = candidate != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E3DA)),
        ),
        child: Column(
          children: [
            // Top tag row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isHot
                                ? const Color(0xFFF8EFE1)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border:
                            isHot
                                ? Border.all(color: const Color(0xFFEADBCC))
                                : Border.all(color: const Color(0xFFE8E3DA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHot) ...[
                            const Icon(
                              Icons.sports_cricket,
                              size: 11,
                              color: Color(0xFF8A6132),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            roleTag,
                            style: CkType.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color:
                                  isHot
                                      ? const Color(0xFF8A6132)
                                      : const Color(0xFF24231F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      roleSubtext,
                      style: CkType.body(fontSize: 11, color: CkColors.muted),
                    ),
                  ],
                ),
                Text(
                  isPopulated ? 'Change ⇅' : slotNumber,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isPopulated ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isPopulated
                            ? const Color(0xFF24231F)
                            : const Color(0xFF7C776F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content row
            if (isPopulated)
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE8E3DA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(candidate!.name),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF24231F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                candidate!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF24231F),
                                ),
                              ),
                            ),
                            if (candidate!.styleTag.trim().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFE8E3DA),
                                  ),
                                ),
                                child: Text(
                                  candidate!.styleTag,
                                  style: CkType.mono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF24231F),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          candidate!.statsSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.body(fontSize: 11, color: CkColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC5BFB3),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_outline,
                      size: 20,
                      color: Color(0xFF7C776F),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emptyTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF24231F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          emptySubtext,
                          style: CkType.body(fontSize: 11, color: CkColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8E3DA)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 13, color: Color(0xFF24231F)),
                        SizedBox(width: 3),
                        Text(
                          'Select',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF24231F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bowler Slot Card Component
// ─────────────────────────────────────────────────────────────────────────────

class _BowlerSlotCard extends StatelessWidget {
  const _BowlerSlotCard({
    required this.candidate,
    required this.onTap,
  });

  final MatchStartLineupCandidate? candidate;
  final VoidCallback onTap;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, math.min(2, name.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isPopulated = candidate != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E3DA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF24231F).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Ball Attack · Over 1',
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
                Text(
                  isPopulated ? 'Change ⇅' : 'Slot 3',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isPopulated ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isPopulated
                            ? const Color(0xFF24231F)
                            : const Color(0xFF7C776F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isPopulated)
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEBE8),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF4C7C2)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(candidate!.name),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC6382A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                candidate!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF24231F),
                                ),
                              ),
                            ),
                            if (candidate!.styleTag.trim().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EEE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  candidate!.styleTag,
                                  style: CkType.mono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF24231F),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          candidate!.statsSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CkType.body(fontSize: 11, color: CkColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Color(0xFF7C776F),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5F0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC5BFB3),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.sports_baseball,
                      size: 20,
                      color: Color(0xFF7C776F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select opening bowler',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF24231F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pace or spin attack to start match',
                          style: CkType.body(fontSize: 11, color: CkColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8E3DA)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 13, color: Color(0xFF24231F)),
                        SizedBox(width: 3),
                        Text(
                          'Select',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF24231F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Roster Selector Modal Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RosterSelectorSheet extends StatefulWidget {
  const _RosterSelectorSheet({
    required this.title,
    required this.subtitle,
    required this.candidates,
    required this.initialSelectedRefId,
    required this.onConfirmed,
    this.disabledRefId,
    this.disabledReason,
    this.onAddPlayer,
  });

  final String title;
  final String subtitle;
  final List<MatchStartLineupCandidate> candidates;
  final String? initialSelectedRefId;
  final ValueChanged<String> onConfirmed;
  final String? disabledRefId;
  final String? disabledReason;
  final VoidCallback? onAddPlayer;

  @override
  State<_RosterSelectorSheet> createState() => _RosterSelectorSheetState();
}

class _RosterSelectorSheetState extends State<_RosterSelectorSheet> {
  late String? _selectedRefId =
      widget.initialSelectedRefId == widget.disabledRefId
          ? null
          : widget.initialSelectedRefId;
  String _search = '';
  String _category = 'all';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, math.min(2, name.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.candidates.where((c) {
      if (_search.isNotEmpty &&
          !c.name.toLowerCase().contains(_search.toLowerCase()) &&
          !c.styleTag.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      if (_category == 'bat' && c.category != 'bat') return false;
      if (_category == 'bowl' && c.category != 'bowl') return false;
      if (_category == 'ar' && c.category != 'ar') return false;
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle & Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F5F0),
              border: Border(bottom: BorderSide(color: Color(0xFFE8E3DA))),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4CEBF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subtitle,
                          style: CkType.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: CkColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF24231F),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF7C776F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search and Filter Pills
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                // Search Field
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8E3DA)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: Color(0xFF7C776F),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _search = val),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF24231F),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search player by name or style...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9E9A92),
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_search.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _search = ''),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF7C776F),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Category filter pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterPill(
                        label: 'All Squad (${widget.candidates.length})',
                        isSelected: _category == 'all',
                        onTap: () => setState(() => _category = 'all'),
                      ),
                      const SizedBox(width: 6),
                      _FilterPill(
                        label: 'Batters',
                        isSelected: _category == 'bat',
                        onTap: () => setState(() => _category = 'bat'),
                      ),
                      const SizedBox(width: 6),
                      _FilterPill(
                        label: 'All-Rounders',
                        isSelected: _category == 'ar',
                        onTap: () => setState(() => _category = 'ar'),
                      ),
                      const SizedBox(width: 6),
                      _FilterPill(
                        label: 'Bowlers',
                        isSelected: _category == 'bowl',
                        onTap: () => setState(() => _category = 'bowl'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8E3DA)),

          if (widget.candidates.isNotEmpty &&
              widget.disabledRefId != null &&
              widget.candidates.every((c) => c.refId == widget.disabledRefId)) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4EB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEADBCC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF8A6132),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Second batter needed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A6132),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cricket rules require two distinct batters at the crease. Add another teammate to the lineup to proceed.',
                    style: CkType.body(
                      fontSize: 11,
                      color: const Color(0xFF8A6132),
                    ),
                  ),
                  if (widget.onAddPlayer != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onAddPlayer!();
                        },
                        icon: const Icon(Icons.person_add, size: 14),
                        label: const Text('Add player to lineup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF24231F),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD4CEBF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Roster candidates list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder:
                  (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFFE8E3DA),
                    indent: 52,
                  ),
              itemBuilder: (context, i) {
                final candidate = filtered[i];
                final isSelected = candidate.refId == _selectedRefId;
                final isDisabled = candidate.refId == widget.disabledRefId;

                return InkWell(
                  onTap: isDisabled
                      ? null
                      : () => setState(() => _selectedRefId = candidate.refId),
                  borderRadius: BorderRadius.circular(10),
                  child: Opacity(
                    opacity: isDisabled ? 0.45 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFFF8EFE1).withValues(alpha: 0.5)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            isSelected
                                ? Border.all(color: const Color(0xFFEADBCC))
                                : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : const Color(0xFFF1EEE7),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE8E3DA)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initials(candidate.name),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF24231F),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        candidate.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDisabled
                                              ? const Color(0xFF7C776F)
                                              : const Color(0xFF24231F),
                                        ),
                                      ),
                                    ),
                                    if (candidate.styleTag.trim().isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1EEE7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          candidate.styleTag,
                                          style: CkType.mono(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF24231F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isDisabled
                                      ? (widget.disabledReason ?? 'Already selected')
                                      : candidate.statsSummary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CkType.body(
                                    fontSize: 11,
                                    color: isDisabled
                                        ? const Color(0xFF8A6132)
                                        : CkColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isDisabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1EEE7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFE8E3DA),
                                ),
                              ),
                              child: Text(
                                widget.disabledReason ?? 'Selected',
                                style: CkType.mono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7C776F),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isSelected
                                        ? const Color(0xFF24231F)
                                        : Colors.transparent,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? const Color(0xFF24231F)
                                          : const Color(0xFFD4CEBF),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child:
                                  isSelected
                                      ? const Icon(
                                        Icons.check,
                                        size: 13,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Confirm button
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F5F0),
              border: Border(top: BorderSide(color: Color(0xFFE8E3DA))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed:
                    _selectedRefId != null &&
                            _selectedRefId != widget.disabledRefId
                        ? () => widget.onConfirmed(_selectedRefId!)
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24231F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE6E2DB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Confirm Selection',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.check, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF24231F) : const Color(0xFFF7F5F0),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF24231F)
                : const Color(0xFFE8E3DA),
          ),
        ),
        child: Text(
          label,
          style: CkType.mono(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF4A463F),
          ),
        ),
      ),
    );
  }
}
