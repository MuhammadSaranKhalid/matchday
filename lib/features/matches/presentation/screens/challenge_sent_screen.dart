import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/circk_theme.dart';
import '../providers/matches_providers.dart';
import '../widgets/pool/pool_icons.dart';
import '../widgets/pool/pool_states.dart';
import '../widgets/wizard/wizard_kit.dart';

/// Posted — `Pool.dc.html` artboard 11.
///
/// The payoff screen. The 6-digit share code is the hero, set large in mono
/// because its job is to be read aloud to another captain standing in front of
/// you. Ink, not celebration-green: the challenge is posted, not won.
class ChallengeSentScreen extends ConsumerWidget {
  const ChallengeSentScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(matchChallengeProvider(requestId));

    void done() =>
        context.canPop()
            ? context.go('/my/pool-requests')
            : context.go('/my/pool-requests');

    return Scaffold(
      backgroundColor: CkColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // No back chevron: the challenge is posted, so there is nothing
            // behind this screen to go back to.
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: done,
                    child: Text(
                      'DONE',
                      style: CkType.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.06,
                        color: CkColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: switch (async) {
                AsyncLoading() => const SingleChildScrollView(
                  child: PoolLoadingState(),
                ),
                AsyncError() => Center(
                  child: PoolErrorState(
                    onRetry:
                        () => ref.invalidate(matchChallengeProvider(requestId)),
                  ),
                ),
                AsyncData(value: final req) => _Body(
                  code: req?.shareCode,
                  isOpen: req?.toTeamId == null,
                ),
              },
            ),
            WizardFooter(
              label: 'View my challenge',
              outlined: true,
              onPressed: () => context.go('/challenges/$requestId'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.code, required this.isOpen});

  final String? code;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CkColors.ink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const PoolIcon(PoolIcons.checkLarge, size: 26),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isOpen ? "You're on the board" : 'Challenge sent',
          textAlign: TextAlign.center,
          style: CkType.display(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: CkColors.ink,
            letterSpacing: -0.02,
          ),
        ),
        const SizedBox(height: 7),
        Center(
          child: SizedBox(
            width: 270,
            child: Text(
              isOpen
                  ? 'Teams can see your open challenge and apply now. '
                      "We'll notify you the moment someone does."
                  : "They'll be notified now. We'll tell you as soon as they "
                      'accept or decline.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                height: 1.6,
                color: CkColors.muted,
              ),
            ),
          ),
        ),
        if (code != null && code!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _CodeCard(code: code!),
          const SizedBox(height: 16),
          _Actions(code: code!),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHARE CODE',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10,
              color: CkColors.amberInk,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              code,
              style: CkType.mono(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.18,
                color: CkColors.ink,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Read it aloud to another captain, or send it. Anyone with the '
            'code can open this challenge.',
            style: CkType.body(
              fontSize: 11.5,
              height: 1.5,
              color: CkColors.ink2,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: CkColors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'CODE EXPIRES IN 24H',
                  style: CkType.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                    color: CkColors.amberInk,
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

class _Actions extends StatelessWidget {
  const _Actions({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Action(
            label: 'Share',
            icon: PoolIcons.sharePaper,
            filled: true,
            onTap:
                () => SharePlus.instance.share(
                  ShareParams(
                    text: 'Join our match on matchday — share code $code',
                  ),
                ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _Action(
            label: 'Copy',
            icon: PoolIcons.copy,
            filled: false,
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share code copied.')),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: filled ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: CkColors.creamBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PoolIcon(icon, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: CkType.display(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: filled ? CkColors.paper : CkColors.ink,
                letterSpacing: -0.01,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
