import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class LearnSpellButton extends StatefulWidget {
  final String spellId;
  final String heroId;
  final String userId;
  final bool isEnabled;

  final VoidCallback? onLearnStart;
  final VoidCallback? onLearnComplete;
  final VoidCallback? onOptimisticLearn;

  const LearnSpellButton({
    super.key,
    required this.spellId,
    required this.heroId,
    required this.userId,
    this.isEnabled = true,
    this.onLearnStart,
    this.onLearnComplete,
    this.onOptimisticLearn,
  });

  @override
  State<LearnSpellButton> createState() => _LearnSpellButtonState();
}

class _LearnSpellButtonState extends State<LearnSpellButton> {
  bool _isProcessing = false;

  Future<void> _handleLearn() async {
    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    widget.onLearnStart?.call();
    widget.onOptimisticLearn?.call();

    try {
      await FirebaseFunctions.instance
          .httpsCallable('learnSpell')
          .call({
        'heroId': widget.heroId,
        'spellId': widget.spellId,
        'userId': widget.userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🧠 Spell learned: ${widget.spellId}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error learning spell: $e')),
        );
        setState(() {
          _isProcessing = false;
        });
      }
      widget.onLearnComplete?.call();
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }

    widget.onLearnComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isButtonActive = widget.isEnabled && !_isProcessing;

    return ElevatedButton(
      onPressed: isButtonActive ? _handleLearn : null,
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
          : const Text('Learn Spell'),
    );
  }
}
