// Full reworked TradingTab with updated rates and clear separation
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
      _controllers[key]?.text = (widget.maxResourceTrade - widget.tradedResourceToday).toString();
    } else {
      _controllers[key]?.text = (widget.maxGoldTrade - widget.tradedGoldToday).toString();
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

      messenger.showSnackBar(SnackBar(content: Text('✅ Traded $amount $resourceType')));
      _controllers[resourceType]?.text = '';
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('❌ Trade failed: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quota = tradeDirection == 'resourceToGold'
        ? '${widget.tradedResourceToday} / ${widget.maxResourceTrade} resources traded today'
        : '${widget.tradedGoldToday} / ${widget.maxGoldTrade} gold traded today';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🏛️ Trading Post", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Row(
            children: [
              const Text("Trade Direction:"),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: tradeDirection,
                onChanged: (val) => setState(() => tradeDirection = val!),
                items: [
                  DropdownMenuItem(value: 'resourceToGold', child: Text('📦 → 🪙')),
                  DropdownMenuItem(value: 'goldToResource', child: Text('🪙 → 📦')),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text("📊 Exchange Rates:", style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("--- Gold for Resources ---", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ...ratesGoldToResource.entries.map((e) => Text(
            "• 1 🪙 → ${e.value} ${emojis[e.key]} ${_capitalize(e.key)}",
          )),
          const SizedBox(height: 8),
          const Text("--- Resources for Gold ---", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ...ratesResourceToGold.entries.map((e) => Text(
            "• 1 ${emojis[e.key]} ${_capitalize(e.key)} → ${e.value} 🪙",
          )),

          const SizedBox(height: 16),
          Text("Enter amount for each resource to trade:"),
          const SizedBox(height: 4),

          ...emojis.keys.map((key) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text('${emojis[key]} ${_capitalize(key)}')),
                Expanded(
                  child: TextField(
                    controller: _controllers[key],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _busy ? null : () => _fillMax(key),
                  child: const Text("Max"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _busy ? null : () => _submitTrade(key),
                  child: const Text("Trade"),
                ),
              ],
            ),
          )),

          const SizedBox(height: 16),
          Text("📈 $quota", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  String _capitalize(String input) => input[0].toUpperCase() + input.substring(1);
}
