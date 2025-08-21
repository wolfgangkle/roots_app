import 'package:flutter/material.dart';
import 'tokens.dart';

const silverGrove = AppStyleTokens(
  glass: GlassTokens(
    baseColor: Color(0xFFFAFAFA),
    opacity: 0.16,
    blurSigma: 20,
    showBorder: false,
    cornerGap: 18,
  ),
  background: BackgroundTokens(
    assetPath: 'assets/images/backgrounds/roots_global_background.png',
    blurSigma: 24,
    darken: 0.12,
    lightenAdd: 0.1,
  ),
  textOnGlass: TextOnGlassTokens(
    primary: Color(0xFF1B1B1B),
    secondary: Color(0xFF2C2C2C),
    subtle: Color(0xFF5F5F5F),
  ),
  radius: RadiusTokens(card: 18),
);
