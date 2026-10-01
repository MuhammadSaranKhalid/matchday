import 'package:flutter/material.dart';

/// Cricket and tabular text tokens exposed through [ThemeData.extensions].
///
/// Material's standard [TextTheme] does not naturally represent cricket-specific
/// typography such as overs, run rates, tabular timestamps, eyebrows, or large
/// scoreboard figures.
///
/// These tokens define the **typographic shape** only (family, size, weight,
/// tracking, line-height). Color is intentionally absent — consumers apply
/// semantic color at the call site via `.copyWith(color: context.colorScheme.*)`.
/// This separation allows the token set to survive theme changes (dark mode,
/// high contrast) without modification.
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

  /// Shape-only token set — no theme-bound colors.
  ///
  /// The name [light] is kept for API compatibility; it does not imply a
  /// color-theme variant. Dark-theme support will supply the same shapes
  /// with colors injected at each call site.
  static const light = TextTokens(
    metadata: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: .7,
    ),
    eyebrow: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
    ),
    metric: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
    score: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    mono: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.14,
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
