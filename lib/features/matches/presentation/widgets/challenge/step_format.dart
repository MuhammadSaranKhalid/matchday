import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/circk_theme.dart';
import '../../../../../core/widgets/v2/v2_kit.dart';
import '../../../domain/entities/format_preset.dart';
import '../../../domain/entities/match.dart';
import '../../providers/matches_providers.dart';
import 'ch_icons.dart';
import 'ch_section_label.dart';

/// "How will we play" — match-format picker.
///
/// 2-col tile grid of every active [FormatPreset] from the backend catalog
/// + a read-only DETAIL strip + the "SAME FORMAT FOR BOTH TEAMS" caption.
/// Per the final landing in `chat1.md`, there are NO knob overrides — the
/// preset's [MatchFormat] snapshot is what ships.
///
/// API:
/// * [selectedPresetId] — the currently-picked preset's id (or null on first
///   render; the tile grid simply shows nothing selected).
/// * [onPicked] — fired when the user taps a tile. Forwards the whole
///   [FormatPreset] so callers can both store the id and snapshot the
///   format jsonb.
class StepFormat extends ConsumerWidget {
  const StepFormat({
    super.key,
    required this.selectedPresetId,
    required this.onPicked,
  });

  final String? selectedPresetId;
  final ValueChanged<FormatPreset> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(formatPresetsProvider);
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: CkColors.ink)),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          e.toString(),
          style: CkType.body(fontSize: 12, color: CkColors.muted),
        ),
      ),
      data: (presets) => _Body(
        presets: presets,
        selectedPresetId: selectedPresetId,
        onPicked: onPicked,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.presets,
    required this.selectedPresetId,
    required this.onPicked,
  });

  final List<FormatPreset> presets;
  final String? selectedPresetId;
  final ValueChanged<FormatPreset> onPicked;

  @override
  Widget build(BuildContext context) {
    final selected = _findSelected();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      children: [
        const ChSectionLabel('Choose a format', hint: 'One tap sets it all'),
        _PresetGrid(
          presets: presets,
          selectedPresetId: selectedPresetId,
          onPicked: onPicked,
        ),
        const SizedBox(height: 16),
        if (selected != null) _DetailStrip(preset: selected),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'SAME FORMAT FOR BOTH TEAMS',
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  FormatPreset? _findSelected() {
    if (selectedPresetId == null) return null;
    for (final p in presets) {
      if (p.id == selectedPresetId) return p;
    }
    return null;
  }
}

/// 2-col preset grid. Uses `IntrinsicHeight` per row so the tiles within a
/// row share a height (the taller of the two), but each row sizes
/// independently — mirroring the JSX `grid-template-columns: 1fr 1fr` flow.
/// `GridView`'s `childAspectRatio` is fixed and would force every tile to
/// the same height, which makes the row too tall vs. the design.
class _PresetGrid extends StatelessWidget {
  const _PresetGrid({
    required this.presets,
    required this.selectedPresetId,
    required this.onPicked,
  });

  final List<FormatPreset> presets;
  final String? selectedPresetId;
  final ValueChanged<FormatPreset> onPicked;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < presets.length; i += 2) {
      final left = presets[i];
      final right = i + 1 < presets.length ? presets[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PresetTile(
                    preset: left,
                    selected: left.id == selectedPresetId,
                    onTap: () => onPicked(left),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: right == null
                      ? const SizedBox.shrink()
                      : _PresetTile(
                          preset: right,
                          selected: right.id == selectedPresetId,
                          onTap: () => onPicked(right),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final FormatPreset preset;
  final bool selected;
  final VoidCallback onTap;

  /// JSX dot colors (`challenge-send.jsx` line 317):
  /// leather → `#a8332e`, tape → `#d8a85e`, tennis → `#cdd64a`.
  Color get _dotColor {
    switch (preset.format.ballType) {
      case MatchBallType.leather:
        return const Color(0xFFA8332E);
      case MatchBallType.tape:
        return const Color(0xFFD8A85E);
      case MatchBallType.tennis:
        return const Color(0xFFCDD64A);
    }
  }

  String get _ballLabel {
    switch (preset.format.ballType) {
      case MatchBallType.leather:
        return 'Hardball';
      case MatchBallType.tape:
        return 'Tape';
      case MatchBallType.tennis:
        return 'Tennis';
    }
  }

  String get _overText {
    final f = preset.format;
    if (f.ballsPerOver != 6) {
      return '${f.oversPerInnings * f.ballsPerOver} balls';
    }
    return '${f.oversPerInnings} overs';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? CkColors.paper2 : CkColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? CkColors.ink : CkColors.hairline,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                    border: preset.format.ballType == MatchBallType.tennis
                        ? null
                        : Border.all(
                            color: const Color(0x1F000000),
                            width: 1,
                          ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    preset.label,
                    overflow: TextOverflow.ellipsis,
                    style: CkType.display(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02,
                    ),
                  ),
                ),
                if (selected)
                  const V2Svg(
                    ChIcons.check,
                    size: 14,
                    color: CkColors.ink,
                    strokeWidth: 2.6,
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              '$_overText · ${preset.format.playersPerTeam}/side',
              style: CkType.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.10,
                color: CkColors.muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$_ballLabel · ${preset.format.maxOversPerBowler} max/bow',
              style: CkType.body(fontSize: 11, color: CkColors.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStrip extends StatelessWidget {
  const _DetailStrip({required this.preset});
  final FormatPreset preset;

  @override
  Widget build(BuildContext context) {
    final f = preset.format;
    final detail = StringBuffer()
      ..write('${f.ballsPerOver}-ball overs · ')
      ..write('${f.inningsPerSide} innings per side');
    if (f.endChangeBalls != null) {
      detail.write(' · ends change every ${f.endChangeBalls} balls');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: CkColors.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CkColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${preset.label.toUpperCase()} · DETAIL',
            style: CkType.mono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.10,
              color: CkColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail.toString(),
            style: CkType.body(
              fontSize: 12,
              color: CkColors.ink2,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
