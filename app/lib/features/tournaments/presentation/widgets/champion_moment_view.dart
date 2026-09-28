import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/circk_theme.dart';
import '../../domain/entities/tournament.dart';

/// Artboard 34 — The Champion Moment.
///
/// A trophy engraving, not a win screen: one crest, one name, one line of
/// record. The share action is ink-on-cream so it reads as the primary act;
/// View Full Tournament is a hairline ghost in warm white.
class ChampionMomentView extends StatelessWidget {
  const ChampionMomentView({
    super.key,
    required this.tournament,
    required this.championTeamName,
    required this.finalScoreSummary,
    this.runnerUpTeamName,
    this.championScore,
    this.runnerUpScore,
    this.matchesPlayed,
    this.teamCount,
    this.city,
  });

  final Tournament tournament;
  final String championTeamName;

  /// The single line of record — "Won by 18 runs".
  final String finalScoreSummary;
  final String? runnerUpTeamName;
  final String? championScore;
  final String? runnerUpScore;
  final int? matchesPlayed;
  final int? teamCount;
  final String? city;

  String get _initials {
    final parts = championTeamName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  String get _recordLine {
    if (runnerUpTeamName == null) return finalScoreSummary;
    return 'Defeated $runnerUpTeamName $finalScoreSummary in the Final';
  }

  String? get _footnote {
    final bits = <String>[
      if (matchesPlayed != null) '$matchesPlayed matches',
      if (teamCount != null) '$teamCount teams',
      if (city != null && city!.isNotEmpty) city!,
    ];
    return bits.isEmpty ? null : bits.join(' · ');
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text: '🏆 $championTeamName are the champions of ${tournament.name}.\n'
            '$_recordLine\n\nScored live on matchday.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CkColors.championGround,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: CkColors.onDarkSecondary),
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'CHAMPIONS',
                      style: CkType.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.20,
                        color: CkColors.championGold,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _Crest(initials: _initials),
                    const SizedBox(height: 22),
                    Text(
                      championTeamName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: CkType.display(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: CkColors.onDarkPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _recordLine,
                      textAlign: TextAlign.center,
                      style: CkType.body(
                        fontSize: 13,
                        height: 1.55,
                        color: CkColors.onDarkSecondary,
                      ),
                    ),
                    if (championScore != null && runnerUpScore != null) ...[
                      const SizedBox(height: 20),
                      _FinalLine(
                        championScore: championScore!,
                        runnerUpScore: runnerUpScore!,
                      ),
                    ],
                    const SizedBox(height: 30),
                    Container(
                      height: 1,
                      color: CkColors.championHairline,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      tournament.name,
                      textAlign: TextAlign.center,
                      style: CkType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CkColors.onDarkSecondary,
                      ),
                    ),
                    if (_footnote != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        _footnote!,
                        textAlign: TextAlign.center,
                        style: CkType.body(
                          fontSize: 11.5,
                          color: CkColors.onDarkTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 34),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Column(
                children: [
                  // Ink on cream — the primary act.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _share,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CkColors.cream,
                        foregroundColor: CkColors.ink,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CkRadii.sm),
                        ),
                      ),
                      child: Text(
                        'Share to WhatsApp',
                        style: CkType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Hairline ghost in warm white.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CkColors.onDarkSecondary,
                        side: const BorderSide(color: CkColors.championHairline),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CkRadii.sm),
                        ),
                      ),
                      child: Text(
                        'View Full Tournament',
                        style: CkType.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CkColors.onDarkSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'matchday',
                    style: CkType.display(
                      fontSize: 15,
                      letterSpacing: -0.045,
                      color: CkColors.onDarkSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: CkColors.championRaised,
        shape: BoxShape.circle,
        border: Border.all(color: CkColors.championGold, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: CkType.display(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: CkColors.onDarkFigures,
        ),
      ),
    );
  }
}

/// The final's two lines, "168/6 v 150/9".
class _FinalLine extends StatelessWidget {
  const _FinalLine({required this.championScore, required this.runnerUpScore});

  final String championScore;
  final String runnerUpScore;

  @override
  Widget build(BuildContext context) {
    final figure = CkType.mono(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: CkColors.onDarkFigures,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(championScore, style: figure),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'v',
            style: CkType.body(fontSize: 12, color: CkColors.onDarkTertiary),
          ),
        ),
        Text(runnerUpScore, style: figure),
      ],
    );
  }
}
