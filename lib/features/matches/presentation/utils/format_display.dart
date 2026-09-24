import '../../domain/entities/format_preset.dart';
import '../../domain/entities/match.dart';

/// Returns a user-facing title for a format code or preset.
///
/// e.g.
/// - 't20' -> 'T20'
/// - 't10' -> 'T10'
/// - 'quick_6' -> '6 Over'
/// - 'quick_8' -> '8 Over'
/// - 'over_30' -> '30 Over'
/// - 'over_40' -> '40 Over'
/// - 'over_45' -> '45 Over'
/// - 'over_50' -> '50 Over'
/// - 'custom' -> 'CUSTOM ($overs OVERS)'
String formatTitle({
  FormatPreset? preset,
  String? formatCode,
  bool isCustom = false,
  required int overs,
}) {
  if (isCustom || formatCode == 'custom') {
    return 'CUSTOM ($overs OVERS)';
  }
  final code = preset?.id ?? formatCode;
  if (code != null) {
    switch (code) {
      case 't20':
        return 'T20';
      case 't10':
        return 'T10';
      case 'quick_6':
        return '6 Over';
      case 'quick_8':
        return '8 Over';
      case 'over_30':
        return '30 Over';
      case 'over_40':
        return '40 Over';
      case 'over_45':
        return '45 Over';
      case 'over_50':
        return '50 OVER';
    }
  }
  if (preset != null) {
    final label = preset.label.toUpperCase();
    return label;
  }
  return '$overs OVERS';
}

/// Formats the spec line: "20 overs · Tape-ball · 11-a-side"
String formatSpecLine({
  required int overs,
  required MatchBallType ball,
  required int playersPerSide,
}) {
  final ballLabel = switch (ball) {
    MatchBallType.tape => 'Tape-ball',
    MatchBallType.tennis => 'Tennis',
    MatchBallType.leather => 'Leather',
  };
  final parts = <String>[
    if (overs > 0) '$overs overs',
    ballLabel,
    '$playersPerSide-a-side',
  ];
  return parts.join(' · ');
}

/// Compact single-line summary e.g. "T20 · 20 ov · 11-a-side · Tape"
String formatSummary(MatchFormat format, {String? formatCode}) {
  final title = formatTitle(
    formatCode: formatCode ?? format.formatCode,
    isCustom: (formatCode ?? format.formatCode) == 'custom',
    overs: format.oversPerInnings,
  );
  final ballLabel = switch (format.ballType) {
    MatchBallType.tape => 'Tape',
    MatchBallType.tennis => 'Tennis',
    MatchBallType.leather => 'Leather',
  };
  return '$title · ${format.oversPerInnings} ov · ${format.playersPerTeam}-a-side · $ballLabel';
}
