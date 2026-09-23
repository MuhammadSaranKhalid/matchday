import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/format_preset.dart';
import '../../../domain/entities/match.dart';
import '../wizard/wizard_kit.dart';

/// Match format — Step 3 of Challenge Creation.
///
/// Decouples format presets (T10, T20, 50 Over, club formats, Custom),
/// playing conditions (Ball type, players per side), and engine rules
/// (overs, max bowler limit, balls/over).
class StepFormat extends StatelessWidget {
  const StepFormat({
    super.key,
    required this.presets,
    required this.selectedPreset,
    required this.format,
    required this.isCustom,
    required this.onSelectPreset,
    required this.onSelectCustom,
    required this.onBall,
    required this.onPlayers,
    required this.onCustomizeFormat,
  });

  final List<FormatPreset> presets;
  final FormatPreset? selectedPreset;
  final MatchFormat format;
  final bool isCustom;
  final ValueChanged<FormatPreset> onSelectPreset;
  final VoidCallback onSelectCustom;
  final ValueChanged<MatchBallType> onBall;
  final ValueChanged<int> onPlayers;
  final void Function({
    int? overs,
    int? maxBowler,
    int? ballsPerOver,
    int? wickets,
  }) onCustomizeFormat;

  static const _balls = {
    MatchBallType.tape: 'Tape-ball',
    MatchBallType.tennis: 'Tennis',
    MatchBallType.leather: 'Leather',
  };

  @override
  Widget build(BuildContext context) {
    // 2x2 featured presets
    final t10Preset = _findPreset('t10', 'T10', 10, 2);
    final t20Preset = _findPreset('t20', 'T20', 20, 4);
    final over50Preset = _findPreset('over_50', '50 Over', 50, 10);

    // Other presets (6, 8, 30, 40, 45, etc.)
    final morePresets = presets.where((p) {
      final id = p.id;
      return id != 't10' && id != 't20' && id != 'over_50' && id != 'custom';
    }).toList();

    final cardTitle = formatTitle(
      preset: selectedPreset,
      isCustom: isCustom,
      overs: format.oversPerInnings,
    );

    final cardSpec = formatSpecLine(
      overs: format.oversPerInnings,
      ball: format.ballType,
      playersPerSide: format.playersPerTeam,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        const WizardHeading(
          'Match format',
          sub: 'Choose how this match will be played.',
        ),
        const SizedBox(height: 20),

        const WizardFieldLabel('Popular'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FormatGridCard(
                title: 'T10',
                subtitle: '10 overs',
                selected: !isCustom && selectedPreset?.id == 't10',
                onTap: () => onSelectPreset(t10Preset),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FormatGridCard(
                title: 'T20',
                subtitle: '20 overs',
                selected: !isCustom && selectedPreset?.id == 't20',
                onTap: () => onSelectPreset(t20Preset),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FormatGridCard(
                title: '50 OVER',
                subtitle: '50 overs',
                selected: !isCustom && selectedPreset?.id == 'over_50',
                onTap: () => onSelectPreset(over50Preset),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FormatGridCard(
                title: 'CUSTOM',
                subtitle: 'Your rules',
                selected: isCustom,
                onTap: onSelectCustom,
              ),
            ),
          ],
        ),

        if (morePresets.isNotEmpty) ...[
          const SizedBox(height: 22),
          const WizardFieldLabel('More formats'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in morePresets)
                _PillTile(
                  label: _shortPillLabel(p),
                  selected: !isCustom && selectedPreset?.id == p.id,
                  onTap: () => onSelectPreset(p),
                ),
            ],
          ),
        ],

        const SizedBox(height: 24),
        const WizardFieldLabel('Ball type'),
        const SizedBox(height: 10),
        WizardSegmented<MatchBallType>(
          options: _balls,
          selected: _balls.containsKey(format.ballType) ? format.ballType : null,
          onSelect: onBall,
        ),

        const SizedBox(height: 24),
        const WizardFieldLabel('Players per side'),
        const SizedBox(height: 10),
        _PlayersRow(
          value: format.playersPerTeam,
          onChanged: onPlayers,
        ),

        const SizedBox(height: 22),
        _CustomizeFormatAccordion(
          format: format,
          isCustom: isCustom,
          onCustomizeFormat: onCustomizeFormat,
        ),

        const SizedBox(height: 24),
        _OnTheCard(
          title: cardTitle,
          spec: cardSpec,
        ),
      ],
    );
  }

  FormatPreset _findPreset(String id, String label, int overs, int maxBowler) {
    return presets.where((p) => p.id == id).firstOrNull ??
        FormatPreset(
          id: id,
          label: label,
          format: MatchFormat(
            formatCode: id,
            oversPerInnings: overs,
            playersPerTeam: 11,
            ballType: format.ballType,
            maxOversPerBowler: maxBowler,
          ),
        );
  }

  static String _shortPillLabel(FormatPreset p) {
    final overs = p.format.oversPerInnings;
    if (overs > 0) return '$overs over';
    return p.label;
  }
}

