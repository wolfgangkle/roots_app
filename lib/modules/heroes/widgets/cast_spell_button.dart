import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CastSpellButton extends StatefulWidget {
  final String spellId;
  final String heroId;
  final bool isEnabled;

  final VoidCallback? onCastStart;
  final VoidCallback? onCastComplete;
  final VoidCallback? onOptimisticCast;

  const CastSpellButton({
    super.key,
    required this.spellId,
    required this.heroId,
    this.isEnabled = true,
    this.onCastStart,
    this.onCastComplete,
    this.onOptimisticCast,
  });

  @override
  State<CastSpellButton> createState() => _CastSpellButtonState();
}

class _CastSpellButtonState extends State<CastSpellButton> {
  bool _isProcessing = false;

  Future<void> _handleCast() async {
    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    widget.onCastStart?.call();
    widget.onOptimisticCast?.call();

    try {
      await FirebaseFunctions.instance
          .httpsCallable('castSpell') // 🔮 Prepare backend for this later
          .call({
        'heroId': widget.heroId,
        'spellId': widget.spellId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🪄 Spell cast: ${widget.spellId}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error casting spell: $e')),
        );
        setState(() {
          _isProcessing = false;
        });
      }
      widget.onCastComplete?.call();
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }

    widget.onCastComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isButtonActive = widget.isEnabled && !_isProcessing;

    return ElevatedButton(
      onPressed: isButtonActive ? _handleCast : null,
      style: ElevatedButton.styleFrom(
        elevation: isButtonActive ? 3 : 0,
        backgroundColor:
        isButtonActive ? Colors.indigo.shade700 : Colors.grey.shade300,
        foregroundColor:
        isButtonActive ? Colors.white : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
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
          : const Text('Cast Spell'),
    );
  }
}
