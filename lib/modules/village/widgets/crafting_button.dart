import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

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
      setState(() => _isProcessing = true);
    }

    widget.onCraftStart?.call();
    widget.onOptimisticCraft?.call();

    // ✅ capture messenger before async gaps
    final messenger = ScaffoldMessenger.of(context);

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
        messenger.showSnackBar(
          SnackBar(content: Text('🛠️ Crafting started: ${widget.itemId}')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Crafting error: $e')),
        );
        setState(() => _isProcessing = false);
      }
      widget.onCraftComplete?.call();
      return;
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }

    widget.onCraftComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Live tokens
    context.watch<StyleManager>();
    final GlassTokens glass = kStyle.glass;
    final TextOnGlassTokens text = kStyle.textOnGlass;
    final ButtonTokens buttons = kStyle.buttons;

    final bool disabled = _isProcessing || widget.isDisabled;

    return TokenButton(
      variant: TokenButtonVariant.danger, // crafting vibe
      glass: glass,
      text: text,
      buttons: buttons,
      onPressed: disabled ? null : _handleCraft,
      child: _isProcessing
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(text.primary),
        ),
      )
          : Text(widget.label ?? 'Craft'),
    );
  }
}
