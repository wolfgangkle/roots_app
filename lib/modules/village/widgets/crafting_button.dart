import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

const Color kCraftingRed = Color(0xFF6B2C2C);

class CraftButton extends StatefulWidget {
  final String itemId;
  final String villageId;
  final int quantity;
  final String? label;
  final bool isDisabled;
  final VoidCallback? onCraftStart;
  final VoidCallback? onCraftComplete;
  final VoidCallback? onOptimisticCraft;

  const CraftButton({
    super.key,
    required this.itemId,
    required this.villageId,
    this.quantity = 1,
    this.label,
    this.isDisabled = false,
    this.onCraftStart,
    this.onCraftComplete,
    this.onOptimisticCraft,
  });

  @override
  State<CraftButton> createState() => _CraftButtonState();
}

class _CraftButtonState extends State<CraftButton> {
  bool _isProcessing = false;

  Future<void> _handleCraft() async {
    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    widget.onCraftStart?.call();
    widget.onOptimisticCraft?.call();

    try {
      await FirebaseFunctions.instance
          .httpsCallable('updateVillageResources')
          .call({'villageId': widget.villageId});

      await FirebaseFunctions.instance.httpsCallable('startCraftingJob').call({
        'villageId': widget.villageId,
        'itemId': widget.itemId,
        'quantity': widget.quantity,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🛠️ Crafting started: ${widget.itemId}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Crafting error: $e')),
        );
        setState(() {
          _isProcessing = false;
        });
      }
      widget.onCraftComplete?.call();
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }

    widget.onCraftComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _isProcessing || widget.isDisabled;

    return ElevatedButton(
      onPressed: disabled ? null : _handleCraft,
      style: ElevatedButton.styleFrom(
        elevation: disabled ? 0 : 3,
        backgroundColor: disabled ? Colors.grey.shade300 : kCraftingRed,
        foregroundColor: disabled ? Colors.grey.shade600 : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      child: _isProcessing
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Text(widget.label ?? 'Craft'),
    );
  }
}
