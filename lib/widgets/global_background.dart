import 'dart:ui';
import 'package:flutter/material.dart';

class GlobalBackground extends StatelessWidget {
  final Widget child;

  /// Tweak these if you want more/less mood later
  final double blurSigma;
  final double darken; // 0..1

  const GlobalBackground({
    super.key,
    required this.child,
    this.blurSigma = 26,   // strong blur for that “hint of scene” (20-34)
    this.darken = 0.28,    // subtle darkening so glass panels pop (0.28 - 0.45)
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scenic image
        Positioned.fill(
          child: Image.asset(
            'assets/images/backgrounds/roots_global_background.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
          ),
        ),

        // Global blur layer
        Positioned.fill(
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Subtle dark gradient (top→bottom)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(darken + 0.10),
                    Colors.black.withOpacity(darken),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content on top
        child,
      ],
    );
  }
}
