import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';
import '../../../matches/domain/entities/match.dart';

/// A fixture row inside a tournament schedule or round view.
class TournamentFixtureRow extends StatelessWidget {
  const TournamentFixtureRow({
    super.key,
    required this.match,
    this.teamAName,
    this.teamBName,
    this.teamACrestColor,
    this.teamBCrestColor,
    this.scoreText,
    this.stageLabel,
    this.onTap,
  });

  final Match match;
  final String? teamAName;
  final String? teamBName;
  final String? teamACrestColor;
  final String? teamBCrestColor;
  final String? scoreText;
  final String? stageLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tAName = teamAName ?? 'Team A';
    final tBName = teamBName ?? 'Team B';
    final isLive = match.status == MatchStatus.live ||
        match.status == MatchStatus.inningsBreak ||
        match.status == MatchStatus.superOver;

    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        border: Border.all(
          color: isLive ? CkColors.redSoft : CkColors.hairline,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CkRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (stageLabel ?? match.venue?.ground ?? 'MATCH')
                          .toUpperCase(),
                      style: CkType.mono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: CkColors.muted,
                      ),
                    ),
                    _buildStatusBadge(isLive),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTeamLine(tAName, teamACrestColor),
                          const SizedBox(height: 6),
                          _buildTeamLine(tBName, teamBCrestColor),
                        ],
                      ),
                    ),
                    if (scoreText != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        scoreText!,
                        style: CkType.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isLive ? CkColors.red : CkColors.ink,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamLine(String name, String? crestColor) {
    final monogram = name.isNotEmpty
        ? (name.length >= 2 ? name.substring(0, 2).toUpperCase() : name)
        : 'T';

    Color parsedColor = CkColors.ink2;
    if (crestColor != null && crestColor.startsWith('#')) {
      final hex = crestColor.replaceAll('#', '');
      if (hex.length == 6) {
        parsedColor = Color(int.parse('0xFF$hex'));
      }
    }

    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: parsedColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              monogram,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: CkType.display(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isLive) {
    if (isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CkColors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'LIVE',
          style: CkType.mono(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    if (match.status == MatchStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CkColors.greenSurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CkColors.greenBorder),
        ),
        child: Text(
          'FINAL',
          style: CkType.mono(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: CkColors.greenInk,
          ),
        ),
      );
    }

    if (match.status == MatchStatus.abandoned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CkColors.redSurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CkColors.redBorder),
        ),
        child: Text(
          'ABANDONED',
          style: CkType.mono(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: CkColors.redInk,
          ),
        ),
      );
    }

    final time = match.scheduledStartTime != null
        ? '${match.scheduledStartTime!.hour.toString().padLeft(2, '0')}:${match.scheduledStartTime!.minute.toString().padLeft(2, '0')}'
        : 'SCHEDULED';

    return Text(
      time,
      style: CkType.mono(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: CkColors.muted,
      ),
    );
  }
}
