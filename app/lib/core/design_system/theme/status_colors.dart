import 'package:flutter/material.dart';

import '../foundation/palette.dart';

/// Semantic functional status colors exposed through [ThemeData.extensions].
///
/// Encodes live competition states, success/win banners, warning/pending alerts,
/// matchday urgency cream, neutral badges, and the dark Champion Moment ground.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.live,
    required this.liveSurface,
    required this.liveBorder,
    required this.success,
    required this.successSurface,
    required this.successBorder,
    required this.warning,
    required this.warningSurface,
    required this.warningBorder,
    required this.cream,
    required this.creamBorder,
    required this.neutral,
    required this.neutralSurface,
    required this.neutralBorder,
    required this.championGround,
    required this.championRaised,
    required this.championHairline,
    required this.championGold,
  });

  /// Cricket Red for live status, urgent deadlines, and score highlights.
  final Color live;
  final Color liveSurface;
  final Color liveBorder;

  /// Grass Green for victory, approved status, and positive milestones.
  final Color success;
  final Color successSurface;
  final Color successBorder;

  /// Amber for pending reviews, cautions, and waitlists.
  final Color warning;
  final Color warningSurface;
  final Color warningBorder;

  /// Matchday Seam Cream for urgent banners and timer chips.
  final Color cream;
  final Color creamBorder;

  /// Neutral ink tones for default badges and calm state containers.
  final Color neutral;
  final Color neutralSurface;
  final Color neutralBorder;

  /// Champion Moment dark canvas tones.
  final Color championGround;
  final Color championRaised;
  final Color championHairline;
  final Color championGold;

  static const light = StatusColors(
    live: Palette.redInk,
    liveSurface: Palette.redSurface,
    liveBorder: Palette.redBorder,
    success: Palette.greenInk,
    successSurface: Palette.greenSurface,
    successBorder: Palette.greenBorder,
    warning: Palette.amberInk,
    warningSurface: Palette.cream,
    warningBorder: Palette.amber,
    cream: Palette.cream,
    creamBorder: Palette.creamBorder,
    neutral: Palette.ink,
    neutralSurface: Palette.paper2,
    neutralBorder: Palette.line,
    championGround: Palette.championGround,
    championRaised: Palette.championRaised,
    championHairline: Palette.championHairline,
    championGold: Palette.championGold,
  );

  @override
  StatusColors copyWith({
    Color? live,
    Color? liveSurface,
    Color? liveBorder,
    Color? success,
    Color? successSurface,
    Color? successBorder,
    Color? warning,
    Color? warningSurface,
    Color? warningBorder,
    Color? cream,
    Color? creamBorder,
    Color? neutral,
    Color? neutralSurface,
    Color? neutralBorder,
    Color? championGround,
    Color? championRaised,
    Color? championHairline,
    Color? championGold,
  }) {
    return StatusColors(
      live: live ?? this.live,
      liveSurface: liveSurface ?? this.liveSurface,
      liveBorder: liveBorder ?? this.liveBorder,
      success: success ?? this.success,
      successSurface: successSurface ?? this.successSurface,
      successBorder: successBorder ?? this.successBorder,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      warningBorder: warningBorder ?? this.warningBorder,
      cream: cream ?? this.cream,
      creamBorder: creamBorder ?? this.creamBorder,
      neutral: neutral ?? this.neutral,
      neutralSurface: neutralSurface ?? this.neutralSurface,
      neutralBorder: neutralBorder ?? this.neutralBorder,
      championGround: championGround ?? this.championGround,
      championRaised: championRaised ?? this.championRaised,
      championHairline: championHairline ?? this.championHairline,
      championGold: championGold ?? this.championGold,
    );
  }

  @override
  StatusColors lerp(
    covariant ThemeExtension<StatusColors>? other,
    double t,
  ) {
    if (other is! StatusColors) return this;
    return StatusColors(
      live: Color.lerp(live, other.live, t) ?? live,
      liveSurface: Color.lerp(liveSurface, other.liveSurface, t) ?? liveSurface,
      liveBorder: Color.lerp(liveBorder, other.liveBorder, t) ?? liveBorder,
      success: Color.lerp(success, other.success, t) ?? success,
      successSurface:
          Color.lerp(successSurface, other.successSurface, t) ?? successSurface,
      successBorder:
          Color.lerp(successBorder, other.successBorder, t) ?? successBorder,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningSurface:
          Color.lerp(warningSurface, other.warningSurface, t) ?? warningSurface,
      warningBorder:
          Color.lerp(warningBorder, other.warningBorder, t) ?? warningBorder,
      cream: Color.lerp(cream, other.cream, t) ?? cream,
      creamBorder: Color.lerp(creamBorder, other.creamBorder, t) ?? creamBorder,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
      neutralSurface:
          Color.lerp(neutralSurface, other.neutralSurface, t) ?? neutralSurface,
      neutralBorder:
          Color.lerp(neutralBorder, other.neutralBorder, t) ?? neutralBorder,
      championGround:
          Color.lerp(championGround, other.championGround, t) ?? championGround,
      championRaised:
          Color.lerp(championRaised, other.championRaised, t) ?? championRaised,
      championHairline:
          Color.lerp(championHairline, other.championHairline, t) ??
          championHairline,
      championGold:
          Color.lerp(championGold, other.championGold, t) ?? championGold,
    );
  }
}
