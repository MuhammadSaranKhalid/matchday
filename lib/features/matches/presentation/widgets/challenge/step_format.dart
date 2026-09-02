import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/match.dart';
import '../wizard/wizard_kit.dart';

/// Match format — `Pool.dc.html` artboard 07.
///
/// Replaces the preset grid this step used to show. The design asks the three
/// questions directly — overs, ball, side count — because that is what a
/// captain is actually deciding, and previews the exact spec string that will
/// land on the challenge card so there is no gap between what you set and what
/// other teams read.
class StepFormat extends StatelessWidget {
  const StepFormat({
    super.key,
    required this.overs,
    required this.ball,
    required this.playersPerSide,
    required this.onOvers,
    required this.onBall,
    required this.onPlayers,
  });

  final int overs;
  final MatchBallType ball;
  final int playersPerSide;
  final ValueChanged<int> onOvers;
  final ValueChanged<MatchBallType> onBall;
  final ValueChanged<int> onPlayers;

  /// The board's own two ball types. Tennis stays reachable through "Other"
  /// side counts only — the design offers this binary.
  static const _balls = {
    MatchBallType.tape: 'Tape-ball',
    MatchBallType.leather: 'Leather',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        const WizardHeading('Match format'),
        const SizedBox(height: 22),
        const WizardFieldLabel('Overs per innings'),
        const SizedBox(height: 12),
        _OversStepper(value: overs, onChanged: onOvers),
        const SizedBox(height: 24),
        const WizardFieldLabel('Ball type'),
        const SizedBox(height: 12),
        WizardSegmented<MatchBallType>(
          options: _balls,
          selected: _balls.containsKey(ball) ? ball : null,
          onSelect: onBall,
        ),
        const SizedBox(height: 24),
        const WizardFieldLabel('Players per side'),
        const SizedBox(height: 12),
        _PlayersRow(value: playersPerSide, onChanged: onPlayers),
        const SizedBox(height: 26),
        _OnTheCard(
          spec: formatSpecLine(
            overs: overs,
            ball: ball,
            playersPerSide: playersPerSide,
          ),
        ),
      ],
    );
  }
}

/// "12 overs · Tape-ball · 11-a-side" — the one spec string, built in one
/// place so the preview here and the card on the board cannot drift apart.
String formatSpecLine({
  required int overs,
  required MatchBallType ball,
  required int playersPerSide,
}) {
  final parts = <String>[
    if (overs > 0) '$overs overs',
    switch (ball) {
      MatchBallType.tape => 'Tape-ball',
      MatchBallType.leather => 'Leather',
      MatchBallType.tennis => 'Tennis-ball',
    },
    '$playersPerSide-a-side',
  ];
  return parts.join(' · ');
}

class _OversStepper extends StatelessWidget {
  const _OversStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  /// Limited-overs range. 5 is the shortest thing anyone plays; 50 is an ODI.
  static const _min = 1;
  static const _max = 50;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Nub(
            glyph: '−',
            filled: false,
            enabled: value > _min,
            onTap: () => onChanged(value - 1),
          ),
          Text(
            '$value',
            style: CkType.display(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
              letterSpacing: -0.02,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          _Nub(
            glyph: '+',
            filled: true,
            enabled: value < _max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _Nub extends StatelessWidget {
  const _Nub({
    required this.glyph,
    required this.filled,
    required this.enabled,
    required this.onTap,
  });

  final String glyph;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? CkColors.ink : CkColors.paper2,
            borderRadius: BorderRadius.circular(10),
            border: filled ? null : Border.all(color: CkColors.line),
          ),
          child: Text(
            glyph,
            style: CkType.display(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: filled ? CkColors.paper : CkColors.muted,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

/// 8 · 11 · Other. "Other" opens a small picker rather than a free field —
/// the server caps a side at 5–15, so an open input would only invite invalid
/// numbers.
class _PlayersRow extends StatelessWidget {
  const _PlayersRow({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _min = 5;
  static const _max = 15;

  @override
  Widget build(BuildContext context) {
    final isPreset = value == 8 || value == 11;

    return Row(
      children: [
        Expanded(child: _Tile(label: '8', selected: value == 8, onTap: () => onChanged(8))),
        const SizedBox(width: 9),
        Expanded(child: _Tile(label: '11', selected: value == 11, onTap: () => onChanged(11))),
        const SizedBox(width: 9),
        Expanded(
          child: _Tile(
            label: isPreset ? 'Other' : '$value',
            selected: !isPreset,
            muted: isPreset,
            onTap: () => _pickOther(context),
          ),
        ),
      ],
    );
  }

  Future<void> _pickOther(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: CkColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WizardFieldLabel('Players per side'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (var n = _min; n <= _max; n++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(n),
                      child: Container(
                        width: 52,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: n == value ? CkColors.ink : CkColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: n == value
                              ? null
                              : Border.all(color: CkColors.line),
                        ),
                        child: Center(
                          child: Text(
                            '$n',
                            style: CkType.display(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: n == value
                                  ? CkColors.paper
                                  : CkColors.ink2,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: selected ? null : Border.all(color: CkColors.line),
        ),
        child: Center(
          child: Text(
            label,
            style: CkType.display(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected
                  ? CkColors.paper
                  : (muted ? CkColors.muted : CkColors.ink2),
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

/// The live preview of the spec string other captains will read.
class _OnTheCard extends StatelessWidget {
  const _OnTheCard({required this.spec});

  final String spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CkColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.creamBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ON THE CARD',
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.08,
              color: CkColors.amberInk,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              spec.toUpperCase(),
              textAlign: TextAlign.right,
              style: CkType.mono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.04,
                color: CkColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
