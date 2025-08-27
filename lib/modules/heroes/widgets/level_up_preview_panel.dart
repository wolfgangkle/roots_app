// lib/modules/heroes/widgets/level_up_preview_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';

// Controller + types
import 'package:roots_app/modules/heroes/controllers/level_up_controller.dart';
import 'package:roots_app/modules/heroes/data/hero_stat_formulas.dart';

class LevelUpPreviewPanel extends StatelessWidget {
  final LevelUpController controller;

  const LevelUpPreviewPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Live-reactive tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final cardPad = kStyle.card.padding;

    final preview = controller.preview;
    final hasAlloc = controller.allocatedTotal > 0;
    final locked = controller.isSpendLocked;

    if (preview == null && !controller.pendingLevelUp) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TokenPanel(
        glass: glass,
        text: text,
        padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.trending_up, size: 18, color: text.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locked
                        ? 'Level Up — please acknowledge to allocate points'
                        : hasAlloc
                        ? _allocSummaryText(controller)
                        : (controller.pendingLevelUp ? 'Level Up available' : 'Preview'),
                    style: TextStyle(
                      color: text.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Actions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (controller.pendingLevelUp && !controller.acknowledgedLocally)
                      TokenIconButton(
                        buttons: buttons,
                        glass: glass,
                        text: text,
                        variant: TokenButtonVariant.primary,
                        onPressed: controller.isBusy ? null : controller.acknowledgeLevelUp,
                        icon: const Icon(Icons.bolt, size: 16),
                        label: const Text('Acknowledge'),
                      ),
                    if (hasAlloc)
                      TokenIconButton(
                        buttons: buttons,
                        glass: glass,
                        text: text,
                        variant: TokenButtonVariant.ghost,
                        onPressed: (controller.isBusy || locked) ? null : controller.reset,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset'),
                      ),
                    if (hasAlloc)
                      TokenIconButton(
                        buttons: buttons,
                        glass: glass,
                        text: text,
                        variant: TokenButtonVariant.primary,
                        onPressed: (controller.isBusy || locked) ? null : controller.confirmSpend,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Confirm'),
                      ),
                  ],
                ),
              ],
            ),

            if (controller.errorText != null) ...[
              const SizedBox(height: 10),
              _ErrorBanner(message: controller.errorText!),
            ],

            const SizedBox(height: 10),

            if (preview != null)
              _StatTable(
                before: preview.before,
                after: preview.after,
              ),
          ],
        ),
      ),
    );
  }

  String _allocSummaryText(LevelUpController c) {
    final parts = <String>[];
    void add(String k, String label) {
      final v = c.allocation[k] ?? 0;
      if (v > 0) parts.add('$label +$v');
    }

    add('strength', 'STR');
    add('dexterity', 'DEX');
    add('intelligence', 'INT');
    add('constitution', 'CON');

    final joined = parts.join(', ');
    return joined.isEmpty ? 'No changes' : 'Pending: $joined';
  }
}

// ---------------------------- Stat Table ----------------------------

class _StatTable extends StatelessWidget {
  final DerivedStatsPreview before;
  final DerivedStatsPreview after;

