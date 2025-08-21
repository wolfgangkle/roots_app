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

  // Keep your existing background for now; tune brightness for parchment UI
  background: BackgroundTokens(
    assetPath: 'assets/images/backgrounds/roots_global_background.png',
    blurSigma: 0,     // keep background crisp under solid surfaces
    darken: 0.18,     // slightly dim so parchment stands out
    lightenAdd: 0.06, // mild warmth lift
  ),

  // “Brown ink” text on parchment
  textOnGlass: TextOnGlassTokens(
    primary: Color(0xFF2B1E11),   // dark brown (titles)
    secondary: Color(0xFF4B3324), // medium brown (icons/secondary)
    subtle: Color(0xFF7A5A45),    // warm subtle (dividers, hints)
  ),

  // Slightly sharper corners -> medieval ledger vibe
  radius: RadiusTokens(card: 8),

  // Optional component defaults (if you added CardTokens)
  card: CardTokens(
    elevation: 3.0,
    strokeWidth: 1.0,
    strokeOpacity: 0.20,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);
