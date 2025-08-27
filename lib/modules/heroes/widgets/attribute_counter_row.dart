// lib/modules/heroes/widgets/attribute_counter_row.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

/// One attribute row with +/- controls and an optional tooltip.
/// Showcases the base value and a tiny delta badge if `allocatedDelta > 0`.
class AttributeCounterRow extends StatelessWidget {
  final String label;
  final int baseValue;
  final int allocatedDelta; // how many points currently pending for this attr
  final bool canIncrement;
  final bool canDecrement;
  final bool busy;
  final String? tooltip;

  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const AttributeCounterRow({
    super.key,
    required this.label,
    required this.baseValue,
    required this.allocatedDelta,
    required this.canIncrement,
    required this.canDecrement,
    this.busy = false,
    this.tooltip,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    // Live-reactive tokens
    context.watch<StyleManager>();
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;

    final labelStyle = TextStyle(color: text.secondary);
    final valueStyle = TextStyle(color: text.primary, fontWeight: FontWeight.w600);

    final valueWithDelta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(baseValue.toString(), style: valueStyle),
        if (allocatedDelta > 0) ...[
          const SizedBox(width: 6),
          _DeltaPill(text: '+$allocatedDelta'),
        ],
      ],
    );

    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: labelStyle),
        if (tooltip != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: tooltip!,
            child: Icon(Icons.info_outline, size: 14, color: text.subtle),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Label
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: labelWidget,
            ),
          ),

          // Value + Delta
          valueWithDelta,
          const SizedBox(width: 10),

          // Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Decrease $label',
                child: TokenIconButton(
                  buttons: buttons,
                  glass: kStyle.glass,
                  text: text,
                  variant: TokenButtonVariant.ghost,
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text(''), // required by your API
                  onPressed: (!busy && canDecrement) ? onDecrement : null,
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Increase $label',
                child: TokenIconButton(
                  buttons: buttons,
                  glass: kStyle.glass,
                  text: text,
                  variant: TokenButtonVariant.primary,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(''), // required by your API
                  onPressed: (!busy && canIncrement) ? onIncrement : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tiny rounded badge for the +N delta.
class _DeltaPill extends StatelessWidget {
  final String text;

  const _DeltaPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final glass = kStyle.glass;
    final t = kStyle.textOnGlass;

    final bg = glass.baseColor.withValues(
      alpha: glass.mode == SurfaceMode.solid ? 0.12 : 0.10,
    );

    final borderColor = glass.showBorder
        ? (glass.borderColor ?? t.subtle.withValues(alpha: glass.strokeOpacity))
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: glass.showBorder ? 1 : 0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: t.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}
