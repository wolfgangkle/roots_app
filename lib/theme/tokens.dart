import 'package:flutter/material.dart';

class GlassTokens {
  final Color baseColor;
  final double opacity;      // 0..1
  final double blurSigma;
  final bool showBorder;     // we keep off by default
  final double cornerGap;

  const GlassTokens({
    this.baseColor = const Color(0xFF1A1A1A),
    this.opacity = 0.28,
    this.blurSigma = 10,
    this.showBorder = false,
    this.cornerGap = 16,
  });
}

class BackgroundTokens {
  final String assetPath;
  final double blurSigma;
  final double darken;       // 0..1
  final double lightenAdd;   // 0..1 (keep 0 to avoid milkiness)

  const BackgroundTokens({
    this.assetPath = 'assets/images/backgrounds/roots_global_background.png',
    this.blurSigma = 26,
    this.darken = 0.36,
    this.lightenAdd = 0.00,
  });
}

class TextOnGlassTokens {
  final Color primary;   // titles/numbers
  final Color secondary; // body
  final Color subtle;    // hints/brackets etc.

  const TextOnGlassTokens({
    this.primary = const Color(0xFFFFFFFF),            // we’ll apply opacity in code
    this.secondary = const Color(0xFFFFFFFF),
    this.subtle = const Color(0xFFFFFFFF),
  });
}

class RadiusTokens {
  final double card;
  const RadiusTokens({ this.card = 14 });
}

class AppStyleTokens {
  final GlassTokens glass;
  final BackgroundTokens background;
  final TextOnGlassTokens textOnGlass;
  final RadiusTokens radius;

  const AppStyleTokens({
    this.glass = const GlassTokens(),
    this.background = const BackgroundTokens(),
    this.textOnGlass = const TextOnGlassTokens(),
    this.radius = const RadiusTokens(),
  });
}

// Current default (your “Dark Forge” look)
const kStyle = AppStyleTokens();
