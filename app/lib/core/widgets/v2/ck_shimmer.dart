import 'package:flutter/material.dart';

import '../../theme/circk_theme.dart';

/// Animated shimmer effect for skeleton loading states.
///
/// Wraps a child (typically a tree of [CkShimmerBox] placeholders) and sweeps
/// a horizontal highlight gradient across it. Uses [CkColors.line] as the
/// base and [CkColors.paper2] as the highlight so the effect reads naturally
/// against the paper background.
///
/// Pass [enabled] = false to render the child without animation (e.g. when
/// data has arrived and you want to swap the same tree to the real widgets).
class CkShimmer extends StatefulWidget {
  const CkShimmer({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<CkShimmer> createState() => _CkShimmerState();
}

class _CkShimmerState extends State<CkShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final t = _c.value;
          return LinearGradient(
            begin: Alignment(-1.5 + t * 3, 0),
            end: Alignment(-0.5 + t * 3, 0),
            colors: const [
              CkColors.line,
              CkColors.paper2,
              CkColors.line,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// A static rounded-rect placeholder block intended to be wrapped in
/// [CkShimmer]. Use these to compose a skeleton that mirrors the real
/// layout's shape (avatar circles, text lines, image rectangles, etc.).
class CkShimmerBox extends StatelessWidget {
  const CkShimmerBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
    this.shape = BoxShape.rectangle,
  });

  /// Null = expand to fill the parent's width.
  final double? width;
  final double height;
  final double radius;

  /// [BoxShape.circle] for round avatars / dots; otherwise a rounded rect.
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CkColors.line,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null,
      ),
    );
  }
}
