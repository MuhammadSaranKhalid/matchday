import 'package:flutter/material.dart';

import '../foundation/radii.dart';
import '../foundation/sizing.dart';
import '../foundation/spacing.dart';

/// Layout tokens exposed through [ThemeData.extensions] as the standardized
/// layout and geometry contract.
@immutable
class LayoutTokens extends ThemeExtension<LayoutTokens> {
  const LayoutTokens({
    required this.screenGutter,
    required this.screenBottom,
    required this.sectionGap,
    required this.majorSectionGap,
    required this.itemGap,
    required this.inlineGap,
    required this.cardPadding,
    required this.compactCardPadding,
    required this.comfortableCardPadding,
    required this.controlLargeHeight,
    required this.controlHeight,
    required this.controlCompactHeight,
    required this.minimumTapTarget,
    required this.controlRadius,
    required this.cardRadius,
    required this.modalRadius,
    required this.heroRadius,
  });

  /// Horizontal margin between screen edge and content (default: 16.0).
  final double screenGutter;

  /// Bottom inset below scrollable content (default: 24.0).
  final double screenBottom;

  /// Vertical spacing between standard content sections (default: 24.0).
  final double sectionGap;

  /// Vertical spacing between major structural sections (default: 32.0).
  final double majorSectionGap;

  /// Spacing between list items or vertical stack items (default: 12.0).
  final double itemGap;

  /// Spacing between inline elements, chips, or row items (default: 8.0).
  final double inlineGap;

  /// Standard inner card padding (default: 16.0).
  final double cardPadding;

  /// Compact inner card padding (default: 12.0).
  final double compactCardPadding;

  /// Comfortable inner card padding (default: 20.0).
  final double comfortableCardPadding;

  /// Prominent primary CTA button height (default: 52.0).
  final double controlLargeHeight;

  /// Standard button/field height (default: 48.0).
  final double controlHeight;

  /// Compact button visual height (default: 40.0).
  final double controlCompactHeight;

  /// Minimum accessible touch target (default: 48.0).
  final double minimumTapTarget;

  /// Standard control border radius (default: 14.0).
  final double controlRadius;

  /// Standard card border radius (default: 14.0).
  final double cardRadius;

  /// Bottom sheet & modal border radius (default: 20.0).
  final double modalRadius;

  /// Hero / featured card border radius (default: 20.0).
  final double heroRadius;

  static const standard = LayoutTokens(
    screenGutter: Spacing.md,
    screenBottom: Spacing.xl,
    sectionGap: Spacing.xl,
    majorSectionGap: Spacing.xxl,
    itemGap: Spacing.sm,
    inlineGap: Spacing.xs,
    cardPadding: Spacing.md,
    compactCardPadding: Spacing.sm,
    comfortableCardPadding: Spacing.lg,
    controlLargeHeight: Sizing.controlLargeHeight,
    controlHeight: Sizing.controlHeight,
    controlCompactHeight: Sizing.controlCompactHeight,
    minimumTapTarget: Sizing.minimumTapTarget,
    controlRadius: Radii.control,
    cardRadius: Radii.card,
    modalRadius: Radii.modal,
    heroRadius: Radii.hero,
  );

  /// Legacy alias for [standard]. Layout tokens are theme-mode agnostic.
  static const light = standard;

  @override
  LayoutTokens copyWith({
    double? screenGutter,
    double? screenBottom,
    double? sectionGap,
    double? majorSectionGap,
    double? itemGap,
    double? inlineGap,
    double? cardPadding,
    double? compactCardPadding,
    double? comfortableCardPadding,
    double? controlLargeHeight,
    double? controlHeight,
    double? controlCompactHeight,
    double? minimumTapTarget,
    double? controlRadius,
    double? cardRadius,
    double? modalRadius,
    double? heroRadius,
  }) {
    return LayoutTokens(
      screenGutter: screenGutter ?? this.screenGutter,
      screenBottom: screenBottom ?? this.screenBottom,
      sectionGap: sectionGap ?? this.sectionGap,
      majorSectionGap: majorSectionGap ?? this.majorSectionGap,
      itemGap: itemGap ?? this.itemGap,
      inlineGap: inlineGap ?? this.inlineGap,
      cardPadding: cardPadding ?? this.cardPadding,
      compactCardPadding: compactCardPadding ?? this.compactCardPadding,
      comfortableCardPadding:
          comfortableCardPadding ?? this.comfortableCardPadding,
      controlLargeHeight: controlLargeHeight ?? this.controlLargeHeight,
      controlHeight: controlHeight ?? this.controlHeight,
      controlCompactHeight: controlCompactHeight ?? this.controlCompactHeight,
      minimumTapTarget: minimumTapTarget ?? this.minimumTapTarget,
      controlRadius: controlRadius ?? this.controlRadius,
      cardRadius: cardRadius ?? this.cardRadius,
      modalRadius: modalRadius ?? this.modalRadius,
      heroRadius: heroRadius ?? this.heroRadius,
    );
  }

  @override
  LayoutTokens lerp(
    covariant ThemeExtension<LayoutTokens>? other,
    double t,
  ) {
    if (other is! LayoutTokens) return this;
    double v(double a, double b) => a + (b - a) * t;
    return LayoutTokens(
      screenGutter: v(screenGutter, other.screenGutter),
      screenBottom: v(screenBottom, other.screenBottom),
      sectionGap: v(sectionGap, other.sectionGap),
      majorSectionGap: v(majorSectionGap, other.majorSectionGap),
      itemGap: v(itemGap, other.itemGap),
      inlineGap: v(inlineGap, other.inlineGap),
      cardPadding: v(cardPadding, other.cardPadding),
      compactCardPadding: v(compactCardPadding, other.compactCardPadding),
      comfortableCardPadding:
          v(comfortableCardPadding, other.comfortableCardPadding),
      controlLargeHeight: v(controlLargeHeight, other.controlLargeHeight),
      controlHeight: v(controlHeight, other.controlHeight),
      controlCompactHeight: v(controlCompactHeight, other.controlCompactHeight),
      minimumTapTarget: v(minimumTapTarget, other.minimumTapTarget),
      controlRadius: v(controlRadius, other.controlRadius),
      cardRadius: v(cardRadius, other.cardRadius),
      modalRadius: v(modalRadius, other.modalRadius),
      heroRadius: v(heroRadius, other.heroRadius),
    );
  }
}