/// "20 overs · Tape-ball · 11-a-side"
String formatSpecLine({
  required int overs,
  required MatchBallType ball,
  required int playersPerSide,
}) {
  final parts = <String>[
    if (overs > 0) '$overs overs',
    switch (ball) {
      MatchBallType.tape => 'Tape-ball',
      MatchBallType.tennis => 'Tennis',
      MatchBallType.leather => 'Leather',
    },
    '$playersPerSide-a-side',
  ];
  return parts.join(' · ');
}

/// "T20" / "CUSTOM (18 OVERS)"
String formatTitle({
  required FormatPreset? preset,
  required bool isCustom,
  required int overs,
}) {
  if (isCustom) return 'CUSTOM ($overs OVERS)';
  if (preset != null) {
    final label = preset.label.toUpperCase();
    if (label.contains('OVER')) return label;
    return label;
  }
  return '$overs OVERS';
}

class _FormatGridCard extends StatelessWidget {
  const _FormatGridCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: CkType.display(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected ? CkColors.paper : CkColors.ink,
                letterSpacing: -0.01,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: CkType.body(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? CkColors.paper.withValues(alpha: 0.75) : CkColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillTile extends StatelessWidget {
  const _PillTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? CkColors.ink : CkColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.line,
          ),
        ),
        child: Text(
          label,
          style: CkType.display(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? CkColors.paper : CkColors.ink2,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _CustomizeFormatAccordion extends StatefulWidget {
  const _CustomizeFormatAccordion({
    required this.format,
    required this.isCustom,
    required this.onCustomizeFormat,
  });

  final MatchFormat format;
  final bool isCustom;
  final void Function({
    int? overs,
    int? maxBowler,
    int? ballsPerOver,
    int? wickets,
  }) onCustomizeFormat;

  @override
  State<_CustomizeFormatAccordion> createState() => _CustomizeFormatAccordionState();
}

class _CustomizeFormatAccordionState extends State<_CustomizeFormatAccordion> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCustom) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CkColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Customize format',
                        style: CkType.display(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: CkColors.ink,
                        ),
                      ),
                      if (widget.isCustom) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: CkColors.paper2,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'CUSTOM',
                            style: CkType.mono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: CkColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: CkColors.ink2,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: CkColors.line),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WizardFieldLabel('Overs per innings'),
                  const SizedBox(height: 8),
                  _OversStepper(
                    value: widget.format.oversPerInnings,
                    min: 1,
                    max: 100,
                    onChanged: (v) => widget.onCustomizeFormat(overs: v),
                  ),
                  const SizedBox(height: 16),
                  const WizardFieldLabel('Max overs per bowler'),
                  const SizedBox(height: 8),
                  _OversStepper(
                    value: widget.format.maxOversPerBowler,
                    min: 1,
                    max: widget.format.oversPerInnings > 0 ? widget.format.oversPerInnings : 10,
                    onChanged: (v) => widget.onCustomizeFormat(maxBowler: v),
                  ),
                  const SizedBox(height: 16),
                  const WizardFieldLabel('Balls per over'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final b in [6, 8])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _PillTile(
                            label: '$b balls',
                            selected: widget.format.ballsPerOver == b,
                            onTap: () => widget.onCustomizeFormat(ballsPerOver: b),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OversStepper extends StatelessWidget {
  const _OversStepper({
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 50,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

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
            enabled: value > min,
            onTap: () => onChanged(value - 1),
          ),
          Text(
            '$value',
            style: CkType.display(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: CkColors.ink,
              letterSpacing: -0.02,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          _Nub(
            glyph: '+',
            filled: true,
            enabled: value < max,
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
        Expanded(
          child: _Tile(
            label: '8',
            selected: value == 8,
            onTap: () => onChanged(8),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _Tile(
            label: '11',
            selected: value == 11,
            onTap: () => onChanged(11),
          ),
        ),
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
      builder:
          (_) => Container(
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
                              border:
                                  n == value
                                      ? null
                                      : Border.all(color: CkColors.line),
                            ),
                            child: Center(
                              child: Text(
                                '$n',
                                style: CkType.display(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      n == value
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
              color:
                  selected
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
  const _OnTheCard({
    required this.title,
    required this.spec,
  });

  final String title;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                title,
                style: CkType.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CkColors.ink,
                  letterSpacing: 0.02,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            spec.toUpperCase(),
            style: CkType.mono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.04,
              color: CkColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
