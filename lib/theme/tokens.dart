import 'package:flutter/material.dart';

/// Optional rendering mode for surfaces that currently use "glass".
/// - glass: blurred/translucent
/// - solid: flat/opaque (no blur, full opacity)
enum SurfaceMode { glass, solid }

class ButtonTokens {
  final Color primaryBg;
  final Color primaryFg;
  final Color subduedBg;
  final Color subduedFg;
  final Color dangerBg;
  final Color dangerFg;

  final double fontSize;      // NEW → text size per theme
  final EdgeInsets padding;   // NEW → button padding per theme
  final double borderRadius;  // NEW → corner radius per theme

  const ButtonTokens({
    required this.primaryBg,
    required this.primaryFg,
    required this.subduedBg,
    required this.subduedFg,
    required this.dangerBg,
    required this.dangerFg,
    this.fontSize = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.borderRadius = 12.0,
  });
}



class GlassTokens {
  // Existing
  final Color baseColor;
  final double opacity;
  final double blurSigma;
  final bool showBorder;
  final double cornerGap;

  // NEW (all optional with defaults)
  /// Visual mode toggle (glassy vs solid)
  final SurfaceMode mode;

  /// Hairline / outline opacity for borders or separators around glassy surfaces.
  final double strokeOpacity;

  /// Optional explicit border color. If null, use theme/text tokens to derive.
  final Color? borderColor;

  /// Elevation hint for components that want shadows (useful in solid modes).
  final double elevation;

  /// A subtle fill/hover highlight for interactive states on glass (0–1).
  final double highlightOpacity;

  const GlassTokens({
    // required (existing)
    required this.baseColor,
    required this.opacity,
    required this.blurSigma,
    required this.showBorder,
    required this.cornerGap,
    // new (optional)
    this.mode = SurfaceMode.glass,
    this.strokeOpacity = 0.16,
    this.borderColor,
    this.elevation = 0.0,
    this.highlightOpacity = 0.06,
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

/// Optional: component-level defaults you can tweak per theme
class CardTokens {
  final double elevation;       // default shadow/elevation
  final double strokeWidth;     // outline width for cards/panels
  final double strokeOpacity;   // outline opacity (multiplies color)
  final EdgeInsets padding;     // default card padding

  const CardTokens({
    this.elevation = 0.0,
    this.strokeWidth = 1.0,
    this.strokeOpacity = 0.16,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
  final ButtonTokens buttons;

  // NEW (optional bundle-level component defaults)
  final CardTokens card;

  const AppStyleTokens({
    required this.glass,
    required this.background,
    required this.textOnGlass,
    required this.radius,
    required this.buttons,
    this.card = const CardTokens(),
  });
}
