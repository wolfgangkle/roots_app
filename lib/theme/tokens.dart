import 'package:flutter/material.dart';

class GlassTokens {
  final Color baseColor;
  final double opacity;
  final double blurSigma;
  final bool showBorder;
  final double cornerGap;

  const GlassTokens({
    required this.baseColor,
    required this.opacity,
    required this.blurSigma,
    required this.showBorder,
    required this.cornerGap,
  });
}

class BackgroundTokens {
  final String assetPath;
  final double blurSigma;
  final double darken;
  final double lightenAdd;

  const BackgroundTokens({
    required this.assetPath,
    required this.blurSigma,
    required this.darken,
    required this.lightenAdd,
  });
}

class TextOnGlassTokens {
  final Color primary;
  final Color secondary;
  final Color subtle;

  const TextOnGlassTokens({
    required this.primary,
    required this.secondary,
    required this.subtle,
  });
}

class RadiusTokens {
  final double card;
  const RadiusTokens({required this.card});
}

class AppStyleTokens {
  final GlassTokens glass;
  final BackgroundTokens background;
  final TextOnGlassTokens textOnGlass;
  final RadiusTokens radius;

  const AppStyleTokens({
    required this.glass,
    required this.background,
    required this.textOnGlass,
    required this.radius,
  });
}
