import 'package:flutter/material.dart';
import 'tokens.dart';

/// Solid medieval parchment theme (light, opaque, brown ink)
const ironKeep = AppStyleTokens(
  glass: GlassTokens(
    baseColor: Color(0xFFF3E8D7),   // parchment surface
    opacity: 0.98,                  // nearly fully opaque
    blurSigma: 0.0,                 // no blur
    showBorder: true,               // crisp ledger-style outline
    cornerGap: 10,
    mode: SurfaceMode.solid,        // solid mode (no blur)
    strokeOpacity: 0.22,            // used if borderColor isn't applied
    borderColor: Color(0x262F1A09), // ~15% deep-brown hairline
    elevation: 3.0,                 // gentle shadow for solidity
    highlightOpacity: 0.08,         // subtle pressed/hover tint
  ),

  background: BackgroundTokens(
    assetPath: 'assets/images/backgrounds/roots_global_background.png',
    blurSigma: 0,
    darken: 0.18,
    lightenAdd: 0.06,
  ),

  // “Brown ink” text on parchment
  textOnGlass: TextOnGlassTokens(
    primary: Color(0xFF2B1E11),   // dark brown (titles)
    secondary: Color(0xFF4B3324), // medium brown (icons/secondary)
    subtle: Color(0xFF7A5A45),    // warm subtle (dividers, hints)
  ),

  radius: RadiusTokens(card: 8),

  // Optional component defaults
  card: CardTokens(
    elevation: 3.0,
    strokeWidth: 1.0,
    strokeOpacity: 0.20,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),

  // 🪵 Button styling tuned for Iron Keep
  buttons: ButtonTokens(
    // Primary → deep brown, high contrast
    primaryBg: Color(0xFF5A3A1E),
    primaryFg: Color(0xFFF9F4EC),

    // Subdued → warm parchment ledger style
    subduedBg: Color(0xFFE8D8C3),
    subduedFg: Color(0xFF2B1E11),

    // Destructive → oxblood / red-brown
    dangerBg: Color(0xFF8E2A22),
    dangerFg: Color(0xFFF9F4EC),

    // ✨ New sizing & typography
    fontSize: 15.0, // slightly smaller than Dark Forge, medieval “ledger” feel
    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    borderRadius: 10.0, // sharper corners to fit the parchment vibe
  ),
);
