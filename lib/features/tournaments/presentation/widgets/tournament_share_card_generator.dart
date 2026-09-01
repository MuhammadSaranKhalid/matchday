import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';

enum ShareCardType {
  champions,
  summary,
  playerPerformance,
}

/// Renders a shareable, high-contrast social card suitable for WhatsApp status and Instagram.
class TournamentShareCard extends StatelessWidget {
  const TournamentShareCard({
    super.key,
    required this.tournament,
    this.cardType = ShareCardType.champions,
    this.championTeamName,
    this.finalMargin,
    this.playerName,
    this.playerStats,
  });

  final Tournament tournament;
  final ShareCardType cardType;
  final String? championTeamName;
  final String? finalMargin;
  final String? playerName;
  final String? playerStats;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5, // WhatsApp / Instagram optimized ratio
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardType == ShareCardType.champions
              ? CkColors.ink
              : CkColors.paper,
          borderRadius: BorderRadius.circular(CkRadii.lg),
          border: Border.all(
            color: cardType == ShareCardType.champions
                ? CkColors.creamBorder
                : CkColors.hairline,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top branding wordmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MATCHDAY CRICKET',
                  style: CkType.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cardType == ShareCardType.champions
                        ? CkColors.cream
                        : CkColors.muted,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cardType == ShareCardType.champions
                        ? const Color(0xFF6B5414)
                        : CkColors.paper2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tournament.type.label.toUpperCase(),
                    style: CkType.mono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: cardType == ShareCardType.champions
                          ? Colors.white
                          : CkColors.ink,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            if (cardType == ShareCardType.champions) ...[
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B5414),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.emoji_events,
                      size: 42, color: Color(0xFFF4ECDD)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'TOURNAMENT CHAMPIONS',
                style: CkType.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CkColors.cream,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                championTeamName ?? 'Champion Team',
                style: CkType.display(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (finalMargin != null) ...[
                const SizedBox(height: 8),
                Text(
                  finalMargin!,
                  style: CkType.body(fontSize: 13.5, color: CkColors.paper2),
                  textAlign: TextAlign.center,
                ),
              ],
            ] else if (cardType == ShareCardType.playerPerformance) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: CkColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: CkColors.creamBorder),
                ),
                child: Center(
                  child: Text(
                    (playerName?.isNotEmpty ?? false)
                        ? playerName!.substring(0, 1).toUpperCase()
                        : 'P',
                    style: CkType.display(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B5414),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'TOURNAMENT PERFORMANCE',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: CkColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                playerName ?? 'Player',
                style: CkType.display(fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: CkColors.paper2,
                  borderRadius: BorderRadius.circular(CkRadii.sm),
                ),
                child: Text(
                  playerStats ?? '214 Runs in 5 Matches',
                  style: CkType.mono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CkColors.ink,
                  ),
                ),
              ),
            ] else ...[
              Text(
                tournament.name,
                style: CkType.display(fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '${tournament.city ?? "Cricket"} · ${tournament.approvedTeamsCount} Teams',
                style: CkType.body(fontSize: 13, color: CkColors.ink2),
              ),
            ],

            const Spacer(),

            // Footer
            const Divider(height: 1, color: CkColors.hairline),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tournament.name,
                  style: CkType.body(
                    fontSize: 11,
                    color: cardType == ShareCardType.champions
                        ? CkColors.soft
                        : CkColors.muted,
                  ),
                ),
                Text(
                  'joinmatchday.com',
                  style: CkType.mono(
                    fontSize: 9.5,
                    color: cardType == ShareCardType.champions
                        ? CkColors.soft
                        : CkColors.muted,
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
