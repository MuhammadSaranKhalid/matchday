import 'package:equatable/equatable.dart';

import '../../../domain/entities/format_preset.dart';
import '../../../domain/entities/match.dart';

/// Mutable-friendly draft state representing the format selection and rules
/// in challenge creation and counter workflows.
class CricketFormatDraft extends Equatable {
  const CricketFormatDraft({
    required this.formatCode,
    required this.overs,
    this.ballsPerOver = 6,
    this.ballType = MatchBallType.tape,
    this.playersPerSide = 11,
    required this.maxOversPerBowler,
    this.inningsPerSide = 1,
  });

  final String formatCode;
  final int overs;
  final int ballsPerOver;
  final MatchBallType ballType;
  final int playersPerSide;
  final int maxOversPerBowler;
  final int inningsPerSide;

  bool get isCustom => formatCode == 'custom';

  factory CricketFormatDraft.initial() => const CricketFormatDraft(
    formatCode: 't20',
    overs: 20,
    ballsPerOver: 6,
    ballType: MatchBallType.tape,
    playersPerSide: 11,
    maxOversPerBowler: 4,
    inningsPerSide: 1,
  );

  factory CricketFormatDraft.fromSelection(CricketFormatSelection selection) =>
      CricketFormatDraft(
        formatCode: selection.formatCode,
        overs: selection.overs,
        ballsPerOver: selection.ballsPerOver,
        ballType: selection.ballType,
        playersPerSide: selection.playersPerSide,
        maxOversPerBowler: selection.maxOversPerBowler,
        inningsPerSide: selection.inningsPerSide,
      );

  factory CricketFormatDraft.fromFormat(
    MatchFormat format, {
    String? formatCode,
  }) => CricketFormatDraft(
    formatCode: formatCode ?? format.formatCode ?? (format.oversPerInnings == 20 ? 't20' : 'custom'),
    overs: format.oversPerInnings,
    ballsPerOver: format.ballsPerOver,
    ballType: format.ballType,
    playersPerSide: format.playersPerTeam,
    maxOversPerBowler: format.maxOversPerBowler > 0
        ? format.maxOversPerBowler
        : CricketFormatSelection.suggestedBowlerLimit(format.oversPerInnings),
    inningsPerSide: format.inningsPerSide,
  );

  CricketFormatSelection toSelection() => CricketFormatSelection(
    formatCode: formatCode,
    overs: overs,
    ballsPerOver: ballsPerOver,
    ballType: ballType,
    playersPerSide: playersPerSide,
    maxOversPerBowler: maxOversPerBowler,
    inningsPerSide: inningsPerSide,
  );

  MatchFormat toMatchFormat() => MatchFormat(
    formatCode: formatCode,
    oversPerInnings: overs,
    playersPerTeam: playersPerSide,
    ballType: ballType,
    maxOversPerBowler: maxOversPerBowler,
    ballsPerOver: ballsPerOver,
    inningsPerSide: inningsPerSide,
  );

  CricketFormatDraft applyPreset(FormatPreset preset) {
    final presetOvers = preset.format.oversPerInnings;
    final derivedLimit = preset.format.maxOversPerBowler > 0
        ? preset.format.maxOversPerBowler
        : CricketFormatSelection.suggestedBowlerLimit(presetOvers);
    return copyWith(
      formatCode: preset.id,
      overs: presetOvers,
      maxOversPerBowler: derivedLimit,
      ballsPerOver: preset.format.ballsPerOver > 0 ? preset.format.ballsPerOver : 6,
      playersPerSide: preset.format.playersPerTeam > 0 ? preset.format.playersPerTeam : playersPerSide,
    );
  }

  CricketFormatDraft copyWith({
    String? formatCode,
    int? overs,
    int? ballsPerOver,
    MatchBallType? ballType,
    int? playersPerSide,
    int? maxOversPerBowler,
    int? inningsPerSide,
  }) => CricketFormatDraft(
    formatCode: formatCode ?? this.formatCode,
    overs: overs ?? this.overs,
    ballsPerOver: ballsPerOver ?? this.ballsPerOver,
    ballType: ballType ?? this.ballType,
    playersPerSide: playersPerSide ?? this.playersPerSide,
    maxOversPerBowler: maxOversPerBowler ?? this.maxOversPerBowler,
    inningsPerSide: inningsPerSide ?? this.inningsPerSide,
  );

  @override
  List<Object?> get props => [
    formatCode,
    overs,
    ballsPerOver,
    ballType,
    playersPerSide,
    maxOversPerBowler,
    inningsPerSide,
  ];
}
