import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class UpgradeButton extends StatefulWidget {
  final String buildingType;
  final int currentLevel;
  final String villageId;
  final String? label;
  /// When true, this button (and others using the same global flag) are disabled.
  final bool isGloballyDisabled;
  /// Callback to notify the parent that an upgrade is starting.
  final VoidCallback? onGlobalUpgradeStart;
  /// Callback to notify the parent that the upgrade process has finished (success or failure).
  final VoidCallback? onUpgradeComplete;

  const UpgradeButton({
    Key? key,
    required this.buildingType,
    required this.currentLevel,
    required this.villageId,
    this.label,
    this.isGloballyDisabled = false,
    this.onGlobalUpgradeStart,
    this.onUpgradeComplete,
  }) : super(key: key);

  @override
  _UpgradeButtonState createState() => _UpgradeButtonState();
}

class _UpgradeButtonState extends State<UpgradeButton> {
  bool _isProcessing = false;

  Future<void> _handleUpgrade() async {
    // Immediately lock the local button.
    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }
    // Tell the parent to lock all upgrade buttons.
    widget.onGlobalUpgradeStart?.call();

    try {
      // First, update the village resources in the database.
      await FirebaseFunctions.instance
          .httpsCallable('updateVillageResources')
          .call({'villageId': widget.villageId});

      // Then, start the upgrade.
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
      // Clear global lock on error.
      widget.onUpgradeComplete?.call();
      return;
    }
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
    // When done (or in error), notify parent to clear the global lock.
    widget.onUpgradeComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Disable if this button is processing or if a global upgrade is active.
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
