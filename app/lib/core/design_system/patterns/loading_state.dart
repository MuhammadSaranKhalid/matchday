import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated shimmer container for skeleton loading placeholders.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final scheme = context.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final t = _controller.value;
          return LinearGradient(
            begin: Alignment(-1.5 + t * 3, 0),
            end: Alignment(-0.5 + t * 3, 0),
            colors: [
              scheme.outline,
              scheme.surfaceContainer,
              scheme.outline,
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

/// Static placeholder box intended to be composed inside [ShimmerLoading].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 12.0,
    this.radius = 6.0,
    this.shape = BoxShape.rectangle,
    this.color,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? scheme.outlineVariant,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null,
      ),
    );
  }
}

/// Centered spinner loading state with an optional label.
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(layout.sectionGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: scheme.primary,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: layout.inlineGap),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ) ??
                    TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
