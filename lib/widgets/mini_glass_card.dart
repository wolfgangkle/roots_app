import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/theme/app_style_manager.dart';

class MiniGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  // Optional overrides; if null we use tokens
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final double? sigma;        // blur
  final double? opacity;      // tint alpha
  final Color? baseColor;

  // Optional extras
  final bool showGrain;

  // Border is off by default; you can re-enable later if wanted
  final bool showOpenBorder;
  final double? strokeOpacity;
  final double? strokeWidth;
  final double? cornerGap;

  const MiniGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.radius,
    this.sigma,
    this.opacity,
    this.baseColor,
    this.showGrain = false,
    this.showOpenBorder = false,
    this.strokeOpacity,
    this.strokeWidth,
    this.cornerGap,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.watch<StyleManager>().currentStyle.glass;

    final effectivePadding = padding ?? const EdgeInsets.all(12);
    final effectiveRadius  = radius  ?? g.cornerGap; // reuse cornerGap as shape radius token
    final r = Radius.circular(effectiveRadius);

    final effectiveSigma   = sigma    ?? g.blurSigma;
    final effectiveOpacity = opacity  ?? g.opacity;
    final effectiveColor   = baseColor ?? g.baseColor;

    final effectiveStrokeOpacity = strokeOpacity ?? 0.0;
    final effectiveStrokeWidth   = strokeWidth   ?? 1.0;
    final effectiveCornerGap     = cornerGap     ?? g.cornerGap;

    return ClipRRect(
      borderRadius: BorderRadius.all(r),
      child: Stack(
        children: [
          // Frosted blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: effectiveSigma, sigmaY: effectiveSigma),
              child: const SizedBox.expand(),
            ),
          ),

          // Translucent tint
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: effectiveOpacity),
              ),
            ),
          ),

          // Subtle top highlight for "glass" sheen
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Optional film grain
          if (showGrain)
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/ui/noise_512.png',
                  repeat: ImageRepeat.repeat,
                  opacity: const AlwaysStoppedAnimation(0.06),
                  filterQuality: FilterQuality.low,
                ),
              ),
            ),

          // Optional open-border (off by default)
          if (showOpenBorder && effectiveStrokeOpacity > 0 && effectiveStrokeWidth > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OpenBorderPainter(
                    strokeColor: Colors.white.withValues(alpha: effectiveStrokeOpacity),
                    strokeWidth: effectiveStrokeWidth,
                    cornerGap: effectiveCornerGap,
                  ),
                ),
              ),
            ),

          // Content + ripple
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.all(r),
              onTap: onTap,
              child: Padding(padding: effectivePadding, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenBorderPainter extends CustomPainter {
  final Color strokeColor;
  final double strokeWidth;
  final double cornerGap;

  _OpenBorderPainter({
    required this.strokeColor,
    required this.strokeWidth,
    required this.cornerGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // open edges (no corners)
    canvas.drawLine(Offset(cornerGap, 0), Offset(size.width - cornerGap, 0), paint);
    canvas.drawLine(Offset(cornerGap, size.height), Offset(size.width - cornerGap, size.height), paint);
    canvas.drawLine(Offset(0, cornerGap), Offset(0, size.height - cornerGap), paint);
    canvas.drawLine(Offset(size.width, cornerGap), Offset(size.width, size.height - cornerGap), paint);
  }

  @override
  bool shouldRepaint(covariant _OpenBorderPainter old) =>
      strokeColor != old.strokeColor ||
          strokeWidth != old.strokeWidth ||
          cornerGap != old.cornerGap;
}
