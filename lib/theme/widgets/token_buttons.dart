// lib/theme/widgets/token_buttons.dart
import 'package:flutter/material.dart';
import 'package:roots_app/theme/tokens.dart';

enum TokenButtonVariant { primary, subdued, danger, outline, ghost }

class ButtonPalette {
  final Color? primaryBg, primaryFg, subduedBg, subduedFg, dangerBg, dangerFg, outlineBorder;
  const ButtonPalette({
    this.primaryBg, this.primaryFg,
    this.subduedBg, this.subduedFg,
    this.dangerBg, this.dangerFg,
    this.outlineBorder,
  });
}

ButtonStyle tokenButtonStyle({
  required TokenButtonVariant variant,
  required GlassTokens glass,
  required TextOnGlassTokens text,
  ButtonTokens? buttons,            // ← new: per-theme sizing/colors
  ButtonPalette? palette,           // optional per-call overrides
  double? radius,                   // if null → buttons?.borderRadius → 12
  EdgeInsets? padding,              // if null → buttons?.padding → default
}) {
  // Resolve sizing from tokens with safe fallbacks
  final double resolvedRadius = radius ?? buttons?.borderRadius ?? 12.0;
  final EdgeInsets resolvedPadding =
      padding ?? buttons?.padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  final BorderRadius br = BorderRadius.circular(resolvedRadius);

  // Clamp alpha into [0,1]
  double clampAlpha(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

  // Base fill for glass vs. solid
  final bool isSolid = glass.mode == SurfaceMode.solid;
  final double baseFill = isSolid ? 1.0 : (glass.opacity <= 0.02 ? 0.06 : glass.opacity);

  Color _baseBgForVariant() {
    switch (variant) {
      case TokenButtonVariant.primary:
        return (buttons?.primaryBg ?? palette?.primaryBg) ?? glass.baseColor;
      case TokenButtonVariant.subdued:
        return (buttons?.subduedBg ?? palette?.subduedBg) ?? glass.baseColor;
      case TokenButtonVariant.danger:
        return (buttons?.dangerBg ?? palette?.dangerBg) ?? glass.baseColor;
      case TokenButtonVariant.outline:
      case TokenButtonVariant.ghost:
        return glass.baseColor;
    }
  }

  Color _baseFgForVariant() {
    switch (variant) {
      case TokenButtonVariant.primary:
        return (buttons?.primaryFg ?? palette?.primaryFg) ?? text.primary;
      case TokenButtonVariant.subdued:
        return (buttons?.subduedFg ?? palette?.subduedFg) ?? text.secondary;
      case TokenButtonVariant.danger:
        return (buttons?.dangerFg ?? palette?.dangerFg) ?? text.primary;
      case TokenButtonVariant.outline:
      case TokenButtonVariant.ghost:
        return text.primary;
    }
  }

  Color resolveBg(
      Color base, {
        required bool pressed,
        required bool hovered,
        required bool focused,
        required bool disabled,
        double bump = 0.0,
      }) {
    double alpha = isSolid ? 1.0 : clampAlpha(baseFill + bump);
    final double dPress = isSolid ? 0.04 : 0.06;
    final double dHover = isSolid ? 0.02 : 0.04;
    final double dFocus = isSolid ? 0.01 : 0.02;

    if (pressed) alpha = clampAlpha(alpha + dPress);
    if (hovered) alpha = clampAlpha(alpha + dHover);
    if (focused) alpha = clampAlpha(alpha + dFocus);
    if (disabled) alpha = clampAlpha(alpha * 0.65);

    return base.withValues(alpha: alpha);
  }

  Color bgColor(Set<WidgetState> states) {
    final disabled = states.contains(WidgetState.disabled);
    final pressed  = states.contains(WidgetState.pressed);
    final hovered  = states.contains(WidgetState.hovered);
    final focused  = states.contains(WidgetState.focused);

    switch (variant) {
      case TokenButtonVariant.primary:
        return resolveBg(_baseBgForVariant(),
            pressed: pressed, hovered: hovered, focused: focused, disabled: disabled, bump: 0.10);
      case TokenButtonVariant.subdued:
        return resolveBg(_baseBgForVariant(),
            pressed: pressed, hovered: hovered, focused: focused, disabled: disabled, bump: 0.05);
      case TokenButtonVariant.danger:
        return resolveBg(_baseBgForVariant(),
            pressed: pressed, hovered: hovered, focused: focused, disabled: disabled, bump: 0.08);
      case TokenButtonVariant.outline:
      case TokenButtonVariant.ghost:
        double a = 0.0;
        if (pressed) a = 0.12;
        else if (hovered) a = 0.08;
        else if (focused) a = 0.06;
        if (disabled) a *= 0.6;
        return glass.baseColor.withValues(alpha: a);
    }
  }

  Color fgColor(Set<WidgetState> states) {
    final disabled = states.contains(WidgetState.disabled);
    final base = _baseFgForVariant();
    return disabled ? base.withValues(alpha: 0.5) : base;
  }

  Color borderForOutline(Set<WidgetState> states) {
    final disabled = states.contains(WidgetState.disabled);
    final pressed  = states.contains(WidgetState.pressed);
    final hovered  = states.contains(WidgetState.hovered);
    final focused  = states.contains(WidgetState.focused);

    double alpha = glass.strokeOpacity;
    if (pressed) alpha = clampAlpha(alpha + 0.05);
    else if (hovered) alpha = clampAlpha(alpha + 0.03);
    else if (focused) alpha = clampAlpha(alpha + 0.02);
    if (disabled) alpha *= 0.6;

    final Color baseBorder = palette?.outlineBorder ?? (glass.borderColor ?? text.subtle);
    return baseBorder.withValues(alpha: alpha);
  }

  Color overlayColor(Set<WidgetState> states) {
    final pressed = states.contains(WidgetState.pressed);
    final hovered = states.contains(WidgetState.hovered);
    final focused = states.contains(WidgetState.focused);
    final a = pressed ? 0.12 : hovered ? 0.08 : focused ? 0.06 : 0.0;
    return fgColor(states).withValues(alpha: a);
  }

  final shape = WidgetStatePropertyAll<RoundedRectangleBorder>(
    RoundedRectangleBorder(borderRadius: br),
  );

  final background = WidgetStateProperty.resolveWith<Color>(bgColor);
  final foreground = WidgetStateProperty.resolveWith<Color>(fgColor);
  final overlay    = WidgetStateProperty.resolveWith<Color>(overlayColor);

  final side = variant == TokenButtonVariant.outline
      ? WidgetStateProperty.resolveWith<BorderSide>(
        (states) => BorderSide(color: borderForOutline(states), width: 1.0),
  )
      : null;

  // NEW: text size from tokens
  final textStyle = WidgetStatePropertyAll<TextStyle>(
    TextStyle(fontSize: buttons?.fontSize ?? 14.0),
  );

  return ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
    padding: WidgetStatePropertyAll(resolvedPadding),
    shape: shape,
    textStyle: textStyle,               // ← apply themed font size
    foregroundColor: foreground,
    backgroundColor: background,
    overlayColor: overlay,
    side: side,
    elevation: WidgetStatePropertyAll(
      variant == TokenButtonVariant.primary && isSolid ? 1.0 : 0.0,
    ),
  );
}

