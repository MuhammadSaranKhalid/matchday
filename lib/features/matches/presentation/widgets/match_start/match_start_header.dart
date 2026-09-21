import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../teams/presentation/providers/teams_providers.dart';
import '../../../../teams/presentation/widgets/team_crest.dart';
import '../../../domain/entities/match.dart';
import '../../state/match_start_state.dart';

/// Minimal back-arrow + title bar. Used by the screen's error state, where
/// there is no [MatchStartState] to build the full header from.
class MatchStartTopBar extends StatelessWidget {
  const MatchStartTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.chevron_left_rounded, color: CkColors.ink),
          ),
          Text(title, style: CkType.display(fontSize: 20)),
        ],
      ),
    );
  }
}

/// The Match Start header: step counter, countdown pill, progress bar,
/// phase headline, and the viewer's role strip.
class MatchStartHeader extends StatelessWidget {
  const MatchStartHeader({super.key, required this.state});

  final MatchStartState state;

  String get _title => switch (state.phase) {
        MatchStartPhase.toss => 'The toss.',
        MatchStartPhase.lineup ||
        MatchStartPhase.ready => state.isViewerBattingCaptain
            ? 'Pick your openers.'
            : 'Waiting on the batting team.',
        MatchStartPhase.live => 'Live.',
      };

  @override
  Widget build(BuildContext context) {
    final countdown = matchStartCountdownLabel(
      state.match.scheduledStartTime,
      DateTime.now(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: CkColors.paper,
            border: Border(bottom: BorderSide(color: CkColors.hairline)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: CkColors.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'MATCH START · ${state.stepIndex + 1}/$matchStartStepCount',
                    style: CkType.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: CkColors.muted,
                    ),
                  ),
                  const Spacer(),
                  if (countdown != null) _CountdownPill(label: countdown),
                ],
              ),
              const SizedBox(height: 8),
              _ProgressBar(stepIndex: state.stepIndex),
              const SizedBox(height: 14),
              Text(
                _title,
                style: CkType.display(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        _PhonePill(state: state),
      ],
    );
  }
}

class _PhonePill extends ConsumerWidget {
  const _PhonePill({required this.state});

  final MatchStartState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (teamId, roleLabel) = switch (state.viewerRole) {
      MatchStartViewerRole.captain => (state.captainOf, 'CAPTAIN'),
      MatchStartViewerRole.battingCaptain => (
          state.battingTeamId,
          'BATTING CAPTAIN',
        ),
      MatchStartViewerRole.bowlingCaptain => (
          state.bowlingTeamId,
          'BOWLING CAPTAIN',
        ),
      MatchStartViewerRole.spectator => (null, 'SPECTATOR'),
    };
    if (teamId == null) return const SizedBox.shrink();

    final team = ref.watch(teamProvider(teamId.value)).value;

    return Container(
      width: double.infinity,
      color: CkColors.paper2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          TeamCrest(
            name: team?.name ?? '??',
            primaryColor: team?.primaryColor,
            logoUrl: team?.logoUrl,
            monogram: team?.logoMonogram,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${team?.name.toUpperCase() ?? 'YOUR TEAM'} · $roleLabel · THIS PHONE',
              overflow: TextOverflow.ellipsis,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.ink2,
              ),
            ),
          ),
          if (state.match.tossDecision != null) ...[
            const SizedBox(width: 8),
            Text(
              'TOSS ✓',
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
                color: CkColors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: CkColors.redSoft,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: CkType.mono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: CkColors.red,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.stepIndex});

  final int stepIndex;

  static const _pending = Color(0x1A14120E);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < matchStartStepCount; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i == matchStartStepCount - 1 ? 0 : 4,
              ),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: i < stepIndex
                      ? CkColors.green
                      : i == stepIndex
                          ? CkColors.ink
                          : _pending,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
