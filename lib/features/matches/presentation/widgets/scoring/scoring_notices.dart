// Full-width states shown in place of the run pad, and the two whole-screen states for a match that will not load.
// Extracted from scoring_screen.dart, which had grown past 3,200
// lines. Purely presentational — no Riverpod, no repository access.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/ck_button.dart';

/// Full-screen loading for the match row. Carries a close affordance so a slow
/// or wedged load is never a trap.
class ScoringLoading extends StatelessWidget {
  const ScoringLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.close, color: CkColors.ink),
              ),
            ),
            const Center(
              child: CircularProgressIndicator(color: CkColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// The match row could not be loaded, or does not exist. Always offers a way
/// out, and a retry when retrying could plausibly help.
class ScoringLoadFailure extends StatelessWidget {
  const ScoringLoadFailure({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.close, color: CkColors.ink),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    'Can’t open this match',
                    textAlign: TextAlign.center,
                    style: CkType.display(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: CkType.body(
                      fontSize: 13,
                      color: CkColors.muted,
                      height: 1.45,
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 20),
                    CkButton(
                      label: 'Try again',
                      expand: false,
                      onPressed: onRetry,
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// Shown in place of the run pad / extras when the viewer is NOT on the team
// currently batting (the bowling side or a spectator). The scoreboard, batters,
// bowler and ball log above stay visible — only the input controls are hidden.
class ReadOnlyScoringNotice extends StatelessWidget {
  const ReadOnlyScoringNotice({super.key, this.battingTeamName});

  final String? battingTeamName;

  @override
  Widget build(BuildContext context) {
    final who = (battingTeamName == null || battingTeamName!.isEmpty)
        ? 'The batting team'
        : battingTeamName!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CkColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, size: 18, color: CkColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$who is scoring this innings. You have a read-only view.',
                style: CkType.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CkColors.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Replaces the run pad / extras whenever no bowler is set for the current over
// (innings start, or after a completed over). Tapping it opens the bowler
// picker. This is the hard gate that makes scoring-without-a-bowler impossible.
class SelectBowlerNotice extends StatelessWidget {
  const SelectBowlerNotice({super.key, 
    required this.onSelect,
    required this.isOpening,
  });

  final VoidCallback onSelect;
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: CkColors.amber,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_cricket, size: 18, color: CkColors.ink),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    isOpening
                        ? 'Select the opening bowler to start'
                        : 'Select the next bowler to continue',
                    textAlign: TextAlign.center,
                    style: CkType.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
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

// Shown when the innings has ended (all out / overs done). The screen routes
// to the innings break or result in the same frame, so this is a brief bridge
// rather than the run pad / bowler gate — never offer to score a dead innings.
class InningsCompleteNotice extends StatelessWidget {
  const InningsCompleteNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: CkColors.ink,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CkColors.paper,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Innings complete',
              style: CkType.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CkColors.paper,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ScoringToast extends StatelessWidget {
  const ScoringToast({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: CkColors.ink,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47141210),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        message,
        style: CkType.display(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: CkColors.paper,
        ),
      ),
    );
  }
}
