import 'package:flutter/material.dart';
import '../../../../core/theme/circk_theme.dart';

/// One match node in a knockout tournament bracket tree.
class CkBracketNode extends StatelessWidget {
  const CkBracketNode({
    super.key,
    required this.teamAName,
    required this.teamBName,
    this.seedA,
    this.seedB,
    this.scoreA,
    this.scoreB,
    this.winnerTeamId,
    this.teamAId,
    this.teamBId,
    this.teamACrestColor,
    this.teamBCrestColor,
    this.isLive = false,
    this.isBye = false,
    this.byeReason,
    this.roundLabel,
    this.onTap,
  });

  final String teamAName;
  final String teamBName;
  final int? seedA;
  final int? seedB;
  final String? scoreA;
  final String? scoreB;
  final String? winnerTeamId;
  final String? teamAId;
  final String? teamBId;
  final String? teamACrestColor;
  final String? teamBCrestColor;
  final bool isLive;
  final bool isBye;

  /// "Bye · advances to SF". The canvas insists the node states *why* it is
  /// empty, in mono — an unexplained blank half reads as a loading state.
  final String? byeReason;
  final String? roundLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTeamAWinner =
        winnerTeamId != null && teamAId != null && winnerTeamId == teamAId;
    final isTeamBWinner =
        winnerTeamId != null && teamBId != null && winnerTeamId == teamBId;

    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        border: Border.all(
          color: isLive ? CkColors.red : CkColors.hairline,
          width: isLive ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CkRadii.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CkRadii.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (roundLabel != null || isLive)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLive ? CkColors.redSoft : CkColors.paper2,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(CkRadii.sm - 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isLive) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: CkColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: CkType.mono(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: CkColors.red,
                          ),
                        ),
                      ] else if (roundLabel != null) ...[
                        Text(
                          roundLabel!.toUpperCase(),
                          style: CkType.mono(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                            color: CkColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              _buildTeamSlot(
                name: teamAName,
                seed: seedA,
                score: scoreA,
                isWinner: isTeamAWinner,
                crestColor: teamACrestColor,
                isTop: roundLabel == null && !isLive,
              ),
              const Divider(height: 1, thickness: 1, color: CkColors.hairline),
              _buildTeamSlot(
                name: isBye ? (byeReason ?? 'Bye · advances') : teamBName,
                seed: seedB,
                score: scoreB,
                isWinner: isTeamBWinner,
                crestColor: teamBCrestColor,
                isBye: isBye,
                isBottom: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSlot({
    required String name,
    int? seed,
    String? score,
    bool isWinner = false,
    String? crestColor,
    bool isBye = false,
    bool isTop = false,
    bool isBottom = false,
  }) {
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

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isWinner ? CkColors.cream : Colors.transparent,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(CkRadii.sm - 1) : Radius.zero,
          bottom:
              isBottom ? const Radius.circular(CkRadii.sm - 1) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          if (seed != null) ...[
            Text(
              '$seed',
              style: CkType.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (!isBye) ...[
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: parsedColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  monogram,
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              name,
              style: isBye
                  ? CkType.body(fontSize: 11, color: CkColors.muted)
                  : CkType.display(
                      fontSize: 12,
                      fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                      color: isWinner
                          ? const Color(0xFF6B5414)
                          : (name.startsWith('Winner')
                              ? CkColors.muted
                              : CkColors.ink),
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (score != null) ...[
            const SizedBox(width: 4),
            Text(
              score,
              style: CkType.mono(
                fontSize: 11,
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                color: isWinner ? CkColors.ink : CkColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
