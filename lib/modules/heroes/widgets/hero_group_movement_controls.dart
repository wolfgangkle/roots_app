import 'package:flutter/material.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:provider/provider.dart';

class HeroGroupMovementControls extends StatelessWidget {
  final VoidCallback onClear;
  final VoidCallback onSend;
  final VoidCallback? onCancelMovement;
  final bool isSending;
  final int waypointCount;

  const HeroGroupMovementControls({
    super.key,
    required this.onClear,
    required this.onSend,
    this.onCancelMovement,
    required this.isSending,
    required this.waypointCount,
  });

  @override
  Widget build(BuildContext context) {
    // live tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final pad = kStyle.card.padding;

    return TokenPanel(
      glass: glass,
      text: text,
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Queue summary
            Text(
              '📦 Current Queue: $waypointCount step(s)',
              style: TextStyle(color: text.secondary, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Cancel movement (danger) if available
            if (onCancelMovement != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TokenButton(
                  variant: TokenButtonVariant.danger,
                  glass: glass,
                  text: text,
                  buttons: buttons,
                  onPressed: isSending ? null : onCancelMovement,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.undo, size: 18),
                      const SizedBox(width: 8),
                      const Text('↩️ Cancel & Return'),
                    ],
                  ),
                ),
              ),

            if (onCancelMovement != null) const SizedBox(height: 8),

            // Primary actions
            Row(
              children: [
                // Clear (outline)
                TokenTextButton(
                  variant: TokenButtonVariant.outline,
                  glass: glass,
                  text: text,
                  buttons: buttons,
                  onPressed: isSending ? null : onClear,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.clear, size: 18),
                      SizedBox(width: 6),
                      Text('🗑️ Clear'),
                    ],
                  ),
                ),
                const Spacer(),
                // Send / Confirm (primary)
                TokenIconButton(
                  variant: TokenButtonVariant.primary,
                  glass: glass,
                  text: text,
                  buttons: buttons,
                  onPressed: isSending ? null : onSend,
                  icon: isSending
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.send),
                  label: Text(isSending ? 'Sending...' : '🚀 Confirm Movement'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
