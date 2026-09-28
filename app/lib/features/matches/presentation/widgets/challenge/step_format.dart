import 'package:flutter/material.dart';

import '../../../domain/entities/format_preset.dart';
import '../../../domain/entities/match.dart';
import '../format/cricket_format_draft.dart';
import '../format/cricket_format_editor.dart';
import '../wizard/wizard_kit.dart';

export '../../utils/format_display.dart' show formatSpecLine, formatSummary, formatTitle;

/// Match format — Step 3 of Challenge Creation.
///
/// Wraps the reusable [CricketFormatEditor] with challenge wizard callbacks.
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

  @override
  Widget build(BuildContext context) {
    final effectiveCode = isCustom
        ? 'custom'
        : (selectedPreset?.id ?? format.formatCode ?? (format.oversPerInnings == 20 ? 't20' : 'custom'));

    final draft = CricketFormatDraft(
      formatCode: effectiveCode,
      overs: format.oversPerInnings,
      ballsPerOver: format.ballsPerOver,
      ballType: format.ballType,
      playersPerSide: format.playersPerTeam,
      maxOversPerBowler: format.maxOversPerBowler > 0
          ? format.maxOversPerBowler
          : CricketFormatSelection.suggestedBowlerLimit(format.oversPerInnings),
      inningsPerSide: format.inningsPerSide,
    );

    return CricketFormatEditor(
      draft: draft,
      presets: presets,
      header: const WizardHeading(
        'Match format',
        sub: 'Choose how this match will be played.',
      ),
      onChanged: (next) {
        if (next.isCustom != isCustom) {
          if (next.isCustom) {
            onSelectCustom();
          } else {
            final p = _findPreset(next.formatCode, next.overs, next.maxOversPerBowler);
            onSelectPreset(p);
          }
        } else if (!next.isCustom && next.formatCode != effectiveCode) {
          final p = _findPreset(next.formatCode, next.overs, next.maxOversPerBowler);
          onSelectPreset(p);
        }

        if (next.ballType != format.ballType) {
          onBall(next.ballType);
        }

        if (next.playersPerSide != format.playersPerTeam) {
          onPlayers(next.playersPerSide);
        }

        if (next.overs != format.oversPerInnings ||
            next.maxOversPerBowler != format.maxOversPerBowler ||
            next.ballsPerOver != format.ballsPerOver) {
          onCustomizeFormat(
            overs: next.overs,
            maxBowler: next.maxOversPerBowler,
            ballsPerOver: next.ballsPerOver,
          );
        }
      },
    );
  }

  FormatPreset _findPreset(String id, int overs, int maxBowler) {
    return presets.where((p) => p.id == id).firstOrNull ??
        FormatPreset(
          id: id,
          label: id.toUpperCase(),
          format: MatchFormat(
            formatCode: id,
            oversPerInnings: overs,
            playersPerTeam: format.playersPerTeam,
            ballType: format.ballType,
            maxOversPerBowler: maxBowler,
          ),
        );
  }
}
