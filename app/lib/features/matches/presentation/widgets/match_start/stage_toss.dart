import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../../teams/domain/entities/team_member.dart';
import '../../../../teams/presentation/providers/team_membership_providers.dart';
import '../../../../teams/presentation/providers/teams_providers.dart';
import '../../../domain/entities/match.dart';
import '../../controllers/match_room_controller.dart';
import '../../state/match_room_state.dart';
import '../../state/match_start_state.dart';
import 'match_start_atoms.dart';

/// Stage 1 — Interactive Toss Recording.
///
/// Faithfully reproduces the Match Day Stitch design:
///   1. 3D vintage cricket coin flip with heads/tails physics & shadow
///   2. Step 1: Who won the toss? (Team cards with coin call badge)
///   3. Step 2: Elected to... (Bat first / Bowl first cards)
///   4. Official Toss Confirmation banner
///   5. Sticky bottom "Confirm toss" button
class MatchStartTossStage extends ConsumerStatefulWidget {
  const MatchStartTossStage({
    super.key,
    required this.matchId,
    required this.state,
    required this.room,
  });

  final String matchId;
  final MatchStartState state;
  final MatchRoomState room;

  @override
  ConsumerState<MatchStartTossStage> createState() =>
      _MatchStartTossStageState();
}

class _MatchStartTossStageState extends ConsumerState<MatchStartTossStage> {
  TeamId? _pendingWinner;
  TossDecision? _pendingDecision;

  @override
  void initState() {
    super.initState();
    _pendingWinner =
        widget.state.pendingTossWinner ?? widget.state.match.tossWonBy;
    _pendingDecision =
        widget.state.pendingDecision ?? widget.state.match.tossDecision;
  }

