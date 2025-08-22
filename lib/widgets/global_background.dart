import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/theme/app_style_manager.dart';

class GlobalBackground extends StatelessWidget {
  final Widget child;

  // Optional overrides (usually keep null to use tokens)
  final double? blurSigma;
  final double? darken;
  final double? lightenAdd;
  final String? assetPathOverride;

  const GlobalBackground({
    super.key,
    required this.child,
    this.blurSigma,
    this.darken,
    this.lightenAdd,
    this.assetPathOverride,
  });

  @override
  Widget build(BuildContext context) {
    final bg = context.watch<StyleManager>().currentStyle.background;

    final effectiveBlur     = blurSigma   ?? bg.blurSigma;
    final effectiveDarken   = darken      ?? bg.darken;
    final effectiveLightAdd = lightenAdd  ?? bg.lightenAdd;
    final assetPath         = assetPathOverride ?? bg.assetPath;

    return Stack(
      children: [
        // Base image (optionally additive-brightened)
        Positioned.fill(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            color: effectiveLightAdd > 0 ? Colors.white.withOpacity(effectiveLightAdd) : null,
            colorBlendMode: effectiveLightAdd > 0 ? BlendMode.plus : null,
          ),
        ),

        // Global blur
        Positioned.fill(
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Dark gradient for contrast
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(effectiveDarken + 0.10),
                    Colors.black.withOpacity(effectiveDarken),
                  ],
                ),
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}
