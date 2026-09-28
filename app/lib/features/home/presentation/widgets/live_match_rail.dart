import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../../../core/widgets/v2/v2_kit.dart';
import '../../../matches/presentation/providers/my_matches_providers.dart';

/// Live match rail widget for the Home Feed.
/// Displays active matches in real-time horizontally.
class LiveMatchRail extends ConsumerWidget {
  const LiveMatchRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesViewAsync = ref.watch(myMatchesViewProvider);

    return matchesViewAsync.when(
      data: (view) {
        final liveMatches = view.confirmed.where((m) => m.live).toList();
        if (liveMatches.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Container(
            decoration: BoxDecoration(
              color: CkColors.ink,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: CkColors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE NOW · ${liveMatches.length}',
                      style: CkType.mono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.10,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'see all →',
                      style: CkType.body(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 66,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: liveMatches.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final m = liveMatches[i];
                      return _LiveCard(
                        aShort: m.homeShort,
                        aColor: m.homeColor,
                        bShort: m.awayShort,
                        bColor: m.awayColor,
                        aScore: '—', // v1: placeholder
                        bScore: '—', // v1: placeholder
                        need: m.tag,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.aShort,
    required this.aColor,
    required this.bShort,
    required this.bColor,
    required this.aScore,
    required this.bScore,
    required this.need,
  });

  final String aShort;
  final Color aColor;
  final String bShort;
  final Color bColor;
  final String aScore;
  final String bScore;
  final String need;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Crest(short: aShort, color: aColor, size: 22, radius: 5),
              const SizedBox(width: 8),
              Text(
                aScore,
                style: CkType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                need,
                style: CkType.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Crest(short: bShort, color: bColor, size: 22, radius: 5),
              const SizedBox(width: 8),
              Text(
                bScore,
                style: CkType.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
