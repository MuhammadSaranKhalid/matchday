import 'package:flutter/material.dart';

import '../../../../../core/theme/circk_theme.dart';

/// Shared atoms for the completed-match screen. Every figure on this screen is
/// tabular mono so columns line up down the page; every label is mono caps.
class CmText {
  /// A column label — "R", "B", "SR", "FALL OF WICKETS".
  static TextStyle label({double size = 9, Color? color}) => CkType.mono(
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.10,
    color: color ?? CkColors.muted,
  );

  /// A figure. Tabular so that 111 and 999 occupy the same width.
  static TextStyle figure({
    double size = 12,
    FontWeight weight = FontWeight.w700,
    Color color = CkColors.ink,
  }) => CkType.mono(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: 0,
    color: color,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// A person's or team's name.
  static TextStyle name({
    double size = 13.5,
    FontWeight weight = FontWeight.w600,
    Color color = CkColors.ink,
  }) => CkType.display(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: 0,
    color: color,
  );
}

/// A team's colour chip. 16px in tables, 20px in the result card.
class CmCrest extends StatelessWidget {
  const CmCrest(this.color, {this.size = 16, this.text, super.key});

  final Color color;
  final double size;
  final String? text;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child:
        text == null
            ? null
            : Text(
              text!,
              style: CkType.display(
                fontSize: size * 0.425,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: Colors.white,
              ),
            ),
  );
}

/// "TOP PERFORMERS ─────" — a mono cap followed by a hairline rule.
class CmSectionHeading extends StatelessWidget {
  const CmSectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(text.toUpperCase(), style: CmText.label(size: 9.5)),
      const SizedBox(width: 9),
      const Expanded(child: Divider(height: 1, color: CkColors.hairline)),
    ],
  );
}

/// The white, hairline-bordered slab every table on this screen sits in.
class CmPanel extends StatelessWidget {
  const CmPanel({required this.children, this.background, super.key});

  final List<Widget> children;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: background ?? CkColors.surface,
      border: Border.all(color: CkColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// A table's header strip — paper, hairline underline, mono caps.
class CmTableHeader extends StatelessWidget {
  const CmTableHeader({required this.cells, super.key});

  /// (label, width) — a null width takes the remaining space.
  final List<({String text, double? width})> cells;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: const BoxDecoration(
      color: CkColors.paper,
      border: Border(bottom: BorderSide(color: CkColors.hairline)),
    ),
    child: Row(
      children: [
        for (final c in cells) ...[
          if (c.width == null)
            Expanded(child: Text(c.text.toUpperCase(), style: CmText.label()))
          else
            SizedBox(
              width: c.width,
              child: Text(
                c.text.toUpperCase(),
                textAlign: TextAlign.right,
                style: CmText.label(size: 9),
              ),
            ),
          const SizedBox(width: 9),
        ],
      ]..removeLast(),
    ),
  );
}

/// A right-aligned fixed-width figure cell. The figures never truncate — only
/// the name column does.
class CmFigureCell extends StatelessWidget {
  const CmFigureCell(
    this.text, {
    required this.width,
    this.size = 12,
    this.weight = FontWeight.w700,
    this.color = CkColors.ink,
    super.key,
  });

  final String text;
  final double width;
  final double size;
  final FontWeight weight;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Text(
      text,
      textAlign: TextAlign.right,
      style: CmText.figure(size: size, weight: weight, color: color),
    ),
  );
}
