import 'dart:ui';
import 'package:flutter/material.dart';

class MiniGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double sigma;            // backdrop blur
  final double opacity;          // tint opacity (0..1)
  final Color baseColor;         // tint color

  // Border-related (now optional)
  final bool showOpenBorder;     // ⬅️ OFF by default
  final double strokeOpacity;    // used only if showOpenBorder = true
  final double strokeWidth;      // used only if showOpenBorder = true
  final double cornerGap;        // used only if showOpenBorder = true

  // Optional film grain
  final bool showGrain;

  const MiniGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.radius = 14,
    this.sigma = 12,
    this.opacity = 0.26,
    this.baseColor = const Color(0xFF1A1A1A),

    // borders are now opt-in
    this.showOpenBorder = false,
    this.strokeOpacity = 0.16,
    this.strokeWidth = 1.0,
    this.cornerGap = 14.0,

    this.showGrain = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(radius);

    return ClipRRect(
      borderRadius: BorderRadius.all(r),
      child: Stack(
        children: [
          // Frosted blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: const SizedBox.expand(),
            ),
          ),

          // Translucent tint
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: baseColor.withOpacity(opacity),
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
                      Colors.white.withOpacity(0.06),
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
          if (showOpenBorder && strokeOpacity > 0 && strokeWidth > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OpenBorderPainter(
                    strokeColor: Colors.white.withOpacity(strokeOpacity),
                    strokeWidth: strokeWidth,
                    radius: radius,
                    cornerGap: cornerGap,
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
              child: Padding(padding: padding, child: child),
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
  final double radius;
  final double cornerGap;

  _OpenBorderPainter({
    required this.strokeColor,
    required this.strokeWidth,
    required this.radius,
    required this.cornerGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top
    canvas.drawLine(
      Offset(cornerGap, 0),
      Offset(size.width - cornerGap, 0),
      paint,
    );
    // Bottom
    canvas.drawLine(
      Offset(cornerGap, size.height),
      Offset(size.width - cornerGap, size.height),
      paint,
    );
    // Left
    canvas.drawLine(
      Offset(0, cornerGap),
      Offset(0, size.height - cornerGap),
      paint,
    );
    // Right
    canvas.drawLine(
      Offset(size.width, cornerGap),
      Offset(size.width, size.height - cornerGap),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OpenBorderPainter oldDelegate) {
    return strokeColor != oldDelegate.strokeColor ||
        strokeWidth != oldDelegate.strokeWidth ||
        radius != oldDelegate.radius ||
        cornerGap != oldDelegate.cornerGap;
  }
}
