import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../providers/challenges_providers.dart';
import '../../state/challenges_view.dart';
import '../pool/pool_icons.dart';

/// The way into the direct-challenge queue, in the My Matches nav bar.
///
/// My Matches lists only created + confirmed matches, so challenges cannot be
/// content there — but they still need a door, because a pending challenge dies
/// after 48h (24h once countered) and a queue nobody is told about quietly
/// loses fixtures. A badged icon in the chrome is that door: always reachable,
/// never taking a row.
///
/// Uses [PoolIcons.target] rather than the menu's pennant glyph on purpose.
/// This codebase already draws that distinction — the target is documented as
/// "the fork's Direct card — a target, for one known team", while the pennant
/// belongs to the open pool. Two different objects, two different icons.
class ChallengesNavButton extends ConsumerWidget {
  const ChallengesNavButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needs = ref.watch(challengesViewProvider).value?.needsYou ??
        const <ChallengeRow>[];
    final urgent = needs.any((r) => r.tier == ExpiryTier.urgent);

    return Semantics(
      button: true,
      label: needs.isEmpty
          ? 'Challenges'
          : 'Challenges, ${needs.length} need you',
      child: InkWell(
        onTap: () => context.push('/my/challenges'),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          // The badge sits proud of the disc, so it must not be clipped.
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: CkColors.paper2,
                  shape: BoxShape.circle,
                ),
                child: const PoolIcon(PoolIcons.target, size: 18),
              ),
              if (needs.isNotEmpty)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      // Red only when something is actually inside the urgent
                      // tier, matching the queue's own rule: the screen
                      // escalates with the queue, not with the feature.
                      color: urgent ? CkColors.red : CkColors.ink,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: CkColors.paper, width: 1.5),
                    ),
                    child: Text(
                      '${needs.length}',
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: CkColors.paper,
                      ),
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
