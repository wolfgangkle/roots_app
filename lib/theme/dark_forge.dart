import 'package:flutter/material.dart';
import 'tokens.dart';

const darkForge = AppStyleTokens(
  glass: GlassTokens(
    baseColor: Color(0xFF1A1A1A),
    opacity: 0.28,
    blurSigma: 10,
    showBorder: false,
    cornerGap: 16,
  ),
  background: BackgroundTokens(
    assetPath: 'assets/images/backgrounds/roots_global_background.png',
    blurSigma: 26,
    darken: 0.36,
    lightenAdd: 0.0,
  ),
  textOnGlass: TextOnGlassTokens(
    primary: Colors.white,
    secondary: Colors.white,
    subtle: Colors.white,
  ),
  radius: RadiusTokens(card: 14),
);
