// lib/theme/widgets/token_panels.dart
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:roots_app/theme/tokens.dart';

/// A glass/solid-aware panel that follows your token recipe.
/// - Blur only when glass.mode == SurfaceMode.glass
/// - Background color from glass.baseColor with tokenized alpha
/// - Optional border (tokenized)
/// - Optional shadow for solid mode (tokenized elevation)
class TokenPanel extends StatelessWidget {
  final GlassTokens glass;
  final TextOnGlassTokens text;
  final Widget child;
  final bool useBlur;
  final EdgeInsets? padding;
  final double? borderRadius;

  const TokenPanel({
    super.key,
    required this.glass,
    required this.text,
    required this.child,
    this.useBlur = true,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius ?? 16);
    final borderColor =
        glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity);

    // Never fully invisible in glass mode
    final double fillOpacity = glass.mode == SurfaceMode.solid
        ? 1.0
        : (glass.opacity <= 0.02 ? 0.06 : glass.opacity);

    return RepaintBoundary(
      child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: br,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (glass.mode == SurfaceMode.glass && useBlur)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: glass.blurSigma,
                      sigmaY: glass.blurSigma,
                    ),
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: glass.baseColor.withValues(alpha: fillOpacity),
                borderRadius: br,
                border: glass.showBorder ? Border.all(color: borderColor) : null,
                boxShadow: glass.mode == SurfaceMode.solid && glass.elevation > 0
                    ? [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ]
                    : null,
              ),
              child: Padding(
                // Use provided padding or fallback to default
                padding: padding ?? const EdgeInsets.all(12),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header that uses tokenized text colors/sizes
class TokenSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextOnGlassTokens text;

  const TokenSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: text.primary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: TextStyle(color: text.subtle, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Divider that derives its color from the border or subtle text token.
class TokenDivider extends StatelessWidget {
  final GlassTokens glass;
  final TextOnGlassTokens text;

  const TokenDivider({
    super.key,
    required this.glass,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final c = (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity))
        .withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1, thickness: 1, color: c),
    );
  }
}

/// Small helper to build a token-consistent SnackBar (text + panel-like bg).
SnackBar buildTokenSnackBar({
  required String message,
  required GlassTokens glass,
  required TextOnGlassTokens text,
}) {
  return SnackBar(
    content: Text(
      message,
      style: TextStyle(color: text.primary),
    ),
    backgroundColor: glass.baseColor.withValues(alpha: 0.85),
    behavior: SnackBarBehavior.floating,
  );
}
