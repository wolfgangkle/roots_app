import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class UpgradeButton extends StatefulWidget {
  final String buildingType;
  final int currentLevel;
  final String villageId;
  final String? label;
  final bool isGloballyDisabled;
  final VoidCallback? onGlobalUpgradeStart;
  final VoidCallback? onUpgradeComplete;

  /// 🔥 NEW: callback to perform optimistic UI update
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
      setState(() {
        _isProcessing = true;
      });
    }

    widget.onGlobalUpgradeStart?.call();
    widget.onOptimisticUpgrade?.call();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upgrade started for ${widget.buildingType}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isProcessing = false;
        });
      }

      widget.onUpgradeComplete?.call();
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }

    widget.onUpgradeComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _isProcessing || widget.isGloballyDisabled;
    return ElevatedButton(
      onPressed: disabled ? null : _handleUpgrade,
      style: ElevatedButton.styleFrom(
        elevation: disabled ? 0 : 2,
        backgroundColor: disabled ? Colors.grey.shade300 : Colors.blue,
        foregroundColor: disabled ? Colors.grey.shade600 : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      child: _isProcessing
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : Text(widget.label ?? 'Upgrade'),
    );
  }
}
