import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../domain/entities/format_preset.dart';
import '../../../domain/entities/match.dart';
import '../../utils/format_display.dart';
import '../wizard/wizard_kit.dart';
import 'cricket_format_draft.dart';

/// Reusable Cricket Format Editor.
///
/// Features:
/// 1. Formats: 2-column grid of all 8 limited-overs presets (`t20`, `t10`,
///    `quick_6`, `quick_8`, `over_30`, `over_40`, `over_45`, `over_50`) + Custom.
/// 2. Match Rules: overs (fixed for presets, stepper for custom), bowler limit, balls/over.
/// 3. Playing Conditions: ball type (Tape, Tennis, Leather), players per side (8, 11, Other 5..15).
/// 4. Live summary card ("ON THE CARD").
class CricketFormatEditor extends StatelessWidget {
  const CricketFormatEditor({
    super.key,
    required this.draft,
    required this.onChanged,
    this.presets = const [],
    this.header,
  });

  final CricketFormatDraft draft;
  final ValueChanged<CricketFormatDraft> onChanged;
  final List<FormatPreset> presets;
  final Widget? header;

  static const _balls = {
    MatchBallType.tape: 'Tape-ball',
    MatchBallType.tennis: 'Tennis',
    MatchBallType.leather: 'Leather',
  };

  static const _catalogDefinitions = [
    (id: 't20', title: 'T20', subtitle: '20 overs', overs: 20, bowlerLimit: 4, players: 11),
    (id: 't10', title: 'T10', subtitle: '10 overs', overs: 10, bowlerLimit: 2, players: 11),
    (id: 'quick_6', title: '6 OVER', subtitle: '6 overs', overs: 6, bowlerLimit: 2, players: 8),
    (id: 'quick_8', title: '8 OVER', subtitle: '8 overs', overs: 8, bowlerLimit: 2, players: 8),
    (id: 'over_30', title: '30 OVER', subtitle: '30 overs', overs: 30, bowlerLimit: 6, players: 11),
    (id: 'over_40', title: '40 OVER', subtitle: '40 overs', overs: 40, bowlerLimit: 8, players: 11),
    (id: 'over_45', title: '45 OVER', subtitle: '45 overs', overs: 45, bowlerLimit: 9, players: 11),
    (id: 'over_50', title: '50 OVER', subtitle: '50 overs', overs: 50, bowlerLimit: 10, players: 11),
  ];

  @override
  Widget build(BuildContext context) {
    final title = formatTitle(
      formatCode: draft.formatCode,
      isCustom: draft.isCustom,
      overs: draft.overs,
    );

    final spec = formatSpecLine(
      overs: draft.overs,
      ball: draft.ballType,
      playersPerSide: draft.playersPerSide,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        if (header != null) header!,
        const SizedBox(height: 12),

        const WizardFieldLabel('POPULAR'),
        const SizedBox(height: 10),
        _buildFormatGrid(),

        const SizedBox(height: 24),
        const WizardFieldLabel('MATCH RULES'),
        const SizedBox(height: 10),
        _buildMatchRulesCard(context),

        const SizedBox(height: 24),
        const WizardFieldLabel('BALL TYPE'),
        const SizedBox(height: 10),
        WizardSegmented<MatchBallType>(
          options: _balls,
          selected: draft.ballType,
          onSelect: (b) => onChanged(draft.copyWith(ballType: b)),
        ),

        const SizedBox(height: 24),
        const WizardFieldLabel('PLAYERS PER SIDE'),
        const SizedBox(height: 10),
        _PlayersRow(
          value: draft.playersPerSide,
          onChanged: (n) => onChanged(draft.copyWith(playersPerSide: n)),
        ),

        const SizedBox(height: 24),
        _OnTheCard(
          title: title,
          spec: spec,
        ),
      ],
    );
  }

  Widget _buildFormatGrid() {
    final items = <Widget>[];

    for (final def in _catalogDefinitions) {
      final selected = !draft.isCustom && draft.formatCode == def.id;
      items.add(
        _FormatCard(
          title: def.title,
          subtitle: def.subtitle,
          selected: selected,
          onTap: () {
            final matching = presets.where((p) => p.id == def.id).firstOrNull;
            if (matching != null) {
              onChanged(draft.applyPreset(matching));
            } else {
              onChanged(
                draft.copyWith(
                  formatCode: def.id,
                  overs: def.overs,
                  maxOversPerBowler: def.bowlerLimit,
                  playersPerSide: def.players,
                ),
              );
            }
          },
        ),
      );
    }

    // Custom 9th card
    items.add(
      _FormatCard(
        title: 'CUSTOM',
        subtitle: 'Your rules',
        selected: draft.isCustom,
        onTap: () {
          onChanged(
            draft.copyWith(
              formatCode: 'custom',
              maxOversPerBowler: draft.maxOversPerBowler > 0
                  ? draft.maxOversPerBowler
                  : CricketFormatSelection.suggestedBowlerLimit(draft.overs),
            ),
          );
        },
      ),
    );

    // Build 2-column rows
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final first = items[i];
      final second = (i + 1 < items.length) ? items[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(child: first),
              const SizedBox(width: 10),
              if (second != null)
                Expanded(child: second)
              else
                const Spacer(),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildMatchRulesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CkColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CkColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OVERS PER INNINGS',
                style: CkType.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: CkColors.ink2,
                  letterSpacing: 0.08,
                ),
              ),
              if (!draft.isCustom)
                Text(
                  'Preset locked',
                  style: CkType.body(fontSize: 11, color: CkColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (draft.isCustom) ...[
            _OversStepper(
              value: draft.overs,
              min: 1,
              max: 90,
              onChanged: (v) {
                final newBowlerLimit = draft.maxOversPerBowler > v
                    ? v
                    : (draft.maxOversPerBowler > 0
                        ? draft.maxOversPerBowler
                        : CricketFormatSelection.suggestedBowlerLimit(v));
                onChanged(
                  draft.copyWith(
                    overs: v,
                    maxOversPerBowler: newBowlerLimit,
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: CkColors.paper2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CkColors.line),
              ),
              child: Row(
                children: [
                  Text(
                    '${draft.overs} overs',
                    style: CkType.display(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CkColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Switch to Custom to modify',
                    style: CkType.body(fontSize: 12, color: CkColors.muted),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),
          Text(
            'MAX OVERS PER BOWLER',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: CkColors.ink2,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 8),
          _OversStepper(
            value: draft.maxOversPerBowler,
            min: 1,
            max: draft.overs > 0 ? draft.overs : 10,
            onChanged: (v) => onChanged(draft.copyWith(maxOversPerBowler: v)),
          ),

          const SizedBox(height: 18),
          Text(
            'BALLS PER OVER',
            style: CkType.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: CkColors.ink2,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final b in [6, 8])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PillTile(
                    label: '$b balls${b == 6 ? ' (standard)' : ''}',
                    selected: draft.ballsPerOver == b,
                    onTap: () => onChanged(draft.copyWith(ballsPerOver: b)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
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
                color: selected
                    ? CkColors.paper.withValues(alpha: 0.75)
                    : CkColors.ink2,
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
                  const WizardFieldLabel('PLAYERS PER SIDE'),
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