  const _StatTable({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    context.watch<StyleManager>();
    final text = kStyle.textOnGlass;

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.2),
        2: IntrinsicColumnWidth(),
        3: FlexColumnWidth(1.2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _rowHeader(text),
        _rowNum('Attack Min', before.attackMin, after.attackMin, text, decimals: 1),
        _rowNum('Attack Max', before.attackMax, after.attackMax, text, decimals: 1),
        _rowMs('Attack Speed', before.attackSpeedMs, after.attackSpeedMs, text),
        _rowNum('Attack Rating (AT)', before.attackRating, after.attackRating, text, decimals: 1),
        _rowNum('Defense (DEF)', before.defenseRating, after.defenseRating, text, decimals: 1),
        _rowNum('Regen / tick', before.regenPerTick, after.regenPerTick, text, decimals: 2),
        _rowNum('DPS (est.)', before.dps, after.dps, text, decimals: 2),
        _rowInt('HP Max', before.hpMax, after.hpMax, text),
        _rowInt('Mana Max', before.manaMax, after.manaMax, text),
        _rowInt('Carry Capacity', before.carryCapacity, after.carryCapacity, text),
        _rowNum('Base Move', before.baseMovementSpeed, after.baseMovementSpeed, text, decimals: 3),
        _rowNum('Adjusted Move', before.adjustedMovementSpeed, after.adjustedMovementSpeed, text, decimals: 3),
      ],
    );
  }

  TableRow _rowHeader(TextOnGlassTokens text) {
    return TableRow(
      children: [
        _cellText('Stat', text.secondary, bold: true),
        _cellText('Before', text.secondary),
        const SizedBox(height: 26),
        _cellText('After', text.secondary),
      ],
    );
  }

  TableRow _rowInt(String label, int beforeVal, int afterVal, TextOnGlassTokens text) {
    return _row(
      label,
      beforeVal.toString(),
      afterVal.toString(),
      _deltaBadge(afterVal - beforeVal, text),
      text,
    );
  }

  TableRow _rowNum(String label, double beforeVal, double afterVal, TextOnGlassTokens text, {int decimals = 1}) {
    String fmt(double v) => v.toStringAsFixed(decimals);
    return _row(
      label,
      fmt(beforeVal),
      fmt(afterVal),
      _deltaBadge(afterVal - beforeVal, text, decimals: decimals),
      text,
    );
  }

  TableRow _rowMs(String label, int beforeMs, int afterMs, TextOnGlassTokens text) {
    String fmt(int ms) {
      final sec = (ms / 1000).toStringAsFixed(2);
      return '$sec s';
    }

    // For time, a *decrease* is positive (faster).
    final deltaMs = afterMs - beforeMs;
    final deltaSec = deltaMs / 1000.0;
    final signAdjusted = -deltaSec; // invert so faster = green positive

    return _row(
      label,
      fmt(beforeMs),
      fmt(afterMs),
      _deltaBadge(signAdjusted, text, suffix: ' s'),
      text,
    );
  }

  TableRow _row(
      String label,
      String beforeStr,
      String afterStr,
      Widget delta,
      TextOnGlassTokens text,
      ) {
    return TableRow(
      children: [
        _cellText(label, text.secondary),
        _cellText(beforeStr, text.primary),
        Center(child: delta),
        _cellText(afterStr, text.primary, bold: true),
      ],
    );
  }

  Widget _cellText(String s, Color c, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        s,
        style: TextStyle(
          color: c,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _deltaBadge(num delta, TextOnGlassTokens text, {int decimals = 2, String suffix = ''}) {
    if (delta == 0) {
      return _Badge(
        label: '±0',
        color: text.subtle,
        variant: _BadgeVariant.neutral,
      );
    }
    final isPos = delta > 0;
    final sign = isPos ? '+' : '–';
    final value = delta.abs().toStringAsFixed(decimals);
    return _Badge(
      label: '$sign$value$suffix',
      color: isPos ? Colors.greenAccent : Colors.redAccent,
      variant: isPos ? _BadgeVariant.positive : _BadgeVariant.negative,
    );
  }
}

// ---------------------------- Error Banner ----------------------------

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    context.watch<StyleManager>();
    final text = kStyle.textOnGlass;
    final glass = kStyle.glass;

    final bg = glass.baseColor.withValues(
      alpha: glass.mode == SurfaceMode.solid ? 0.14 : 0.12,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: text.subtle.withValues(alpha: glass.strokeOpacity),
          width: glass.showBorder ? 1 : 0,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: text.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: text.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------- Badge ----------------------------

enum _BadgeVariant { neutral, positive, negative }

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final _BadgeVariant variant;

  const _Badge({
    required this.label,
    required this.color,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final t = kStyle.textOnGlass;

    final alpha = switch (variant) {
      _BadgeVariant.positive => 0.14,
      _BadgeVariant.negative => 0.14,
      _BadgeVariant.neutral => 0.10,
    };

    final bg = (variant == _BadgeVariant.neutral)
        ? glass.baseColor.withValues(alpha: glass.mode == SurfaceMode.solid ? 0.12 : 0.10)
        : color.withValues(alpha: alpha);

    final borderColor = glass.showBorder
        ? (glass.borderColor ?? t.subtle.withValues(alpha: glass.strokeOpacity))
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: glass.showBorder ? 1 : 0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: (variant == _BadgeVariant.neutral) ? t.secondary : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
    );
  }
}