/// Convenience wrappers

class TokenButton extends StatelessWidget {
  final TokenButtonVariant variant;
  final GlassTokens glass;
  final TextOnGlassTokens text;
  final ButtonTokens? buttons;
  final ButtonPalette? palette;
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsets? padding;
  final double? radius;

  const TokenButton({
    super.key,
    required this.variant,
    required this.glass,
    required this.text,
    required this.onPressed,
    required this.child,
    this.buttons,
    this.palette,
    this.padding,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: tokenButtonStyle(
        variant: variant,
        glass: glass,
        text: text,
        buttons: buttons,
        palette: palette,
        padding: padding,
        radius: radius,
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}

class TokenIconButton extends StatelessWidget {
  final TokenButtonVariant variant;
  final GlassTokens glass;
  final TextOnGlassTokens text;
  final ButtonTokens? buttons;
  final ButtonPalette? palette;
  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final EdgeInsets? padding;
  final double? radius;

  const TokenIconButton({
    super.key,
    required this.variant,
    required this.glass,
    required this.text,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.buttons,
    this.palette,
    this.padding,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: tokenButtonStyle(
        variant: variant,
        glass: glass,
        text: text,
        buttons: buttons,
        palette: palette,
        padding: padding,
        radius: radius,
      ),
      onPressed: onPressed,
      icon: icon,
      label: label,
    );
  }
}

class TokenTextButton extends StatelessWidget {
  final TokenButtonVariant variant;
  final GlassTokens glass;
  final TextOnGlassTokens text;
  final ButtonTokens? buttons;
  final ButtonPalette? palette;
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsets? padding;
  final double? radius;

  const TokenTextButton({
    super.key,
    this.variant = TokenButtonVariant.ghost,
    required this.glass,
    required this.text,
    required this.onPressed,
    required this.child,
    this.buttons,
    this.palette,
    this.padding,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: tokenButtonStyle(
        variant: variant,
        glass: glass,
        text: text,
        buttons: buttons,
        palette: palette,
        padding: padding,
        radius: radius,
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