  String _teamInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, math.min(2, name.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.state.match;
    final teamA = ref.watch(teamProvider(match.teamAId.value)).value;
    final teamB = ref.watch(teamProvider(match.teamBId.value)).value;

    final rosterA =
        ref.watch(rosterProvider(match.teamAId.value)).value ?? const [];
    final rosterB =
        ref.watch(rosterProvider(match.teamBId.value)).value ?? const [];

    String captainNameOf(TeamId id) {
      final roster = id == match.teamAId ? rosterA : rosterB;
      for (final r in roster) {
        if (r.member.hasRole(MemberRole.captain)) {
          final first = r.displayName.split(' ').first;
          return first;
        }
      }
      return 'Captain';
    }

    final nameA = teamA?.name ?? 'Team A';
    final nameB = teamB?.name ?? 'Team B';
    final codeA = _teamInitials(nameA);
    final codeB = _teamInitials(nameB);

    if (!widget.state.canRecordToss) {
      final setupTeamId = match.setupTeamId;
      final neutral = setupTeamId == null;
      final setupTeamName = setupTeamId == match.teamAId ? nameA : nameB;

      return Center(
        child: MatchStartWaitingCard(
          eyebrow:
              neutral
                  ? 'WAITING ON THE MATCH OFFICIAL'
                  : 'WAITING ON THE CRICKET SETUP TEAM',
          title:
              neutral
                  ? 'The assigned official will record the toss.'
                  : '$setupTeamName is running the toss.',
          body:
              neutral
                  ? 'They’ll record who won and whether the winner chose to bat or bowl.'
                  : 'The setup-side member will ask the winning side whether they want to bat or bowl, then submit both details here.',
        ),
      );
    }

    final winner = _pendingWinner ?? widget.state.pendingTossWinner;
    final decision = _pendingDecision ?? widget.state.pendingDecision;
    final winnerName =
        winner == match.teamAId
            ? nameA
            : (winner == match.teamBId ? nameB : null);

    return Column(
      children: [
        // Scrollable content canvas
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // 1. 3D Interactive Coin Toss
              const MatchStartCoinFlipper(),
              const SizedBox(height: 18),

              // 2. Step 1: Who won the toss?
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Who won the toss?',
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                  Text(
                    'STEP 1',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: CkColors.muted,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _TossTeamCard(
                      teamName: nameA,
                      captainName: captainNameOf(match.teamAId),
                      initials: codeA,
                      avatarColor: const Color(0xFF1B3D2F),
                      isSelected: winner == match.teamAId,
                      badgeLabel: winner == match.teamAId
                          ? 'Toss Winner'
                          : (winner == null ? 'Select' : 'Opponent'),
                      statusLabel: 'TEAM A',
                      onTap: () {
                        setState(() => _pendingWinner = match.teamAId);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TossTeamCard(
                      teamName: nameB,
                      captainName: captainNameOf(match.teamBId),
                      initials: codeB,
                      avatarColor: const Color(0xFF1E2330),
                      isSelected: winner == match.teamBId,
                      badgeLabel: winner == match.teamBId
                          ? 'Toss Winner'
                          : (winner == null ? 'Select' : 'Opponent'),
                      statusLabel: 'TEAM B',
                      onTap: () {
                        setState(() => _pendingWinner = match.teamBId);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Step 2: Elected to...
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Elected to..',
                    style: CkType.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                  Text(
                    'STEP 2',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: CkColors.muted,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'What did the winning captain decide?',
                style: CkType.body(fontSize: 11, color: CkColors.muted),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _TossDecisionCard(
                      title: 'Bat first',
                      subtitle: 'Set the match target',
                      icon: Icons.sports_cricket,
                      isSelected: decision == TossDecision.bat,
                      onTap: () =>
                          setState(() => _pendingDecision = TossDecision.bat),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TossDecisionCard(
                      title: 'Bowl first',
                      subtitle: 'Chase down total',
                      icon: Icons.sports_baseball,
                      isSelected: decision == TossDecision.bowl,
                      onTap: () =>
                          setState(() => _pendingDecision = TossDecision.bowl),
                    ),
                  ),
                ],
              ),

              // 4. Official Toss Confirmation Banner
              if (winnerName != null && decision != null) ...[
                const SizedBox(height: 18),
                _OfficialTossBanner(
                  winnerName: winnerName,
                  decision: decision,
                ),
              ],
            ],
          ),
        ),

        // 5. Sticky Bottom Action Bar
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
            height: 52,
            child: ElevatedButton(
              onPressed:
                  winner != null &&
                          decision != null &&
                          !widget.room.isCommandPending
                      ? () async {
                        final res = await ref
                            .read(
                              matchRoomControllerProvider(widget.matchId).notifier,
                            )
                            .submitToss(
                              wonByTeamId: winner.value,
                              decision: decision,
                            );
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
                backgroundColor: const Color(0xFF28241E),
                disabledBackgroundColor: const Color(0xFFE6E2DB),
                foregroundColor: const Color(0xFFFBF9F4),
                disabledForegroundColor: CkColors.muted,
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
                              color: Color(0xFFFBF9F4),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Syncing captains & openers...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      : const Text(
                        'Confirm toss',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D Coin Flipper Component
// ─────────────────────────────────────────────────────────────────────────────

enum CoinSide { heads, tails }

class MatchStartCoinFlipper extends StatefulWidget {
  const MatchStartCoinFlipper({
    super.key,
    this.initialSide = CoinSide.heads,
    this.onOutcomeChanged,
  });

  final CoinSide initialSide;
  final ValueChanged<CoinSide>? onOutcomeChanged;

  @override
  State<MatchStartCoinFlipper> createState() => MatchStartCoinFlipperState();
}

class MatchStartCoinFlipperState extends State<MatchStartCoinFlipper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  );

  bool _isFlipping = false;
  late CoinSide _currentSide = widget.initialSide;
  double _startAngle = 0.0;
  double _targetAngle = 0.0;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _startAngle = widget.initialSide == CoinSide.heads ? 0.0 : math.pi;
    _targetAngle = _startAngle;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> flip() async {
    if (_isFlipping) return;

    HapticFeedback.mediumImpact();

    // Independent, truly random 50/50 fair toss
    final nextSide = _random.nextBool() ? CoinSide.heads : CoinSide.tails;
    final currentIsHeads = _currentSide == CoinSide.heads;
    final nextIsHeads = nextSide == CoinSide.heads;

    // Spin 4 full revolutions (8 * pi) + half revolution (pi) if toggling face
    final deltaAngle =
        (4 * 2 * math.pi) + (currentIsHeads == nextIsHeads ? 0.0 : math.pi);

    setState(() {
      _isFlipping = true;
      _startAngle = _targetAngle % (2 * math.pi);
      _targetAngle = _startAngle + deltaAngle;
    });

    await _controller.forward(from: 0);

    if (mounted) {
      setState(() {
        _currentSide = nextSide;
        _isFlipping = false;
      });
      HapticFeedback.lightImpact();
      widget.onOutcomeChanged?.call(nextSide);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHeads = _currentSide == CoinSide.heads;
    final outcomeText = _isFlipping
        ? 'TOSS IN THE AIR...'
        : 'TOSS OUTCOME: ${isHeads ? 'HEADS' : 'TAILS'}';
    final helperText =
        _isFlipping ? 'Flipping high in match arena...' : 'Tap coin to toss';

    return Column(
      children: [
        GestureDetector(
          onTap: flip,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ground shadow beneath coin
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final progress = _controller.value;
                    final arc = math.sin(progress * math.pi);
                    final shadowScale = 1.0 - (arc * 0.45);
                    final shadowOpacity =
                        (0.35 - (arc * 0.22)).clamp(0.08, 0.4);

                    return Positioned(
                      bottom: 12,
                      child: Container(
                        width: 110 * shadowScale,
                        height: 18 * shadowScale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF24231F)
                              .withValues(alpha: shadowOpacity),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF24231F)
                                  .withValues(alpha: shadowOpacity),
                              blurRadius: 10 + (arc * 10),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // 3D Flipping Coin
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final progress = _controller.value;
                    final arc = math.sin(progress * math.pi);
                    // High vertical toss flight
                    final translateY = -85.0 * arc;
                    final scale = 1.0 + (arc * 0.22);

                    final curvedProgress = CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutCubic,
                    ).value;
                    final spinAngle = _isFlipping
                        ? _startAngle +
                            (_targetAngle - _startAngle) * curvedProgress
                        : (isHeads ? 0.0 : math.pi);

                    final normalizedAngle = spinAngle % (2 * math.pi);
                    final showFront =
                        normalizedAngle < (math.pi / 2) ||
                        normalizedAngle > (3 * math.pi / 2);

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..translateByDouble(0.0, translateY, 0.0, 1.0)
                        ..scaleByDouble(scale, scale, 1.0, 1.0)
                        ..rotateY(spinAngle),
                      child: Transform.flip(
                        flipX: !showFront,
                        child: Container(
                          width: 136,
                          height: 136,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEEDC9A),
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x60A0781E),
                                blurRadius: 28,
                                offset: Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Color(0x30000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              showFront
                                  ? 'assets/cricket/coin_heads.png'
                                  : 'assets/cricket/coin_tails.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFD4AF37),
                                alignment: Alignment.center,
                                child: Text(
                                  showFront ? 'HEADS' : 'TAILS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Outcome Status Pill
        GestureDetector(
          onTap: flip,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFE8E3DA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isFlipping
                        ? const Color(0xFFE94D3A)
                        : const Color(0xFFB8860B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  outcomeText,
                  style: CkType.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF24231F),
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isFlipping ? Icons.sync : Icons.touch_app_outlined,
                  size: 14,
                  color: CkColors.muted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          helperText,
          style: CkType.body(fontSize: 11, color: CkColors.muted),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1: Team Selection Card
// ─────────────────────────────────────────────────────────────────────────────

class _TossTeamCard extends StatelessWidget {
  const _TossTeamCard({
    required this.teamName,
    required this.captainName,
    required this.initials,
    required this.avatarColor,
    required this.isSelected,
    required this.badgeLabel,
    required this.statusLabel,
    required this.onTap,
  });

  final String teamName;
  final String captainName;
  final String initials;
  final Color avatarColor;
  final bool isSelected;
  final String badgeLabel;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF24231F) : const Color(0xFFE8E3DA),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Team Initial Badge Avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Check indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFF24231F)
                            : const Color(0xFFF1EEE7),
                    shape: BoxShape.circle,
                    border:
                        isSelected
                            ? null
                            : Border.all(color: const Color(0xFFE8E3DA)),
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
            const SizedBox(height: 8),

            // Team Name
            Text(
              teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF24231F),
              ),
            ),
            const SizedBox(height: 2),

            // Captain Name
            Text(
              'Capt. $captainName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CkType.body(fontSize: 11, color: CkColors.muted),
            ),
            const SizedBox(height: 10),

            // Bottom status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFFF1EEE7)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected
                              ? const Color(0xFF24231F)
                              : CkColors.muted,
                    ),
                  ),
                ),
                Text(
                  statusLabel,
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected
                            ? const Color(0xFFB8860B)
                            : CkColors.muted.withValues(alpha: 0.6),
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
// Step 2: Decision Card (Bat / Bowl)
// ─────────────────────────────────────────────────────────────────────────────

class _TossDecisionCard extends StatelessWidget {
  const _TossDecisionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF24231F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF24231F) : const Color(0xFFE8E3DA),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF24231F),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color:
                      isSelected
                          ? const Color(0xFFE94D3A)
                          : CkColors.muted.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF24231F),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color:
                    isSelected
                        ? const Color(0xFFE8E3DA).withValues(alpha: 0.85)
                        : CkColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Official Toss Confirmation Banner
// ─────────────────────────────────────────────────────────────────────────────

class _OfficialTossBanner extends StatelessWidget {
  const _OfficialTossBanner({
    required this.winnerName,
    required this.decision,
  });

  final String winnerName;
  final TossDecision decision;

  @override
  Widget build(BuildContext context) {
    final decisionLabel = decision == TossDecision.bat ? 'bat first' : 'bowl first';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E3DA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Red vertical accent stripe
          Container(
            width: 3.5,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE94D3A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          // Red flag icon in circle
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF1EEE7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.flag_outlined,
              size: 14,
              color: Color(0xFFE94D3A),
            ),
          ),
          const SizedBox(width: 10),

          // Text confirmation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OFFICIAL TOSS CONFIRMATION',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: CkColors.muted,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF24231F),
                    ),
                    children: [
                      TextSpan(
                        text: winnerName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text: ' won the toss and elected to ',
                      ),
                      TextSpan(
                        text: decisionLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE94D3A),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
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
