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
    subtle: Colors.white70,
  ),
  radius: RadiusTokens(card: 14),
  buttons: ButtonTokens(
    primaryBg: Color(0xFF1B4332),
    primaryFg: Colors.white,
    subduedBg: Color(0xFF333333),
    subduedFg: Colors.white,
    dangerBg: Color(0xFFD1495B),
    dangerFg: Colors.white,
    fontSize: 16.0,                      // slightly larger text in this theme
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14), // bigger buttons
    borderRadius: 20.0,                  // more rounded corners for this theme
  ),
);
