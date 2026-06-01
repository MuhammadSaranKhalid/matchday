import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/format_preset.dart';
import '../../domain/entities/match.dart';

part 'format_preset_dto.freezed.dart';
part 'format_preset_dto.g.dart';

/// DTO for a `format_presets` row. `config` is the open-shape format jsonb;
/// `toEntity` parses it into a [MatchFormat] (same key set as `matches.format`).
@freezed
abstract class FormatPresetDto with _$FormatPresetDto {
  const factory FormatPresetDto({
    required String id,
    required String label,
    required Map<String, dynamic> config,
    @JsonKey(name: 'default_scoring_mode') String? defaultScoringMode,
  }) = _FormatPresetDto;

  const FormatPresetDto._();

  factory FormatPresetDto.fromJson(Map<String, dynamic> json) =>
      _$FormatPresetDtoFromJson(json);

  FormatPreset toEntity() => FormatPreset(
        id: id,
        label: label,
        defaultScoringMode: ScoringMode.fromWire(defaultScoringMode),
        // Parse the config jsonb → MatchFormat (mirrors MatchDto's format parse;
        // every key is optional + defaulted, per the append-only config model).
        format: MatchFormat(
          oversPerInnings: (config['overs_per_innings'] as num?)?.toInt() ?? 0,
          playersPerTeam: (config['players_per_team'] as num?)?.toInt() ?? 11,
          ballType: MatchBallType.fromWire(config['ball_type'] as String?),
          maxOversPerBowler:
              (config['max_overs_per_bowler'] as num?)?.toInt() ?? 0,
          ballsPerOver: (config['balls_per_over'] as num?)?.toInt() ?? 6,
          inningsPerSide: (config['innings_per_side'] as num?)?.toInt() ?? 1,
          wicketsToAllOut: (config['wickets_to_all_out'] as num?)?.toInt(),
          endChangeBalls: (config['end_change_balls'] as num?)?.toInt(),
        ),
      );
}
