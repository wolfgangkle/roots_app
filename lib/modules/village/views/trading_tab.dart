// Tokenized TradingTab (fixed variants + child last)
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

class TradingTab extends StatefulWidget {
  final String villageId;
  final int maxResourceTrade;
  final int maxGoldTrade;
  final int tradedResourceToday;
  final int tradedGoldToday;

  const TradingTab({
    super.key,
    required this.villageId,
    required this.maxResourceTrade,
    required this.maxGoldTrade,
    required this.tradedResourceToday,
    required this.tradedGoldToday,
  });

  @override
  State<TradingTab> createState() => _TradingTabState();
}

class _TradingTabState extends State<TradingTab> {
  String tradeDirection = 'resourceToGold';
  final Map<String, TextEditingController> _controllers = {
    'wood': TextEditingController(),
    'stone': TextEditingController(),
    'iron': TextEditingController(),
    'food': TextEditingController(),
  };

  final Map<String, String> emojis = {
    'wood': '🪵',
    'stone': '🪨',
    'iron': '⛓',
    'food': '🍗',
  };

  // Updated balanced exchange rates
  final Map<String, double> ratesResourceToGold = {
    'wood': 0.001,
    'stone': 0.001,
    'iron': 0.001,
    'food': 0.02,
  };

  final Map<String, double> ratesGoldToResource = {
    'wood': 1000,
    'stone': 1000,
    'iron': 1000,
    'food': 50,
  };

  bool _busy = false;

  void _fillMax(String key) {
    if (tradeDirection == 'resourceToGold') {
      _controllers[key]?.text =
          (widget.maxResourceTrade - widget.tradedResourceToday).toString();
    } else {
      _controllers[key]?.text =
          (widget.maxGoldTrade - widget.tradedGoldToday).toString();
    }
    setState(() {});
  }

  Future<void> _submitTrade(String resourceType) async {
    final amount = int.tryParse(_controllers[resourceType]?.text ?? '0') ?? 0;
    if (amount <= 0) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('executeTrade');
      await callable.call({
        'villageId': widget.villageId,
        'direction': tradeDirection,
        'resourceType': resourceType,
        'amount': amount,
      });

      messenger.showSnackBar(
        SnackBar(content: Text('✅ Traded $amount $resourceType')),
      );
      _controllers[resourceType]?.text = '';
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('❌ Trade failed: $e')),
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final GlassTokens glass = kStyle.glass;
    final TextOnGlassTokens text = kStyle.textOnGlass;
    final ButtonTokens buttons = kStyle.buttons;
    final EdgeInsets cardPad = kStyle.card.padding;

    final quota = tradeDirection == 'resourceToGold'
        ? '${widget.tradedResourceToday} / ${widget.maxResourceTrade} resources traded today'
        : '${widget.tradedGoldToday} / ${widget.maxGoldTrade} gold traded today';

    return ListView(
      padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, cardPad.bottom),
      children: [
        // 🏛️ Header + direction
        TokenPanel(
          glass: glass,
          text: text,
          padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🏛️ Trading Post",
                style: TextStyle(color: text.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text("Trade Direction:", style: TextStyle(color: text.secondary)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: tradeDirection,
                    dropdownColor: glass.baseColor.withValues(
                      alpha: glass.mode == SurfaceMode.solid ? 0.98 : 0.94,
                    ),
                    onChanged: (val) => setState(() => tradeDirection = val!),
                    items: const [
                      DropdownMenuItem(value: 'resourceToGold', child: Text('📦 → 🪙')),
                      DropdownMenuItem(value: 'goldToResource', child: Text('🪙 → 📦')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 📊 Rates
        TokenPanel(
          glass: glass,
          text: text,
          padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📊 Exchange Rates", style: TextStyle(color: text.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text("--- Gold for Resources ---", style: TextStyle(color: text.subtle, fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 2),
              ...ratesGoldToResource.entries.map((e) => _rateRow(
                "• 1 🪙 → ${e.value} ${emojis[e.key]} ${_capitalize(e.key)}",
                text,
              )),
              const SizedBox(height: 8),
              Text("--- Resources for Gold ---", style: TextStyle(color: text.subtle, fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 2),
              ...ratesResourceToGold.entries.map((e) => _rateRow(
                "• 1 ${emojis[e.key]} ${_capitalize(e.key)} → ${e.value} 🪙",
                text,
              )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 💱 Trade inputs
        TokenPanel(
          glass: glass,
          text: text,
          padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Enter amount for each resource to trade:", style: TextStyle(color: text.secondary)),
              const SizedBox(height: 8),
              ...emojis.keys.map((key) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _resourceRow(
                  context: context,
                  keyName: key,
                  emoji: emojis[key]!,
                  controller: _controllers[key]!,
                  busy: _busy,
                  onMax: () => _fillMax(key),
                  onTrade: () => _submitTrade(key),
                  glass: glass,
                  text: text,
                  buttons: buttons,
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 📈 Quota
        TokenPanel(
          glass: glass,
          text: text,
          padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, 12),
          child: Text("📈 $quota", style: TextStyle(color: text.subtle, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _rateRow(String line, TextOnGlassTokens text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(line, style: TextStyle(color: text.secondary)),
    );
  }

  Widget _resourceRow({
    required BuildContext context,
    required String keyName,
    required String emoji,
    required TextEditingController controller,
    required bool busy,
    required VoidCallback onMax,
    required VoidCallback onTrade,
    required GlassTokens glass,
    required TextOnGlassTokens text,
    required ButtonTokens buttons,
  }) {
    final inputFill = glass.baseColor.withValues(
      alpha: glass.mode == SurfaceMode.solid ? 0.10 : 0.08,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: text.subtle.withValues(alpha: 0.25),
        width: 1,
      ),
    );

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text('$emoji ${_capitalize(keyName)}', style: TextStyle(color: text.secondary)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: text.primary),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: inputFill,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(
                  color: text.secondary.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Max button → subdued
        TokenButton(
          variant: TokenButtonVariant.subdued,
          glass: glass,
          text: text,
          buttons: buttons,
          onPressed: busy ? null : onMax,
          child: const Text("Max"),
        ),
        const SizedBox(width: 8),
        // Trade button → primary
        TokenButton(
          variant: TokenButtonVariant.primary,
          glass: glass,
          text: text,
          buttons: buttons,
          onPressed: busy ? null : onTrade,
          child: const Text("Trade"),
        ),
      ],
    );
  }

  String _capitalize(String input) =>
      input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);
}
