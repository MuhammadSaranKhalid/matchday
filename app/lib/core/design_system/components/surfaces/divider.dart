import 'package:flutter/material.dart';

import '../../foundation/palette.dart';

/// Standardized horizontal divider primitive.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.indent,
    this.endIndent,
    this.thickness = 1.0,
    this.color,
  });

  final double? indent;
  final double? endIndent;
  final double thickness;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: thickness,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color ?? Palette.hairline,
    );
  }
}
