import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/ck_shimmer.dart';
import 'pool_icons.dart';

/// Pool board — empty (`Pool.dc.html` artboard 02).
///
/// No create button and no management row: posting and your own challenges
/// both live in the side panel, so the empty board explains itself instead of
/// selling a button. The share-code row stays because it is the one thing a
/// captain standing in front of another captain actually needs here.
class PoolEmptyState extends StatelessWidget {
  const PoolEmptyState({super.key, this.onEnterCode});

  final VoidCallback? onEnterCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
          child: Column(
            children: [
              const _CreamTile(
                size: 60,
                radius: 16,
                child: PoolIcon(PoolIcons.silentBoard, size: 26),
              ),
              const SizedBox(height: 18),
              Text(
                'No open challenges yet',
                textAlign: TextAlign.center,
                style: CkType.display(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: CkColors.ink,
                  letterSpacing: -0.01,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 280,
                child: Text(
                  'The board is quiet right now. Open challenges from teams '
                  'in your area land here as they are posted, and stay up '
                  'for 48 hours.',
                  textAlign: TextAlign.center,
                  style: CkType.body(
                    fontSize: 13,
                    height: 1.6,
                    color: CkColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: _ShareCodeRow(onTap: onEnterCode),
        ),
      ],
    );
  }
}

class _ShareCodeRow extends StatelessWidget {
  const _ShareCodeRow({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: CkColors.paper2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CkColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: CkColors.line),
              ),
              child: const PoolIcon(PoolIcons.shareCode, size: 15),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Have a share code?',
                    style: CkType.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CkColors.ink,
                      letterSpacing: -0.01,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Enter a 6-digit code from another captain.',
                    style: CkType.body(fontSize: 11, color: CkColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: CkColors.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: CkColors.creamBorder),
              ),
              child: Text(
                'ENTER',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.06,
                  color: CkColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pool board — error (`Pool.dc.html` artboard 04).
///
/// Calm, not alarming: a hairline icon, a plain cause, a retry. Red is spent
/// only on the small failure dot.
class PoolErrorState extends StatelessWidget {
  const PoolErrorState({super.key, required this.onRetry, this.code});

  final VoidCallback onRetry;

  /// Machine-readable cause, printed under the button ("503 · pool_unavailable").
  /// Null hides the line rather than printing an empty rule.
  final String? code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 34, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CkColors.line),
                ),
                child: const PoolIcon(PoolIcons.disconnected, size: 26),
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: CkColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: CkColors.paper, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "Couldn't load the pool",
            textAlign: TextAlign.center,
            style: CkType.display(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CkColors.ink,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 270,
            child: Text(
              "We couldn't reach matchday just now. Check your connection "
              'and try again — your draft, if any, is safe.',
              textAlign: TextAlign.center,
              style: CkType.body(
                fontSize: 13,
                height: 1.6,
                color: CkColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRetry,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: CkColors.ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PoolIcon(PoolIcons.retry, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Retry',
                    style: CkType.display(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CkColors.paper,
                      letterSpacing: -0.01,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (code != null) ...[
            const SizedBox(height: 14),
            Text(
              code!.toUpperCase(),
              textAlign: TextAlign.center,
              style: CkType.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
                color: CkColors.soft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pool board — no team (`Pool.dc.html` artboard 05).
///
/// States where teams come from rather than linking into them: the Pool tab
/// creates nothing, not even a team.
class PoolNoTeamGate extends StatelessWidget {
  const PoolNoTeamGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PoolIcon(PoolIcons.locked, size: 17),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'You need a team to take part',
                  style: CkType.display(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CkColors.ink,
                    letterSpacing: -0.01,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Only team managers can post challenges or apply to play. Teams '
            'live in the side panel, under My teams — that is where you '
            'create or join one. Once you are in a team, the Pool opens up.',
            style: CkType.body(
              fontSize: 12.5,
              height: 1.6,
              color: CkColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pool board — loading (`Pool.dc.html` artboard 03).
///
/// Card-shaped skeletons matching the real card's geometry so nothing jumps
/// when data lands. Shimmer on paper-2, no spinner.
class PoolLoadingState extends StatelessWidget {
  const PoolLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const CkShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                CkShimmerBox(width: 52, height: 26, radius: 999),
                SizedBox(width: 8),
                CkShimmerBox(width: 80, height: 26, radius: 999),
                SizedBox(width: 8),
                CkShimmerBox(width: 70, height: 26, radius: 999),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Column(
              children: [
                _SkeletonCard(
                  nameWidth: 0.55,
                  subWidth: 0.35,
                  metaWidths: [0.70, 0.50],
                  withFooter: true,
                ),
                SizedBox(height: 12),
                _SkeletonCard(
                  nameWidth: 0.60,
                  subWidth: 0.30,
                  metaWidths: [0.65, 0.45],
                  withFooter: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.nameWidth,
    required this.subWidth,
    required this.metaWidths,
    required this.withFooter,
  });

  /// Widths are fractions of the line they sit on, not pixels, so the skeleton
  /// keeps the real card's proportions at any width. Expressed with
  /// [FractionallySizedBox] rather than a [LayoutBuilder] because the board's
  /// slivers measure intrinsic height, which a LayoutBuilder cannot report.
  final double nameWidth;
  final double subWidth;
  final List<double> metaWidths;
  final bool withFooter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CkShimmerBox(width: 42, height: 42, radius: 12),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(nameWidth, height: 13),
                    const SizedBox(height: 8),
                    _Line(subWidth, height: 9),
                  ],
                ),
              ),
            ],
          ),
          for (final w in metaWidths) ...[
            const SizedBox(height: 12),
            _Line(w, height: 11),
          ],
          if (withFooter) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: CkColors.hairline),
            const SizedBox(height: 11),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _Line(0.30, height: 10)),
                CkShimmerBox(width: 70, height: 22, radius: 6),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A shimmer bar occupying [factor] of the width available to it.
class _Line extends StatelessWidget {
  const _Line(this.factor, {required this.height});

  final double factor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: factor,
      alignment: Alignment.centerLeft,
      child: CkShimmerBox(height: height, radius: 5),
    );
  }
}

class _CreamTile extends StatelessWidget {
  const _CreamTile({
    required this.size,
    required this.radius,
    required this.child,
  });

  final double size;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: child,
    );
  }
}
