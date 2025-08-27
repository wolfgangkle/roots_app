// lib/modules/heroes/widgets/level_up_points_chip.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ for context.watch

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';

/// A small, themed pill that shows unspent attribute points and (optionally)
/// a "pending level-up" hint. Tappable to jump/expand the allocation UI.
class LevelUpPointsChip extends StatelessWidget {
  final int unspentPoints;
  final bool pendingLevelUp;
  final bool isBusy;
  final VoidCallback? onTap;

  const LevelUpPointsChip({
    super.key,
    required this.unspentPoints,
    this.pendingLevelUp = false,
    this.isBusy = false,
    this.onTap,
  });

  bool get _isEnabled => !isBusy && unspentPoints > 0;

  @override
  Widget build(BuildContext context) {
    // Live-reactive tokens
    context.watch<StyleManager>(); // ✅
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    const double radius = 12.0; // ✅ no kStyle.card.radius in your tokens

    final baseBg = glass.baseColor.withValues(
      alpha: glass.mode == SurfaceMode.solid ? 0.16 : 0.12,
    );
    final hoverBg = glass.baseColor.withValues(
      alpha: glass.mode == SurfaceMode.solid ? 0.22 : 0.18,
    );
    final disabledBg = glass.baseColor.withValues(alpha: 0.08);

    final fgPrimary = _isEnabled ? text.primary : text.subtle;
    final fgSecondary = _isEnabled ? text.secondary : text.subtle;

    final borderColor = glass.showBorder
        ? (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity))
        : Colors.transparent;

    return Opacity(
      opacity: isBusy ? 0.8 : 1.0,
      child: _InkWellish(
        enabled: _isEnabled && onTap != null,
        baseColor: baseBg,
        hoverColor: hoverBg,
        disabledColor: disabledBg,
        borderColor: borderColor,
        radius: radius, // ✅
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pendingLevelUp ? Icons.bolt : Icons.upgrade,
                size: 16,
                color: fgPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Unspent: $unspentPoints',
                style: TextStyle(
                  color: fgPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (pendingLevelUp) ...[
                const SizedBox(width: 8),
                _Badge(
                  label: 'Acknowledge',
                  color: fgSecondary,
                  borderColor: borderColor,
                ),
              ],
              if (isBusy) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal, reusable badge used inside the chip.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final glass = kStyle.glass;
    final bg = glass.baseColor.withValues(
      alpha: glass.mode == SurfaceMode.solid ? 0.12 : 0.10,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: glass.showBorder ? 1 : 0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}

/// A tiny InkWell wrapper with custom glassy hover/press background.
class _InkWellish extends StatefulWidget {
  final bool enabled;
  final Color baseColor;
  final Color hoverColor;
  final Color disabledColor;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final Widget child;

  const _InkWellish({
    required this.enabled,
    required this.baseColor,
    required this.hoverColor,
    required this.disabledColor,
    required this.borderColor,
    required this.radius,
    required this.onTap,
    required this.child,
  });

  @override
  State<_InkWellish> createState() => _InkWellishState();
}

class _InkWellishState extends State<_InkWellish> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.enabled
        ? (_down ? widget.hoverColor : (_hover ? widget.hoverColor : widget.baseColor))
        : widget.disabledColor;

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _down = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: widget.borderColor,
              width: kStyle.glass.showBorder ? 1 : 0,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
