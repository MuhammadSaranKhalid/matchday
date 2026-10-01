import 'package:flutter/material.dart';

import '../foundation/palette.dart';

/// Cricket and tabular text tokens exposed through [ThemeData.extensions].
///
/// Material's standard [TextTheme] does not naturally represent cricket-specific
/// typography such as overs, run rates, tabular timestamps, eyebrows, or large
/// scoreboard figures.
@immutable
class TextTokens extends ThemeExtension<TextTokens> {
  const TextTokens({
    required this.metadata,
    required this.eyebrow,
    required this.metric,
    required this.score,
    required this.mono,
  });

  /// Monospace metadata (overs, time stamps, run rate).
  final TextStyle metadata;

  /// Uppercase section eyebrow label.
  final TextStyle eyebrow;

  /// Tabular metric number (e.g. 132/4, 8.4 rpo).
  final TextStyle metric;

  /// Large scoreboard score display.
  final TextStyle score;

  /// Monospace body typography for cricket figures and tabular metadata.
  final TextStyle mono;

  static const light = TextTokens(
    metadata: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: .7,
      color: Palette.muted,
    ),
    eyebrow: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: Palette.muted,
    ),
    metric: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Palette.ink,
    ),
    score: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Palette.ink,
    ),
    mono: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.14,
      color: Palette.muted,
    ),
  );

  @override
  TextTokens copyWith({
    TextStyle? metadata,
    TextStyle? eyebrow,
    TextStyle? metric,
    TextStyle? score,
    TextStyle? mono,
  }) {
    return TextTokens(
      metadata: metadata ?? this.metadata,
      eyebrow: eyebrow ?? this.eyebrow,
      metric: metric ?? this.metric,
      score: score ?? this.score,
      mono: mono ?? this.mono,
    );
  }

  @override
  TextTokens lerp(
    covariant ThemeExtension<TextTokens>? other,
    double t,
  ) {
    if (other is! TextTokens) return this;
    return TextTokens(
      metadata: TextStyle.lerp(metadata, other.metadata, t) ?? metadata,
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t) ?? eyebrow,
      metric: TextStyle.lerp(metric, other.metric, t) ?? metric,
      score: TextStyle.lerp(score, other.score, t) ?? score,
      mono: TextStyle.lerp(mono, other.mono, t) ?? mono,
    );
  }
}
