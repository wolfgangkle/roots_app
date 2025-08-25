import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class UpgradeButton extends StatefulWidget {
  final String buildingType;
  final int currentLevel;
  final String villageId;
  final String? label;
  final bool isGloballyDisabled;
  final VoidCallback? onGlobalUpgradeStart;
  final VoidCallback? onUpgradeComplete;

  /// Optimistic UI hook
  final VoidCallback? onOptimisticUpgrade;

  const UpgradeButton({
    super.key,
    required this.buildingType,
    required this.currentLevel,
    required this.villageId,
    this.label,
    this.isGloballyDisabled = false,
    this.onGlobalUpgradeStart,
    this.onUpgradeComplete,
    this.onOptimisticUpgrade,
  });

  @override
  UpgradeButtonState createState() => UpgradeButtonState();
}

class UpgradeButtonState extends State<UpgradeButton> {
  bool _isProcessing = false;

  Future<void> _handleUpgrade() async {
    if (mounted) {
      setState(() => _isProcessing = true);
    }

    widget.onGlobalUpgradeStart?.call();
    widget.onOptimisticUpgrade?.call();

    // ✅ capture messenger before async gaps
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFunctions.instance
          .httpsCallable('updateVillageResources')
          .call({'villageId': widget.villageId});

      await FirebaseFunctions.instance
          .httpsCallable('startBuildingUpgrade')
          .call({
        'villageId': widget.villageId,
        'buildingType': widget.buildingType,
      });

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Upgrade started for ${widget.buildingType}')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isProcessing = false);
      }
      widget.onUpgradeComplete?.call();
      return;
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
    widget.onUpgradeComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Live tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;

    final bool disabled = _isProcessing || widget.isGloballyDisabled;

    return TokenButton(
      variant: TokenButtonVariant.primary,
      glass: glass,
      text: text,
      buttons: buttons,
      onPressed: disabled ? null : _handleUpgrade,
      child: _isProcessing
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          // Spinner inherits foreground; use token text to ensure contrast
          valueColor: AlwaysStoppedAnimation<Color>(text.primary),
        ),
      )
          : Text(widget.label ?? 'Upgrade'),
    );
  }
}
