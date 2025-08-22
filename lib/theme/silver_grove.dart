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

  // Full-contrast text for better readability on glass
  textOnGlass: TextOnGlassTokens(
    primary: Colors.black,   // full contrast for titles & main text
    secondary: Colors.black, // subtitles/icons also pure black
    subtle: Colors.black,    // even hints & dividers are fully readable
  ),

  radius: RadiusTokens(card: 18),

  // 🌿 Button styling tuned for Silver Grove
  buttons: ButtonTokens(
    primaryBg: Color(0xFF2A7F6F),   // elegant muted teal-green
    primaryFg: Colors.white,

    subduedBg: Color(0xFFEDEDED),   // soft light gray
    subduedFg: Colors.black,        // max contrast for subdued buttons

    dangerBg: Color(0xFFD1495B),    // muted crimson
    dangerFg: Colors.white,

    // ✨ New sizing & typography
    fontSize: 15.5, // balanced size for light themes
    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    borderRadius: 22.0, // more rounded → softer, modern aesthetic
  ),
);
