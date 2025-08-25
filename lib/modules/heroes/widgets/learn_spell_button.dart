import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

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
    if (mounted) setState(() => _isProcessing = true);

    widget.onLearnStart?.call();
    widget.onOptimisticLearn?.call();

    try {
      await FirebaseFunctions.instance.httpsCallable('learnSpell').call({
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
        setState(() => _isProcessing = false);
      }
      widget.onLearnComplete?.call();
      return;
    }

    if (mounted) setState(() => _isProcessing = false);
    widget.onLearnComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    // 🔁 Tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;

    final isButtonActive = widget.isEnabled && !_isProcessing;

    return TokenButton(
      variant: TokenButtonVariant.primary,
      glass: glass,
      text: text,
      buttons: buttons,
      onPressed: isButtonActive ? _handleLearn : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _isProcessing
            ? Row(
          key: const ValueKey('loading'),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                AlwaysStoppedAnimation<Color>(text.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Learning…',
              style: TextStyle(color: text.primary),
            ),
          ],
        )
            : Row(
          key: const ValueKey('idle'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school),
            const SizedBox(width: 8),
            Text(
              'Learn Spell',
              style: TextStyle(color: text.primary),
            ),
          ],
        ),
      ),
    );
  }
}
